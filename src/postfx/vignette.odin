package postfx

import "core:c"
import rl "deps:raylib"
import "raytmfkit:core"

@(private)
VIGNETTE_FS :: #load("shaders/vignette.fshader", cstring)

// Радиальное затемнение к краям экрана.
// Одна стадия в Chain.
Vignette :: struct {
    shader:       rl.Shader,
    strength_loc: c.int,
    radius_loc:   c.int,

    strength: f32,   // 0..1
    radius:   f32,   // 0..1, типично 0.3..0.6
}

init_vignette :: proc(v: ^Vignette, strength := f32(0.5), radius := f32(0.4)) {
    v.shader       = rl.LoadShaderFromMemory(nil, VIGNETTE_FS)
    v.strength_loc = rl.GetShaderLocation(v.shader, "uStrength")
    v.radius_loc   = rl.GetShaderLocation(v.shader, "uRadius")
    v.strength     = strength
    v.radius       = radius
}

deinit_vignette :: proc(v: ^Vignette) {
    rl.UnloadShader(v.shader)
}

setup_vignette_stage :: proc(c: ^Chain, i: int, v: ^Vignette) {
    set_stage(c, i, v.shader, v, vignette_prepare)
}

@(private)
vignette_prepare :: proc(c: ^Chain, s: ^Stage) {
    v := cast(^Vignette)s.user
    if v.strength_loc >= 0 { core.set_shader_f32(v.shader, v.strength_loc, v.strength) }
    if v.radius_loc   >= 0 { core.set_shader_f32(v.shader, v.radius_loc,   v.radius)   }
}
