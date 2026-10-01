package ui

import rl "deps:raylib"
import "raytmfkit:core"
import "raytmfkit:input"
import "raytmfkit:text"

MenuItem :: struct {
    label:   cstring,
    enabled: bool,
    user:    rawptr,
}

MenuStyle :: struct {
    font_size:       f32,
    pad:             rl.Vector2,
    spacing:         f32,
    border_width:    f32,

    bg:              rl.Color,
    bg_selected:     rl.Color,
    fg:              rl.Color,
    fg_selected:     rl.Color,
    fg_disabled:     rl.Color,
    border:          rl.Color,
    border_selected: rl.Color,
}

default_menu_style :: proc() -> MenuStyle {
    return MenuStyle{
        font_size       = 32,
        pad             = {24, 10},
        spacing         = 6,
        border_width    = 1,
        bg              = rl.BLACK,
        bg_selected     = rl.DARKGRAY,
        fg              = rl.WHITE,
        fg_selected     = rl.WHITE,
        fg_disabled     = rl.GRAY,
        border          = rl.DARKGRAY,
        border_selected = rl.LIGHTGRAY,
    }
}

Menu :: struct {
    items:      []MenuItem,
    selected:   i32,
    wrap:       bool,
    style:      MenuStyle,

    rects:      [dynamic]rl.Rectangle,
    text_sizes: [dynamic]rl.Vector2,
    total_rect: rl.Rectangle,
    laid_out:   bool,
}

menu_init :: proc(m: ^Menu, items: []MenuItem, allocator := context.allocator) {
    m.items    = items
    m.style    = default_menu_style()
    m.wrap     = true
    m.selected = -1
    m.laid_out = false

    for i in 0 ..< len(items) {
        if items[i].enabled {
            m.selected = i32(i)
            break
        }
    }

    n := len(items)
    m.rects      = make([dynamic]rl.Rectangle, n, n, allocator)
    m.text_sizes = make([dynamic]rl.Vector2,   n, n, allocator)
}

menu_deinit :: proc(m: ^Menu) {
    delete(m.rects)
    delete(m.text_sizes)
}

menu_layout :: proc(
    m:           ^Menu,
    font:        rl.Font,
    anchor:      rl.Vector2,
    anchor_mode  := Anchor.CENTER,
) {
    n := len(m.items)
    if n == 0 {
        m.total_rect = {}
        m.laid_out   = false
        return
    }

    if len(m.rects) != n {
        resize(&m.rects, n)
        resize(&m.text_sizes, n)
    }

    size    := core.get_scale(m.style.font_size)
    pad_x   := core.get_scale(m.style.pad.x)
    pad_y   := core.get_scale(m.style.pad.y)
    spacing := core.get_scale(m.style.spacing)

    max_w := f32(0)
    max_h := f32(0)
    for i in 0 ..< n {
        sz := text.measure_text(font, m.items[i].label, size)
        m.text_sizes[i] = sz
        if sz.x > max_w { max_w = sz.x }
        if sz.y > max_h { max_h = sz.y }
    }

    item_w := max_w + pad_x * 2
    item_h := max_h + pad_y * 2

    total_w := item_w
    total_h := item_h * f32(n) + spacing * f32(n - 1)

    origin := resolve_anchor(anchor, {total_w, total_h}, anchor_mode)
    m.total_rect = rl.Rectangle{origin.x, origin.y, total_w, total_h}

    y := origin.y
    for i in 0 ..< n {
        m.rects[i] = rl.Rectangle{origin.x, y, total_w, item_h}
        y += item_h + spacing
    }

    m.laid_out = true
}

menu_update :: proc(
    m:           ^Menu,
    font:        rl.Font,
    anchor:      rl.Vector2,
    anchor_mode  := Anchor.CENTER,
) -> int {
    menu_layout(m, font, anchor, anchor_mode)
    if len(m.items) == 0 { return -1 }

    activated := -1

    for i in 0 ..< len(m.items) {
        if input.hover_rect(m.rects[i]) && m.items[i].enabled {
            m.selected = i32(i)
            break
        }
    }

    if input.is_mouse_pressed() {
        for i in 0 ..< len(m.items) {
            if input.hover_rect(m.rects[i]) {
                if m.items[i].enabled {
                    m.selected = i32(i)
                    activated = i
                }
                break
            }
        }
    }

    dir := i32(0)
    if rl.IsKeyPressed(.UP)   || gamepad_pressed(.LEFT_FACE_UP)   { dir -= 1 }
    if rl.IsKeyPressed(.DOWN) || gamepad_pressed(.LEFT_FACE_DOWN) { dir += 1 }
    if dir != 0 { menu_move_selection(m, dir) }

    activate_key := rl.IsKeyPressed(.ENTER) ||
                    rl.IsKeyPressed(.KP_ENTER) ||
                    rl.IsKeyPressed(.SPACE)
    if activate_key || gamepad_pressed(.RIGHT_FACE_DOWN) {
        if m.selected >= 0 && m.selected < i32(len(m.items)) {
            if m.items[m.selected].enabled {
                activated = int(m.selected)
            }
        }
    }

    return activated
}

menu_draw :: proc(m: Menu, font: rl.Font) {
    if !m.laid_out || len(m.items) == 0 { return }

    bw := core.get_scale(m.style.border_width)
    if bw < 1 { bw = 1 }

    size := core.get_scale(m.style.font_size)

    for i in 0 ..< len(m.items) {
        r   := m.rects[i]
        it  := m.items[i]
        sel := i32(i) == m.selected

        bg := m.style.bg
        if sel && it.enabled { bg = m.style.bg_selected }
        rl.DrawRectangleRec(r, bg)

        border := m.style.border
        if sel && it.enabled { border = m.style.border_selected }
        rl.DrawRectangleLinesEx(r, bw, border)

        col := m.style.fg
        if !it.enabled {
            col = m.style.fg_disabled
        } else if sel {
            col = m.style.fg_selected
        }

        ts := m.text_sizes[i]
        tx := r.x + (r.width  - ts.x) / 2
        ty := r.y + (r.height - ts.y) / 2
        text.draw_text_ex(font, it.label, size, {tx, ty}, col)
    }
}

@(private)
gamepad_pressed :: proc(b: rl.GamepadButton) -> bool {
    if !rl.IsGamepadAvailable(0) { return false }
    return rl.IsGamepadButtonPressed(0, b)
}

@(private)
menu_move_selection :: proc(m: ^Menu, dir: i32) {
    n := i32(len(m.items))
    if n == 0 { return }

    start: i32
    if m.selected < 0 || m.selected >= n {
        start = dir > 0 ? -1 : n
    } else {
        start = m.selected
    }

    idx := start
    for _ in 0 ..< n {
        idx += dir
        if idx < 0 {
            if m.wrap { idx = n - 1 } else { return }
        } else if idx >= n {
            if m.wrap { idx = 0 } else { return }
        }
        if m.items[idx].enabled {
            m.selected = idx
            return
        }
    }
}
