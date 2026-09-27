package ui

import rl "deps:raylib"
import "raytmfkit:core"
import "raytmfkit:text"
import "raytmfkit:input"

// Рисует кнопку. rect — out: заполняется реальным прямоугольником (по measure текста).
draw_button :: proc(
    font:      rl.Font,
    label:     cstring,
    center:    rl.Vector2,
    rect:      ^rl.Rectangle,
    bg   := rl.BLACK,
    fg   := rl.WHITE,
    pad  := rl.Vector2{10, 5},   // в виртуальных пикселях
) {
    size := core.get_scale(f32(font.baseSize))
    m    := text.measure_text(font, label, size)

    pos := rl.Vector2{ center.x - m.x / 2, center.y - m.y / 2 }

    rect^ = rl.Rectangle{
        pos.x - core.get_scale(pad.x),
        pos.y - core.get_scale(pad.y),
        m.x   + core.get_scale(pad.x * 2),
        m.y   + core.get_scale(pad.y * 2),
    }

    rl.DrawRectangleRec(rect^, bg)
    col := input.hover_rect(rect^) ? rl.ColorAlpha(fg, 0.5) : fg
    text.draw_text_ex(font, label, size, pos, col)
    rl.DrawRectangleLinesEx(rect^, 1, rl.DARKGRAY)
}

// Layout-вариант: центрирует по X, ставит по Y от низа с множителем.
draw_button_layout :: proc(
    font:         rl.Font,
    label:        cstring,
    anchor:       rl.Vector2,     // обычно {screen_half.x, screen_vec2.y}
    rect:         ^rl.Rectangle,
    y_multiplier: f32,
    bg := rl.BLACK,
    fg := rl.WHITE,
) {
    size := core.get_scale(f32(font.baseSize))
    m    := text.measure_text(font, label, size)

    pos := rl.Vector2{
        anchor.x - m.x / 2,
        anchor.y - size * y_multiplier,
    }

    rect^ = rl.Rectangle{
        pos.x - core.get_scale(10),
        pos.y - core.get_scale(5),
        m.x   + core.get_scale(20),
        m.y   - core.get_scale(8),
    }

    rl.DrawRectangleRec(rect^, bg)
    col := input.hover_rect(rect^) ? rl.ColorAlpha(fg, 0.5) : fg
    text.draw_text_ex(font, label, size, pos, col)
    rl.DrawRectangleLinesEx(rect^, 1, rl.DARKGRAY)
}

// Треугольная кнопка-стрелка.
draw_button_triangle :: proc(
    size_xy:       rl.Vector2,
    tri_size:      rl.Vector2,
    center:        rl.Vector2,
    rect:          ^rl.Rectangle,
    triangle_left: bool,
) {
    scaled := rl.Vector2{ core.get_scale(size_xy.x), core.get_scale(size_xy.y) }
    rect^ = rl.Rectangle{
        center.x - scaled.x / 2,
        center.y - scaled.y / 2,
        scaled.x, scaled.y,
    }

    hovered := input.hover_rect(rect^)
    tri_col := hovered ? rl.DARKGRAY : rl.WHITE

    ts := rl.Vector2{ core.get_scale(tri_size.x), core.get_scale(tri_size.y) }
    mid := rl.Vector2{ rect^.x + rect^.width / 2, rect^.y + rect^.height / 2 }

    a, b, c: rl.Vector2
    if triangle_left {
        a = mid + {-ts.x, 0}
        b = mid + { ts.x,  ts.y}
        c = mid + { ts.x, -ts.y}
    } else {
        a = mid + { ts.x, 0}
        b = mid + {-ts.x, -ts.y}
        c = mid + {-ts.x,  ts.y}
    }

    rl.DrawRectangleRec(rect^, rl.BLACK)
    rl.DrawTriangle(a, b, c, tri_col)
    rl.DrawRectangleLinesEx(rect^, 1, rl.DARKGRAY)
}
