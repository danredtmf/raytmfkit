package debug

import rl "deps:raylib"
import "core:fmt"
import "raytmfkit:core"

// Публичные флаги — игра сама решает, когда их включать.
enabled:      bool  // общий тумблер оверлея
show_fps:     bool = true
show_memory:  bool = true

// Настройки отображения.
text_color:   rl.Color = rl.LIME
font_size:    f32 = 20
line_spacing: f32 = 4
margin:       f32 = 10

Label :: struct {
    name:  string,
    value: string,
}

@(private)
labels: [dynamic]Label

init :: proc() {
    labels = make([dynamic]Label)
}

shutdown :: proc() {
    delete(labels)
}

// Очищает буфер меток. Вызывается игрой в начале каждого update-кадра.
begin_frame :: proc() {
    clear(&labels)
}

// Добавляет одну метку. Строки должны быть валидны на момент draw_overlay.
// Для литералов и уже хранимых строк — работает как есть.
add :: proc(name, value: string) {
    append(&labels, Label{name, value})
}

// Форматирует и добавляет метку.
// Форматированная строка аллоцируется в temp_allocator,
// который игра очищает free_all в конце кадра — освобождать вручную не нужно.
addf :: proc(name, format: string, args: ..any) {
    s := fmt.aprintf(format, ..args, allocator = context.temp_allocator)
    append(&labels, Label{name, s})
}

// Рисует оверлей. Вызывать в draw_ui после всего остального.
draw_overlay :: proc() {
    if !enabled { return }

    size    := core.get_scale(font_size)
    spacing := core.get_scale(line_spacing)
    m       := core.get_scale(margin)

    x := i32(m)
    y := i32(m)
    step := i32(size + spacing)

    if show_fps {
        s := rl.TextFormat("FPS: %d", rl.GetFPS())
        rl.DrawText(s, x, y, i32(size), text_color)
        y += step
    }

    if show_memory {
        mb := ram_usage_mb()
        s  := rl.TextFormat("RAM: %d MB", mb)
        rl.DrawText(s, x, y, i32(size), text_color)
        y += step
    }

    for label in labels {
        name_cs  := core.cstring_temp(label.name)
        value_cs := core.cstring_temp(label.value)
        if name_cs == nil || value_cs == nil { continue }

        s := rl.TextFormat("%s: %s", name_cs, value_cs)
        rl.DrawText(s, x, y, i32(size), text_color)
        y += step
    }
}
