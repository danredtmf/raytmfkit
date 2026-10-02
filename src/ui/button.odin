package ui

import rl "deps:raylib"
import "raytmfkit:core"
import "raytmfkit:text"
import "raytmfkit:input"

// Рисует кнопку. rect — out: заполняется реальным прямоугольником (по measure текста).
draw_button :: proc(
	font:        rl.Font,
    label:       cstring,
    size:        f32,
    anchor:      rl.Vector2,
    anchor_mode  := Anchor.CENTER,
    rect:        ^rl.Rectangle,
    bg           := rl.BLACK,
    fg           := rl.WHITE,
    pad          := rl.Vector2{10, 5},
    min_size     := rl.Vector2{0, 0},
) {
	m := text.measure_text(font, label, core.get_scale(size))

    w := m.x + core.get_scale(pad.x * 2)
    h := m.y + core.get_scale(pad.y * 2)
    if min_size.x > w { w = min_size.x }
    if min_size.y > h { h = min_size.y }

    // anchor_mode трактуется относительно rect размера {w, h}.
    pos := resolve_anchor(anchor, {w, h}, anchor_mode)

    rect^ = rl.Rectangle{pos.x, pos.y, w, h}

    // Текст центрируется внутри rect (при min_size = {0,0} совпадает
    // с прежним поведением: rect == m + 2pad, текст на pos + pad).
    text_pos := rl.Vector2{
        rect^.x + (rect^.width  - m.x) / 2,
        rect^.y + (rect^.height - m.y) / 2,
    }

    rl.DrawRectangleRec(rect^, bg)
    hovered := input.hover_rect(rect^)
    if hovered { core.want_cursor(.POINTING_HAND) }
    col := hovered ? rl.ColorAlpha(fg, 0.5) : fg
    text.draw_text_ex(font, label, core.get_scale(size), text_pos, col)
    rl.DrawRectangleLinesEx(rect^, 1, rl.DARKGRAY)
}

// Треугольная кнопка-стрелка.
draw_button_triangle :: proc(
    size_xy:       rl.Vector2,
    tri_size:      rl.Vector2,
    anchor:        rl.Vector2,
    anchor_mode   := Anchor.CENTER,
    rect:          ^rl.Rectangle,
    triangle_left: bool,
) {
    scaled := rl.Vector2{core.get_scale(size_xy.x), core.get_scale(size_xy.y)}
    pos    := resolve_anchor(anchor, scaled, anchor_mode)

    rect^ = rl.Rectangle{pos.x, pos.y, scaled.x, scaled.y}

    hovered := want_cursor_over(rect^, .POINTING_HAND)
    tri_col := hovered ? rl.DARKGRAY : rl.WHITE

    ts  := rl.Vector2{core.get_scale(tri_size.x), core.get_scale(tri_size.y)}
    mid := rl.Vector2{rect^.x + rect^.width / 2, rect^.y + rect^.height / 2}

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
