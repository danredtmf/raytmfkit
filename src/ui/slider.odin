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
    s:           ^Slider,
    label:       cstring,
    font:        rl.Font,
    size:        f32,
    anchor:      rl.Vector2,
    anchor_mode  := Anchor.CENTER,
    width        := f32(450),
    height       := f32(25),
) {
    // 1. Считаем размеры всех частей виджета
    m       := text.measure_text(font, label, core.get_scale(size))
    val_str := rl.TextFormat("%.2f", s.value)
    mv      := text.measure_text(font, val_str, core.get_scale(size))

    text_h  := m.y + mv.y + core.get_scale(8)   // заголовок + значение + отступ между
    title_w := m.x + core.get_scale(20)
    val_w   := mv.x + core.get_scale(20)
    top_w   := max(title_w, val_w)              // ширина по самой широкой строке сверху

    track_w := core.get_scale(width)
    track_h := core.get_scale(height)

    total_w := max(top_w, track_w)
    total_h := text_h + track_h + core.get_scale(8)  // + отступ между текстом и треком

    // 2. Общий прямоугольник виджета — от него и отталкивается anchor
    origin := resolve_anchor(anchor, {total_w, total_h}, anchor_mode)

    // 3. Заголовок — по центру верхней части
    title_pos := rl.Vector2{
        origin.x + (total_w - m.x) / 2,
        origin.y,
    }
    // Рамка заголовка — только под ним
    title_rect := rl.Rectangle{
        origin.x + (total_w - title_w) / 2,
        origin.y - core.get_scale(4),
        title_w,
        m.y + core.get_scale(8),
    }
    rl.DrawRectangleRec(title_rect, rl.BLACK)
    rl.DrawRectangleLinesEx(title_rect, 1, rl.DARKGRAY)
    text.draw_text_ex(font, label, core.get_scale(size), title_pos, rl.WHITE)

    // 4. Значение — по центру, под заголовком
    val_pos := rl.Vector2{
        origin.x + (total_w - mv.x) / 2,
        origin.y + m.y + core.get_scale(7),
    }
    text.draw_text_ex(font, val_str, core.get_scale(size), val_pos, rl.WHITE)

    // 5. Трек — по центру нижней части
    track := rl.Rectangle{
        origin.x + (total_w - track_w) / 2,
        origin.y + text_h + core.get_scale(4),
        track_w,
        track_h,
    }

    s.rect = rl.Rectangle{origin.x, origin.y, total_w, total_h}

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
}
