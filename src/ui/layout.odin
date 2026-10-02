package ui

import rl "deps:raylib"
import "raytmfkit:core"
import "raytmfkit:text"

// Layout-хелперы для статического размещения виджетов.
//
// Работают в screen-пикселях: на вход — размеры детей (screen px),
// на выход — позиции (screen px). Масштабирование делается один раз
// на границе (перед measure/gap), а не размазано по layout-логике.
//
// Типичный сценарий:
//
//     labels := []cstring{"New Game", "Continue", "Quit"}
//     sizes: [3]rl.Vector2
//     for l, i in labels {
//         sizes[i] = ui.button_size(font, l, 32)
//     }
//     total  := ui.measure_stack(sizes[:], core.get_scale(8), .VERTICAL)
//     origin := ui.resolve_anchor(core.ctx.screen_half, total, .CENTER)
//     lay    := ui.vbox(origin, gap = core.get_scale(8))
//
//     rects: [3]rl.Rectangle
//     for label, i in labels {
//         p := ui.layout_next(&lay, sizes[i])
//         ui.draw_button(font, label, 32, p, .TOP_LEFT, &rects[i])
//     }
//
// Stateless: Layout — просто курсор, ничего не аллоцирует, ничего не
// держит между кадрами. Создание и выброс на каждый кадр бесплатны.

Direction  :: enum { VERTICAL, HORIZONTAL }
CrossAlign :: enum { START, CENTER, END }

Layout :: struct {
    pos:         rl.Vector2,   // верхний-левый угол контейнера, screen px
    dir:         Direction,
    gap:         f32,          // screen px
    cross_align: CrossAlign,
    cross_size:  f32,          // screen px; нужен для CENTER/END (0 = START)

    // Приватное состояние курсора.
    _offset:    f32,           // screen px, позиция следующего ребёнка вдоль main
    _cross_max: f32,           // screen px, максимальный размер ребёнка по cross
    _count:     int,
}

// Вертикальный стек. Все позиции/размеры — screen px.
// gap масштабируйте через core.get_scale(...) самостоятельно.
vbox :: proc(pos: rl.Vector2, gap := f32(8)) -> Layout {
    return Layout{ pos = pos, dir = .VERTICAL, gap = gap, cross_align = .START }
}

// Горизонтальный стек.
hbox :: proc(pos: rl.Vector2, gap := f32(8)) -> Layout {
    return Layout{ pos = pos, dir = .HORIZONTAL, gap = gap, cross_align = .START }
}

// Возвращает верхний-левый угол следующего ребёнка и продвигает курсор.
// `size` — screen px.
layout_next :: proc(l: ^Layout, size: rl.Vector2) -> rl.Vector2 {
    p: rl.Vector2

    switch l.dir {
    case .VERTICAL:
        if l._count > 0 { l._offset += l.gap }
        p.y = l.pos.y + l._offset
        p.x = l.pos.x + cross_offset(l, size.x)
        l._offset += size.y
        if size.x > l._cross_max { l._cross_max = size.x }

    case .HORIZONTAL:
        if l._count > 0 { l._offset += l.gap }
        p.x = l.pos.x + l._offset
        p.y = l.pos.y + cross_offset(l, size.y)
        l._offset += size.x
        if size.y > l._cross_max { l._cross_max = size.y }
    }

    l._count += 1
    return p
}

// Итоговый размер контейнера после размещения всех детей.
// screen px. Если cross_align != .START и cross_size > 0 — cross-размер
// берётся из cross_size, иначе — максимальный cross-размер среди детей.
layout_size :: proc(l: Layout) -> rl.Vector2 {
    cross: f32
    if l.cross_align != .START && l.cross_size > 0 {
        cross = l.cross_size
    } else {
        cross = l._cross_max
    }
    switch l.dir {
    case .VERTICAL:   return { cross, l._offset }
    case .HORIZONTAL: return { l._offset, cross }
    }
    return {}
}

// Предварительное измерение стека без создания Layout.
// Удобно до resolve_anchor: сначала total, потом origin, потом vbox/hbox.
// Все размеры — screen px.
measure_stack :: proc(
    sizes: []rl.Vector2,
    gap:   f32,
    dir:   Direction,
) -> rl.Vector2 {
    if len(sizes) == 0 { return {} }

    total_main: f32
    max_cross:  f32

    for s, i in sizes {
        if i > 0 { total_main += gap }
        switch dir {
        case .VERTICAL:
            total_main += s.y
            if s.x > max_cross { max_cross = s.x }
        case .HORIZONTAL:
            total_main += s.x
            if s.y > max_cross { max_cross = s.y }
        }
    }

    switch dir {
    case .VERTICAL:   return { max_cross, total_main }
    case .HORIZONTAL: return { total_main, max_cross }
    }
    return {}
}

// Однострочный хелпер под самый частый случай: измерить стек, заанкорить
// и вернуть готовый Layout. Требует все размеры заранее — для динамического
// состава используйте measure_stack + resolve_anchor + vbox/hbox вручную.
anchored_stack :: proc(
    sizes:       []rl.Vector2,
    anchor:      rl.Vector2,
    anchor_mode: Anchor,
    gap:         f32,
    dir:         Direction,
) -> Layout {
    total  := measure_stack(sizes, gap, dir)
    origin := resolve_anchor(anchor, total, anchor_mode)
    switch dir {
    case .VERTICAL:   return vbox(origin, gap)
    case .HORIZONTAL: return hbox(origin, gap)
    }
    return {}
}

// Размер кнопки так, как её нарисует ui.draw_button с теми же
// font/size/pad. Возвращает screen px — готово к measure_stack / layout_next.
//
// Единственное место в layout.odin, которое делает get_scale: это граница
// между «неотмасштабированным миром виджетов» и «экранным миром layout».
button_size :: proc(
    font:  rl.Font,
    label: cstring,
    size:  f32,
    pad := rl.Vector2{10, 5},
) -> rl.Vector2 {
    m := text.measure_text(font, label, core.get_scale(size))
    return rl.Vector2{
        m.x + core.get_scale(pad.x * 2),
        m.y + core.get_scale(pad.y * 2),
    }
}

// Центр следующего слота. Для виджетов, которые принимают anchor как
// свой центр (например, draw_button с anchor_mode = .CENTER).
//
//     sz := ui.button_size(font, "OK", 32)
//     ui.draw_button(font, "OK", 32, ui.layout_next_center(&lay, sz), .CENTER, &rect)
layout_next_center :: proc(l: ^Layout, size: rl.Vector2) -> rl.Vector2 {
    p := layout_next(l, size)
    return p + size / 2
}

// Размеры кнопок с одинаковой шириной (по самой широкой).
// Удобно для меню и рядов кнопок — зазор между кнопками тогда
// симметричен относительно центра контейнера.
button_sizes_uniform :: proc(
    font:   rl.Font,
    labels: []cstring,
    size:   f32,
    pad    := rl.Vector2{10, 5},
    allocator := context.temp_allocator,
) -> []rl.Vector2 {
    out := make([]rl.Vector2, len(labels), allocator)
    max_w: f32
    for l, i in labels {
        out[i] = button_size(font, l, size, pad)
        if out[i].x > max_w { max_w = out[i].x }
    }
    for &s in out { s.x = max_w }
    return out
}

@(private)
cross_offset :: proc(l: ^Layout, child_cross: f32) -> f32 {
    if l.cross_align == .START || l.cross_size <= 0 { return 0 }
    switch l.cross_align {
    case .START:  return 0
    case .CENTER: return (l.cross_size - child_cross) / 2
    case .END:    return l.cross_size - child_cross
    }
    return 0
}
