package light

import rl "deps:raylib"
import "raytmfkit:effects"
import "raytmfkit:core"

// Обновляет плавные переходы цвета и power у всех источников.
// Зови раз в кадр из update-цикла.
update_colors :: proc(lights: []Light, dt: f32) {
    for i in 0 ..< len(lights) {
        l := &lights[i]
        if !l.enabled { continue }
        effects.fade_translate_update(&l.color, dt)
        effects.fade_value_update(&l.power, dt)
    }
}

// Загружает значения одного источника в шейдер.
update_values :: proc(shader: rl.Shader, l: ^Light) {
    core.set_shader_i32(shader, l.enabled_loc,     i32(l.enabled))
    core.set_shader_i32(shader, l.type_loc,        i32(l.type))
    core.set_shader_vec3(shader, l.position_loc,   l.position)
    core.set_shader_vec3(shader, l.target_loc,     l.target)
    core.set_shader_color(shader, l.color_loc,     l.color.current)
    core.set_shader_f32(shader, l.attenuation_loc, l.attenuation)
    core.set_shader_f32(shader, l.power_loc,       l.power.current)
}

// Загружает все источники в шейдер.
// Зови из draw-цикла перед рендером (или перед update_shaders, если есть цепочка).
update_all :: proc(shader: rl.Shader, lights: []Light) {
    for i in 0 ..< len(lights) {
        update_values(shader, &lights[i])
    }
}
