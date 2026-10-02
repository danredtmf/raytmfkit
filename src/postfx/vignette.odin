package postfx

import rl "deps:raylib"
import "raytmfkit:core"

@(private)
VIGNETTE_FS :: #load("shaders/vignette.fshader", cstring)

Vignette :: struct {
    shader:   rl.Shader,
    strength: f32,
    radius:   f32,
}

init_vignette :: proc(
    v:               ^Vignette,
    strength         := f32(0.5),
    radius           := f32(0.4),
    hot_reload_path  := "",
) {
    v.shader   = rl.LoadShaderFromMemory(nil, VIGNETTE_FS)
    v.strength = strength
    v.radius   = radius
    if hot_reload_path != "" {
        core.register_reloadable_shader(
            name    = "vignette",
            target  = &v.shader,
            fs_path = hot_reload_path,
        )
    }
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
    s.shader = v.shader

    st_loc := rl.GetShaderLocation(v.shader, "uStrength")
    rd_loc := rl.GetShaderLocation(v.shader, "uRadius")
    if st_loc >= 0 { core.set_shader_f32(v.shader, st_loc, v.strength) }
    if rd_loc >= 0 { core.set_shader_f32(v.shader, rd_loc, v.radius)   }
}