package light

import rl "deps:raylib"
import eff "raytmfkit:effects"

MAX_LIGHTS :: 16

Type :: enum i32 {
    DIRECTIONAL,
    POINT,
}

Light :: struct {
    type:           Type,
    enabled:        b32,
    position:       [3]f32,
    target:         [3]f32,
    color:          eff.FadeTranslate,
    attenuation:    f32,
    power:          eff.FadeValue(f32),

    // Shader uniform locations. -1 if not found.
    enabled_loc:    i32,
    type_loc:       i32,
    position_loc:   i32,
    target_loc:     i32,
    color_loc:      i32,
    attenuation_loc: i32,
    power_loc:      i32,
}

// Создаёт свет по индексу `index` в шейдере.
// Игра сама решает, какой индекс ей нужен (обычно последовательные).
create :: proc(
    index:       int,
    type:        Type,
    position:    [3]f32,
    target:      [3]f32,
    color:       rl.Color,
    shader:      rl.Shader,
    attenuation := f32(0.05),
    power       := f32(1),
) -> Light {
    light: Light
    light.type        = type
    light.enabled     = true
    light.position    = position
    light.target      = target
    light.attenuation = attenuation

    eff.init_fade_translate(&light.color, color)
    eff.init_fade_value(&light.power, power)

    // Locations получаются через TextFormat — единственный способ подставить индекс.
    light.enabled_loc     = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].enabled",     index)))
    light.type_loc        = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].type",        index)))
    light.position_loc    = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].position",    index)))
    light.target_loc      = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].target",      index)))
    light.color_loc       = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].color",       index)))
    light.attenuation_loc = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].attenuation", index)))
    light.power_loc       = i32(rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].power",       index)))

    return light
}

// Быстрый выключатель. Без анимации.
disable :: proc(l: ^Light) {
    l.enabled = false
}

enable :: proc(l: ^Light) {
    l.enabled = true
}
