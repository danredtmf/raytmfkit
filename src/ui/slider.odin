package ui

import rl "deps:raylib"
import "raytmfkit:core"
import "raytmfkit:text"
import "raytmfkit:input"

Slider :: struct {
    value:      f32,
    min, max:   f32,
    active:     bool,   // зажат ли knob
    rect:       rl.Rectangle,  // заполняется при рисовании
}

update_slider :: proc(
    s: ^Slider,
    label: cstring,
    font: rl.Font,
    size: f32,
    anchor: rl.Vector2,       // центр текста над слайдером
    width := f32(450),
    height := f32(25),
) {
    // Текст-заголовок сверху
    m := text.measure_text(font, label, core.get_scale(size))

    // Значение
    val_str := rl.TextFormat("%.2f", s.value)
    mv := text.measure_text(font, val_str, core.get_scale(size))

    text_pos := rl.Vector2{ anchor.x - m.x / 2, anchor.y - core.get_scale(size) }
    text_rect := rl.Rectangle{
        text_pos.x - core.get_scale(10),
        text_pos.y - core.get_scale(4),
        m.x + core.get_scale(20),
        m.y + m.y + core.get_scale(12),
    }
    rl.DrawRectangleRec(text_rect, rl.BLACK)
    rl.DrawRectangleLinesEx(text_rect, 1, rl.DARKGRAY)
    text.draw_text_ex(font, label, core.get_scale(size), text_pos, rl.WHITE)

    // Трек слайдера
    scaled_w := core.get_scale(width)
    scaled_h := core.get_scale(height)
    track := rl.Rectangle{
        anchor.x - scaled_w / 2,
        text_rect.y + text_rect.height + scaled_h / 2,
        scaled_w,
        scaled_h,
    }
    s.rect = rl.Rectangle{
        track.x,
        text_rect.y,
        track.width,
        text_rect.height + track.height + scaled_h / 2,
    }

    rl.DrawRectangleRec(track, rl.BLACK)
    rl.DrawRectangleLinesEx(track, 1, rl.DARKGRAY)

    knob_r   := core.get_scale(8)
    padding  := knob_r * 1.5
    usable_w := track.width - 2 * padding

    t := clamp((s.value - s.min) / (s.max - s.min), 0, 1)
    knob_x := track.x + padding + t * usable_w
    knob_y := track.y + track.height / 2

    if input.pressed_on_rect(track) ||
       input.pressed_on_circle({knob_x, knob_y}, knob_r) {
        s.active = true
    }
    if input.is_mouse_released() { s.active = false }

    if s.active && input.is_mouse_down() {
        t = clamp((core.ctx.mouse.x - (track.x + padding)) / usable_w, 0, 1)
        s.value = s.min + t * (s.max - s.min)
    }

    rl.DrawCircle(i32(knob_x), i32(knob_y), knob_r, s.active ? rl.DARKGRAY : rl.WHITE)
    rl.DrawCircleLines(i32(knob_x), i32(knob_y), knob_r, s.active ? rl.BLACK : rl.DARKGRAY)

    // Значение внизу
    val_pos := rl.Vector2{ anchor.x - mv.x / 2, text_pos.y + m.y + core.get_scale(4) }
    text.draw_text_ex(font, val_str, core.get_scale(size), val_pos, rl.WHITE)
}
