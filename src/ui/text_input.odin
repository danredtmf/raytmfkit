package ui

import rl "deps:raylib"
import "core:unicode/utf8"
import "raytmfkit:core"
import "raytmfkit:input"
import "raytmfkit:text"
import "core:math"
import "core:unicode"

@(private)
CLICK_TIME :: f64(0.40)   // окно для double/triple click, сек
@(private)
CLICK_DIST :: f32(5)      // радиус «тот же spot», пиксели

// Однострочное поле ввода с выделением и clipboard.
//
// Ввод: rl.GetCharPressed — Unicode-корректно (в т.ч. кириллица).
// Клавиши: Left/Right/Home/End (+Shift — расширяют выделение),
//          Backspace/Delete (с repeat), Ctrl+A/C/X/V, Enter, Escape.
// Мышь: клик — переход курсора; drag — выделение; Shift+клик — расширение;
//       клик вне rect — снять фокус.
//
// Жизненный цикл:
//     ti: ui.TextInput
//     ui.init_text_input(&ti)
//     defer ui.deinit_text_input(&ti)
//     ...
//     ui.update_text_input(&ti, font, anchor, .CENTER, 400)
//     ...
//     ui.draw_text_input(ti, font)
TextInput :: struct {
    buf:         [dynamic]rune,
    cursor:      int,       // 0..len(buf)
    sel_anchor:  int,       // -1 = нет выделения; иначе — старт выделения
    focused:     bool,
    blink_t:     f32,
    dragging:    bool,

    rect:        rl.Rectangle,  // заполняется в update
    max_len:     int,           // 0 = без лимита, в рунах
    masked:      bool,
    mask_char:   rune,
    placeholder: cstring,

    on_changed:  proc(ti: ^TextInput),
    on_submit:   proc(ti: ^TextInput),

    // Стиль (неотмасштабированный — get_scale применяется внутри kit)
    font_size:   f32,
    pad:         rl.Vector2,
    blink_rate:  f32,   // полный период мигания, сек
    scroll_pad:  f32,   // запас справа при авто-скролле, неотмасшт.
    sel_bg:      rl.Color,
    show_reveal: bool, // показать кнопку-глаз справа
    show_clear:  bool,   // показать кнопку «×» (только при непустом buf активна)

    // Внутреннее
    _scratch:    [dynamic]u8,   // UTF-8 + '\0'
    _dirty:      bool,
    _scroll_x:   f32,
    _scratch_masked: bool,  // с каким masked собран _scratch
    _press_idx:      int,   // cursor на момент клика (anchor для drag-селекта)
    _drag_x:         f32,   // последняя мышиная X, которая двигала курсор
    _drag_y:         f32,

    // Click-counting для double/triple
    _last_click_time: f64,
    _last_click_x:    f32,
    _last_click_y:    f32,
    _click_count:     int,
}

TextInputLayout :: struct {
    inner:      rl.Rectangle,
    clear:      rl.Rectangle,
    reveal:     rl.Rectangle,
    has_clear:  bool,
    has_reveal: bool,
}

init_text_input :: proc(
    ti:        ^TextInput,
    initial:   string = "",
    allocator := context.allocator,
) {
    ti.buf         = make([dynamic]rune, 0, 32, allocator)
    ti._scratch    = make([dynamic]u8,   0, 64, allocator)
    ti.cursor      = 0
    ti.sel_anchor  = -1
    ti.blink_t     = 0
    ti.dragging    = false
    ti.masked      = false
    ti.mask_char   = '*'
    ti.max_len     = 0
    ti.font_size   = 24
    ti.pad         = {10, 6}
    ti.blink_rate  = 1.0
    ti.scroll_pad  = 4
    ti.sel_bg      = {60, 120, 220, 180}
    ti.show_reveal = false
    ti.show_clear  = false
    ti._dirty      = true
    ti._scroll_x   = 0
    ti._scratch_masked = false
    ti._press_idx  = -1
    ti._drag_x     = 0
    ti._drag_y     = 0
    ti._last_click_time = 0
    ti._last_click_x    = 0
    ti._last_click_y    = 0
    ti._click_count     = 0

    rebuild_scratch(ti)

    if len(initial) > 0 {
        text_input_set(ti, initial)
    }
}

deinit_text_input :: proc(ti: ^TextInput) {
    delete(ti.buf)
    delete(ti._scratch)
}

text_input_set :: proc(ti: ^TextInput, s: string) {
    resize(&ti.buf, 0)
    for r in s {
        if ti.max_len > 0 && len(ti.buf) >= ti.max_len { break }
        append(&ti.buf, r)
    }
    ti.cursor     = len(ti.buf)
    ti.sel_anchor = -1
    ti.blink_t    = 0
    rebuild_scratch(ti)
    if ti.on_changed != nil { ti.on_changed(ti) }
}

text_input_clear :: proc(ti: ^TextInput) {
    resize(&ti.buf, 0)
    ti.cursor     = 0
    ti.sel_anchor = -1
    ti.blink_t    = 0
    rebuild_scratch(ti)
    if ti.on_changed != nil { ti.on_changed(ti) }
}

// Текущее содержимое как UTF-8 string.
// Владелец результата — указанный allocator (по умолчанию temp_allocator).
text_input_value :: proc(
    ti:        TextInput,
    allocator := context.temp_allocator,
) -> string {
    if len(ti.buf) == 0 { return "" }

    bytes := make([dynamic]u8, 0, len(ti.buf) * 4, allocator)
    for r in ti.buf {
        arr, n := utf8.encode_rune(r)
        append(&bytes, ..arr[:n])
    }
    return string(bytes[:])
}

// true, если есть непустое выделение.
text_input_has_selection :: proc(ti: TextInput) -> bool {
    return ti.sel_anchor >= 0 && ti.sel_anchor != ti.cursor
}

@(private)
text_input_layout :: proc(ti: TextInput) -> TextInputLayout {
    out: TextInputLayout

    pad_x := core.get_scale(ti.pad.x)
    pad_y := core.get_scale(ti.pad.y)
    gap   := core.get_scale(4)

    out.inner = rl.Rectangle{
        ti.rect.x + pad_x,
        ti.rect.y + pad_y,
        ti.rect.width  - pad_x * 2,
        ti.rect.height - pad_y * 2,
    }
    if out.inner.width  < 0 { out.inner.width  = 0 }
    if out.inner.height < 0 { out.inner.height = 0 }
    if out.inner.height <= 0 { return out }

    w     := out.inner.height
    right := out.inner.x + out.inner.width

    if ti.show_reveal {
        right -= w
        out.reveal = {right, out.inner.y, w, w}
        right -= gap
        out.has_reveal = true
    }
    if ti.show_clear {
        right -= w
        out.clear = {right, out.inner.y, w, w}
        right -= gap
        out.has_clear = true
    }
    if out.has_reveal || out.has_clear {
        out.inner.width = right - out.inner.x
        if out.inner.width < 0 { out.inner.width = 0 }
    }
    return out
}

// Обновляет состояние и обрабатывает ввод. Звать в update-фазе.
update_text_input :: proc(
	ti:           ^TextInput,
    font:         rl.Font,
    anchor:       rl.Vector2,
    anchor_mode   := Anchor.CENTER,
    width         := f32(400),
) {
	size   := core.get_scale(ti.font_size)
    pad_y  := core.get_scale(ti.pad.y)
    line_h := text.measure_text(font, "Ag", size).y
    h      := line_h + pad_y * 2
    w      := core.get_scale(width)

    origin := resolve_anchor(anchor, {w, h}, anchor_mode)
    ti.rect = rl.Rectangle{origin.x, origin.y, w, h}

    lay := text_input_layout(ti^)

    // ---------- Мышь ----------
    if input.is_mouse_pressed() {
        if lay.has_reveal && input.hover_rect(lay.reveal) {
            ti.masked = !ti.masked
            ti._dirty = true
        } else if lay.has_clear && input.hover_rect(lay.clear) {
            if len(ti.buf) > 0 {
                text_input_clear(ti)
                ti.blink_t = 0
            }
        } else if input.hover_rect(ti.rect) {
            ti.focused = true
            ti.blink_t = 0
            // Click-counting. Сбрасывается при смене поля или паузе,
            // т.к. same_spot сравнивает абсолютные экранные координаты.
            now := core.ctx.time
            dt  := now - ti._last_click_time
            same_spot :=
            	math.abs(core.ctx.mouse.x - ti._last_click_x) < CLICK_DIST &&
                math.abs(core.ctx.mouse.y - ti._last_click_y) < CLICK_DIST
            if dt < CLICK_TIME && same_spot {
                ti._click_count += 1
            } else {
                ti._click_count = 1
            }
            ti._last_click_time = now
            ti._last_click_x    = core.ctx.mouse.x
            ti._last_click_y    = core.ctx.mouse.y

            idx := rune_from_x(
                font, ti^,
                core.ctx.mouse.x - (lay.inner.x - ti._scroll_x),
                size,
            )

            switch {
            case ti._click_count >= 3:
                // Тройной клик — выделить всё. Drag не включаем:
                // выделение уже максимальное, тянуть некуда.
                ti.sel_anchor = 0
                ti.cursor     = len(ti.buf)
                ti._press_idx = 0
                ti._drag_x    = core.ctx.mouse.x
                ti._drag_y    = core.ctx.mouse.y
                ti.dragging   = false
            case ti._click_count == 2:
                // Двойной клик — выделить слово под курсором.
                s, e := word_bounds(ti.buf[:], idx)
                ti.sel_anchor = s
                ti.cursor     = e
                ti._press_idx = s
            case:
                // Обычный клик: shift расширяет, без shift — сброс.
                if shift_down() && ti.sel_anchor < 0 {
                    ti.sel_anchor = ti.cursor
                } else if !shift_down() {
                    ti.sel_anchor = -1
                }
                ti.cursor     = idx
                ti._press_idx = idx
            }

            ti._drag_x  = core.ctx.mouse.x
            ti._drag_y  = core.ctx.mouse.y
            ti.dragging = true
        } else {
            ti.focused    = false
            ti.dragging   = false
            ti.sel_anchor = -1
        }
    }

    // Drag: обновляем cursor и стартуем выделение только когда мышь
    // реально сдвинулась. Иначе, если пользователь просто держит ЛКМ и
    // печатает, drag-блок каждый кадр обнулял бы cursor.
    if ti.dragging && input.is_mouse_down() {
        mx := core.ctx.mouse.x
        my := core.ctx.mouse.y
        if mx != ti._drag_x || my != ti._drag_y {
            ti._drag_x = mx
            ti._drag_y = my
            idx := rune_from_x(
                font, ti^,
                mx - (lay.inner.x - ti._scroll_x),
                size,
            )
            // Первый сдвиг — фиксируем anchor в исходной позиции клика.
            if ti.sel_anchor < 0 && idx != ti._press_idx {
                ti.sel_anchor = ti._press_idx
            }
            ti.cursor  = idx
            ti.blink_t = 0
        }
    }

    if input.is_mouse_released() { ti.dragging = false }

    // Курсор мыши. Порядок важен: кнопки перебивают IBEAM.
    if lay.has_reveal && input.hover_rect(lay.reveal) {
        core.want_cursor(.POINTING_HAND)
    } else if lay.has_clear && input.hover_rect(lay.clear) {
        core.want_cursor(.POINTING_HAND)
    } else if input.hover_rect(ti.rect) {
        core.want_cursor(.IBEAM)
    }

    // ---------- Клавиатура ----------
    if ti.focused && rl.IsKeyPressed(.ESCAPE) {
        ti.focused    = false
        ti.sel_anchor = -1
    }
    if ti.focused && (rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.KP_ENTER)) {
        if ti.on_submit != nil { ti.on_submit(ti) }
        ti.focused = false
    }

    if ti.focused {
        // --- Clipboard / Select All ---
        if ctrl_down() {
            if rl.IsKeyPressed(.A) {
                ti.sel_anchor = 0
                ti.cursor     = len(ti.buf)
                ti.blink_t    = 0
            }
            if rl.IsKeyPressed(.C) {
                if s, has := selection_to_string(ti^); has {
                    cs := core.cstring_temp(s)
                    if cs != nil { rl.SetClipboardText(cs) }
                }
            }
            if rl.IsKeyPressed(.X) {
                if s, has := selection_to_string(ti^); has {
                    cs := core.cstring_temp(s)
                    if cs != nil { rl.SetClipboardText(cs) }
                    delete_selection(ti)
                    ti.blink_t = 0
                }
            }
            if rl.IsKeyPressed(.V) {
                cs := rl.GetClipboardText()
                if cs != nil {
                    paste_string(ti, string(cs))
                    ti.blink_t = 0
                }
            }
        }

        // --- Backspace / Delete ---
        if rl.IsKeyPressed(.BACKSPACE) || rl.IsKeyPressedRepeat(.BACKSPACE) {
            if text_input_has_selection(ti^) {
                delete_selection(ti)
            } else if ti.cursor > 0 {
                buf_remove_at(&ti.buf, ti.cursor - 1)
                ti.cursor -= 1
            }
            ti.blink_t = 0
            ti._dirty  = true
        }
        if rl.IsKeyPressed(.DELETE) || rl.IsKeyPressedRepeat(.DELETE) {
            if text_input_has_selection(ti^) {
                delete_selection(ti)
            } else if ti.cursor < len(ti.buf) {
                buf_remove_at(&ti.buf, ti.cursor)
            }
            ti.blink_t = 0
            ti._dirty  = true
        }

        // --- Стрелки / Home / End ---
        shift := shift_down()

        if rl.IsKeyPressed(.LEFT) || rl.IsKeyPressedRepeat(.LEFT) {
            if text_input_has_selection(ti^) && !shift {
                s, _, _ := selection_range(ti^)
                ti.cursor     = s
                ti.sel_anchor = -1
            } else {
                if shift && ti.sel_anchor < 0 { ti.sel_anchor = ti.cursor }
                if ti.cursor > 0 { ti.cursor -= 1 }
            }
            ti.blink_t = 0
        }
        if rl.IsKeyPressed(.RIGHT) || rl.IsKeyPressedRepeat(.RIGHT) {
            if text_input_has_selection(ti^) && !shift {
                _, e, _ := selection_range(ti^)
                ti.cursor     = e
                ti.sel_anchor = -1
            } else {
                if shift && ti.sel_anchor < 0 { ti.sel_anchor = ti.cursor }
                if ti.cursor < len(ti.buf) { ti.cursor += 1 }
            }
            ti.blink_t = 0
        }
        if rl.IsKeyPressed(.HOME) {
            if shift && ti.sel_anchor < 0 { ti.sel_anchor = ti.cursor }
            ti.cursor  = 0
            ti.blink_t = 0
        }
        if rl.IsKeyPressed(.END) {
            if shift && ti.sel_anchor < 0 { ti.sel_anchor = ti.cursor }
            ti.cursor  = len(ti.buf)
            ti.blink_t = 0
        }

        // --- Ввод символов ---
        for {
            r := rl.GetCharPressed()
            if r == 0 { break }
            if r < 32 { continue } // \n, \t — игнорируем в однострочном поле
            if text_input_has_selection(ti^) { delete_selection(ti) }
            if ti.max_len > 0 && len(ti.buf) >= ti.max_len { break }
            buf_insert_at(&ti.buf, ti.cursor, r)
            ti.cursor += 1
            ti.blink_t = 0
            ti._dirty  = true
        }

        // --- Мигание ---
        ti.blink_t += core.ctx.delta
        if ti.blink_rate > 0 {
            for ti.blink_t >= ti.blink_rate { ti.blink_t -= ti.blink_rate }
        }
    }

    // Пересчёт горизонтального скролла под суженный inner
    recompute_scroll_x(ti, font, size, lay.inner.width)

    // Если кто-то поменял masked снаружи — пересобираем scratch.
    if ti._scratch_masked != ti.masked {
        ti._dirty = true
    }
    if ti._dirty {
        rebuild_scratch(ti)
        if ti.on_changed != nil { ti.on_changed(ti) }
    }
}

// Рисует поле. Звать в draw-фазе после update.
draw_text_input :: proc(ti: TextInput, font: rl.Font) {
    rl.DrawRectangleRec(ti.rect, rl.BLACK)
    border_col := ti.focused ? rl.LIGHTGRAY : rl.DARKGRAY
    rl.DrawRectangleLinesEx(ti.rect, 1, border_col)

    lay := text_input_layout(ti)
    if lay.inner.width <= 0 || lay.inner.height <= 0 { return }

    size := core.get_scale(ti.font_size)

    // --- Scissor по inner ---
    sc_x := i32(math.floor(lay.inner.x))
    sc_y := i32(math.floor(lay.inner.y))
    sc_w := i32(math.ceil(lay.inner.x + lay.inner.width))  - sc_x
    sc_h := i32(math.ceil(lay.inner.y + lay.inner.height)) - sc_y
    rl.BeginScissorMode(sc_x, sc_y, sc_w, sc_h)

    if s, e, has := selection_range(ti); has {
        x1 := lay.inner.x - ti._scroll_x + measure_upto_masked(font, ti, s, size)
        x2 := lay.inner.x - ti._scroll_x + measure_upto_masked(font, ti, e, size)
        if x2 > x1 {
            rl.DrawRectangleRec({x1, lay.inner.y, x2 - x1, lay.inner.height}, ti.sel_bg)
        }
    }

    cs := cstring(raw_data(ti._scratch))

    if len(ti.buf) > 0 {
        pos := rl.Vector2{lay.inner.x - ti._scroll_x, lay.inner.y}
        if text.current_is_sdf {
            text.draw_text_ex_sdf(font, cs, size, pos, rl.WHITE)
        } else {
            text.draw_text_ex(font, cs, size, pos, rl.WHITE)
        }
    }

    if len(ti.buf) == 0 && ti.placeholder != nil {
        pos := rl.Vector2{lay.inner.x, lay.inner.y}
        if text.current_is_sdf {
            text.draw_text_ex_sdf(font, ti.placeholder, size, pos, rl.DARKGRAY)
        } else {
            text.draw_text_ex(font, ti.placeholder, size, pos, rl.DARKGRAY)
        }
    }

    if ti.focused && !text_input_has_selection(ti) && cursor_visible(ti) {
        cursor_x := measure_upto_masked(font, ti, ti.cursor, size)
        cw := i32(max(1, core.get_scale(2)))
        rl.DrawRectangle(
            i32(lay.inner.x - ti._scroll_x + cursor_x),
            i32(lay.inner.y),
            cw,
            i32(lay.inner.height),
            rl.WHITE,
        )
    }

    rl.EndScissorMode()

    // --- Кнопки (вне scissor) ---
    if lay.has_clear {
        active  := len(ti.buf) > 0
        hovered := input.hover_rect(lay.clear)
        col     := rl.DARKGRAY
        if active { col = hovered ? rl.WHITE : rl.LIGHTGRAY }
        draw_clear_icon(lay.clear, col)
    }
    if lay.has_reveal {
        hovered  := input.hover_rect(lay.reveal)
        icon_col := hovered ? rl.WHITE : rl.LIGHTGRAY
        draw_reveal_icon(lay.reveal, ti.masked, icon_col)
    }
}

// ---------- internal ----------

@(private)
shift_down :: proc() -> bool {
    return rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT)
}

@(private)
ctrl_down :: proc() -> bool {
    return rl.IsKeyDown(.LEFT_CONTROL) || rl.IsKeyDown(.RIGHT_CONTROL)
}

// Возвращает [start, end) и флаг наличия выделения.
@(private)
selection_range :: proc(ti: TextInput) -> (start, end: int, has: bool) {
    if ti.sel_anchor < 0 || ti.sel_anchor == ti.cursor {
        return 0, 0, false
    }
    if ti.sel_anchor < ti.cursor {
        return ti.sel_anchor, ti.cursor, true
    }
    return ti.cursor, ti.sel_anchor, true
}

@(private)
selection_to_string :: proc(ti: TextInput) -> (string, bool) {
    s, e, has := selection_range(ti)
    if !has { return "", false }

    bytes := make([dynamic]u8, 0, (e - s) * 4, context.temp_allocator)
    for i in s ..< e {
        arr, n := utf8.encode_rune(ti.buf[i])
        append(&bytes, ..arr[:n])
    }
    return string(bytes[:]), true
}

@(private)
delete_selection :: proc(ti: ^TextInput) {
    s, e, has := selection_range(ti^)
    if !has { return }

    n     := len(ti.buf)
    count := e - s

    for i := s; i + count < n; i += 1 {
        ti.buf[i] = ti.buf[i + count]
    }
    resize(&ti.buf, n - count)

    ti.cursor     = s
    ti.sel_anchor = -1
    ti._dirty     = true
}

@(private)
paste_string :: proc(ti: ^TextInput, s: string) {
    if text_input_has_selection(ti^) { delete_selection(ti) }

    for r in s {
        if r < 32 { continue } // однострочное поле
        if ti.max_len > 0 && len(ti.buf) >= ti.max_len { break }
        buf_insert_at(&ti.buf, ti.cursor, r)
        ti.cursor += 1
    }
    ti._dirty = true
}

RuneClass :: enum { Word, Space, Punct }

@(private)
rune_class :: proc(r: rune) -> RuneClass {
    if unicode.is_space(r) { return .Space }
    if unicode.is_letter(r) || unicode.is_digit(r) || r == '_' { return .Word }
    return .Punct
}

// Возвращает [start, end) run'а того же класса, что и символ под курсором.
//
// Эвристика: если idx попадает в пробел, но слева — буква (типичный случай
// "hello| world"), выделяем слово слева. Если idx == len(buf) — смотрим
// на последний символ. Если поле пустое — вернём (0, 0).
//
// Классы считаются по Unicode: is_letter покрывает кириллицу, is_digit —
// арабские цифры и т.д. Рунный run ПОДРЯД одного класса — и есть «слово»
// (буквы+цифры+_), «пробельный run» или «run пунктуации».
@(private)
word_bounds :: proc(buf: []rune, idx: int) -> (start, end: int) {
    n := len(buf)
    if n == 0 { return 0, 0 }

    i := idx
    if i < 0 { i = 0 }
    if i > n { i = n }

    cls: RuneClass
    probe: int

    if i < n {
        cls   = rune_class(buf[i])
        probe = i
        if cls == .Space && i > 0 {
            left := rune_class(buf[i - 1])
            if left == .Word {
                cls   = .Word
                probe = i - 1
            }
        }
    } else {
        probe = n - 1
        cls   = rune_class(buf[probe])
    }

    s := probe
    for s > 0 && rune_class(buf[s - 1]) == cls { s -= 1 }
    e := probe + 1
    for e < n && rune_class(buf[e]) == cls { e += 1 }
    return s, e
}

// Пиксель X (относительно начала текста) → индекс руны.
// Возвращает 0..len(buf).
@(private)
rune_from_x :: proc(font: rl.Font, ti: TextInput, x_rel: f32, size: f32) -> int {
    n := len(ti.buf)
    if n == 0 { return 0 }
    if x_rel <= 0 { return 0 }

    acc := f32(0)
    for i in 0 ..< n {
        r   := ti.masked ? ti.mask_char : ti.buf[i]
        adv := rune_advance(font, r, size)

        if x_rel < acc + adv * 0.5 { return i }
        if x_rel < acc + adv { return i + 1 }
        acc += adv + 1 // spacing_h = 1
    }
    return n
}

@(private)
recompute_scroll_x :: proc(ti: ^TextInput, font: rl.Font, size: f32, inner_w: f32) {
    cursor_x   := measure_upto_masked(font, ti^, ti.cursor,   size)
    total_x    := measure_upto_masked(font, ti^, len(ti.buf), size)
    scroll_pad := core.get_scale(ti.scroll_pad)

    // Запас scroll_pad справа, чтобы каретка в конце текста не упиралась
    // точно в границу inner — её там срежет scissor.
    max_scroll := total_x + scroll_pad - inner_w
    if max_scroll < 0 { max_scroll = 0 }

    sx := ti._scroll_x

    if cursor_x - sx > inner_w - scroll_pad {
        sx = cursor_x - inner_w + scroll_pad
    }
    if cursor_x - sx < scroll_pad {
        sx = cursor_x - scroll_pad
    }

    if sx < 0          { sx = 0 }
    if sx > max_scroll { sx = max_scroll }
    ti._scroll_x = sx
}

@(private)
rebuild_scratch :: proc(ti: ^TextInput) {
    resize(&ti._scratch, 0)
    for r in ti.buf {
        rr := ti.masked ? ti.mask_char : r
        arr, n := utf8.encode_rune(rr)
        append(&ti._scratch, ..arr[:n])
    }
    append(&ti._scratch, u8(0))
    ti._dirty          = false
    ti._scratch_masked = ti.masked   // ← новое
}

@(private)
buf_remove_at :: proc(buf: ^[dynamic]rune, i: int) {
    n := len(buf)
    if i < 0 || i >= n { return }
    for j := i; j < n - 1; j += 1 {
        buf[j] = buf[j + 1]
    }
    pop(buf)
}

@(private)
buf_insert_at :: proc(buf: ^[dynamic]rune, idx: int, r: rune) {
    i := idx
    if i < 0 { i = 0 }
    if i > len(buf) { i = len(buf) }

    append(buf, 0)
    n := len(buf)
    for j := n - 1; j > i; j -= 1 {
        buf[j] = buf[j - 1]
    }
    buf[i] = r
}

@(private)
rune_advance :: proc(font: rl.Font, r: rune, size: f32) -> f32 {
    if r == '\n' || r == 0 { return 0 }
    scale := size / f32(font.baseSize)
    idx := rl.GetGlyphIndex(font, r)
    if font.glyphs[idx].advanceX == 0 {
        return f32(font.recs[idx].width) * scale
    }
    return f32(font.glyphs[idx].advanceX) * scale
}

@(private)
measure_upto_masked :: proc(
    font: rl.Font,
    ti:   TextInput,
    upto: int,
    size: f32,
) -> f32 {
    n := min(upto, len(ti.buf))
    if n == 0 { return 0 }
    w := f32(0)
    for i in 0 ..< n {
        r := ti.masked ? ti.mask_char : ti.buf[i]
        w += rune_advance(font, r, size)
        if i < n - 1 { w += 1 }
    }
    return w
}

@(private)
cursor_visible :: proc(ti: TextInput) -> bool {
    if ti.blink_rate <= 0 { return true }
    return ti.blink_t < ti.blink_rate * 0.5
}

// Рисует иконку глаза. masked = true → перечёркнутый (текст скрыт),
// masked = false → открытый (текст виден).
@(private)
draw_reveal_icon :: proc(r: rl.Rectangle, masked: bool, col: rl.Color) {
    cx := r.x + r.width  / 2
    cy := r.y + r.height / 2
    rx := r.width  * 0.32
    ry := r.height * 0.20
    t  := max(1, r.width * 0.06)

    rl.DrawEllipseLines(i32(cx), i32(cy), rx, ry, col)

    if masked {
        // Перечёркнутый глаз
        rl.DrawLineEx(
            {cx - rx, cy + ry * 1.6},
            {cx + rx, cy - ry * 1.6},
            t, col,
        )
    } else {
        // Зрачок
        rl.DrawCircle(i32(cx), i32(cy), ry * 0.65, col)
    }
}

@(private)
draw_clear_icon :: proc(r: rl.Rectangle, col: rl.Color) {
    inset := r.width * 0.30
    t     := max(1, r.width * 0.08)
    x1 := r.x + inset
    y1 := r.y + inset
    x2 := r.x + r.width  - inset
    y2 := r.y + r.height - inset
    rl.DrawLineEx({x1, y1}, {x2, y2}, t, col)
    rl.DrawLineEx({x2, y1}, {x1, y2}, t, col)
}
