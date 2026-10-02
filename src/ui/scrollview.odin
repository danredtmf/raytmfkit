package ui

import rl "deps:raylib"
import "raytmfkit:core"
import "raytmfkit:input"

ScrollView :: struct {
    scroll:      f32,   // текущий offset в пикселях
    content_h:   f32,   // полная высота контента
    view_rect:   rl.Rectangle,
    speed:       f32,   // множитель колеса
    dragging:    bool,
    drag_offset: f32,
    bar_width:   f32,   // по умолчанию 12
}

// Обновляет scroll (колесо + drag thumb).
update_scrollview :: proc(sv: ^ScrollView) {
    max_scroll := max(0, sv.content_h - sv.view_rect.height)

    // Колесо — только если курсор внутри view_rect
    if input.hover_rect(sv.view_rect) {
        sv.scroll -= input.wheel() * sv.speed
    }
    sv.scroll = clamp(sv.scroll, 0, max_scroll)

    if sv.content_h <= sv.view_rect.height { return }  // скроллбар не нужен

    bar_w   := core.get_scale(sv.bar_width)
    track_r := rl.Rectangle{
        sv.view_rect.x + sv.view_rect.width - bar_w,
        sv.view_rect.y,
        bar_w,
        sv.view_rect.height,
    }

    visible_ratio := sv.view_rect.height / sv.content_h
    thumb_h := sv.view_rect.height * visible_ratio
    thumb_y := track_r.y +
        (sv.scroll / max_scroll) * (sv.view_rect.height - thumb_h)
    thumb_r := rl.Rectangle{track_r.x, thumb_y, bar_w, thumb_h}

    // Drag
    if input.pressed_on_rect(thumb_r) {
        sv.dragging    = true
        sv.drag_offset = core.ctx.mouse.y - thumb_r.y
    }
    if input.is_mouse_released() { sv.dragging = false }

    if sv.dragging {
        new_y := clamp(
            core.ctx.mouse.y - sv.drag_offset,
            track_r.y,
            track_r.y + track_r.height - thumb_h,
        )
        sv.scroll = ((new_y - track_r.y) / (track_r.height - thumb_h)) * max_scroll
    }
}

// Рисует скроллбар поверх view_rect. Контент рисуется вызывающим кодом внутри scissor.
draw_scrollview_bar :: proc(sv: ScrollView) {
    if sv.content_h <= sv.view_rect.height { return }

    max_scroll := sv.content_h - sv.view_rect.height
    bar_w   := core.get_scale(sv.bar_width)
    track_r := rl.Rectangle{
        sv.view_rect.x + sv.view_rect.width - bar_w,
        sv.view_rect.y,
        bar_w,
        sv.view_rect.height,
    }
    rl.DrawRectangleRec(track_r, rl.DARKGRAY)

    visible_ratio := sv.view_rect.height / sv.content_h
    thumb_h := sv.view_rect.height * visible_ratio
    thumb_y := track_r.y +
        (sv.scroll / max_scroll) * (sv.view_rect.height - thumb_h)
    thumb_r := rl.Rectangle{track_r.x, thumb_y, bar_w, thumb_h}

    want_cursor_over(thumb_r, .RESIZE_NS)

    rl.DrawRectangleRec(thumb_r, rl.LIGHTGRAY)
    rl.DrawRectangleLinesEx(thumb_r, 1, rl.BLACK)
}
