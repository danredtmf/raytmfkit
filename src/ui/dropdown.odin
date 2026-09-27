package ui

import rl "deps:raylib"
import "raytmfkit:core"
import "raytmfkit:text"
import "raytmfkit:input"

Dropdown :: struct {
    items:          []cstring,   // указатели на строки; игра хранит у себя
    selected:       i32,
    focused:        bool,
    frozen:         bool,        // временно заблокирован (напр., другим dropdown)
    rect:           rl.Rectangle, // заполняется в draw
    item_height:    f32,
    widest_item_w:  f32,          // кэш ширины самого длинного
    recompute_width: bool,        // флаг «пересчитать»
}

update_dropdown :: proc(
    d: ^Dropdown,
    font: rl.Font,
    anchor: rl.Vector2,   // центр верхнего прямоугольника
) {
    size := core.get_scale(f32(font.baseSize))
    d.item_height = size + core.get_scale(10)

    // Кэш ширины по самой длинной строке (только если изменились items)
    if d.recompute_width || d.widest_item_w == 0 {
        w := f32(0)
        for it in d.items {
            m := text.measure_text(font, it, size)
            if m.x > w { w = m.x }
        }
        d.widest_item_w  = w
        d.recompute_width = false
    }

    rect_w := d.widest_item_w + size + core.get_scale(20)
    rect_h := size + core.get_scale(10)
    d.rect = rl.Rectangle{
        anchor.x - rect_w / 2,
        anchor.y - rect_h / 2,
        rect_w,
        rect_h,
    }

    if d.frozen { return }

    if input.is_mouse_pressed() {
        if input.hover_rect(d.rect) {
            // Клик по верхнему прямоугольнику — toggle
            d.focused = !d.focused
            return
        }

        if d.focused {
            // Клик по одному из пунктов
            for i in 0 ..< len(d.items) {
                item_r := dropdown_item_rect(d^, i)
                if input.hover_rect(item_r) {
                    d.selected = i32(i)
                    d.focused  = false
                    return
                }
            }
            // Клик вне — закрыть
            d.focused = false
        }
    }
}

draw_dropdown :: proc(d: Dropdown, font: rl.Font) {
    size := core.get_scale(f32(font.baseSize))
    margin := core.get_scale(10)

    // Верхний прямоугольник
    col_border := input.hover_rect(d.rect) ? rl.LIGHTGRAY : rl.GRAY
    rl.DrawRectangleRec(d.rect, rl.BLACK)
    rl.DrawRectangleLinesEx(d.rect, core.get_scale(2), col_border)

    // Текущий выбранный текст
    if d.selected >= 0 && d.selected < i32(len(d.items)) {
        txt_pos := rl.Vector2{
            d.rect.x + margin,
            d.rect.y + d.rect.height / 2 - size / 2,
        }
        text.draw_text_ex(font, d.items[d.selected], size, txt_pos, rl.WHITE)
    }

    // Треугольник справа
    tri_x := d.rect.x + d.rect.width - size / 2 - core.get_scale(8)
    tri_y := d.rect.y + d.rect.height / 2
    tri_s := size / 2
    if d.focused {
        rl.DrawTriangle(
            {tri_x, tri_y + tri_s / 2},
            {tri_x + tri_s, tri_y + tri_s / 2},
            {tri_x + tri_s / 2, tri_y - tri_s / 2},
            col_border,
        )
    } else {
        rl.DrawTriangle(
            {tri_x, tri_y - tri_s / 2},
            {tri_x + tri_s, tri_y - tri_s / 2},
            {tri_x + tri_s / 2, tri_y + tri_s / 2},
            col_border,
        )
    }

    // Список
    if d.focused {
        for i in 0 ..< len(d.items) {
            item_r := dropdown_item_rect(d, i)
            bg := input.hover_rect(item_r) ? rl.DARKGRAY : rl.GRAY
            rl.DrawRectangleRec(item_r, bg)
            rl.DrawRectangleLinesEx(item_r, 1, rl.LIGHTGRAY)

            txt_pos := rl.Vector2{
                item_r.x + margin,
                item_r.y + item_r.height / 2 - size / 2,
            }
            text.draw_text_ex(font, d.items[i], size, txt_pos, rl.WHITE)
        }
    }
}

@(private)
dropdown_item_rect :: proc(d: Dropdown, i: int) -> rl.Rectangle {
    return rl.Rectangle{
        d.rect.x,
        d.rect.y + d.rect.height * f32(i + 1),
        d.rect.width,
        d.rect.height,
    }
}
