package postfx

import rl "deps:raylib"
import "raytmfkit:core"

@(private)
BLUR_FS :: #load("shaders/blur.fshader", cstring)

Blur :: struct {
    shader: rl.Shader,
    radius: f32,
}

init_blur :: proc(
    b:               ^Blur,
    radius           := f32(2),
    hot_reload_path  := "",
) {
    b.shader = rl.LoadShaderFromMemory(nil, BLUR_FS)
    b.radius = radius
    if hot_reload_path != "" {
        core.register_reloadable_shader(
            name    = "blur",
            target  = &b.shader,
            fs_path = hot_reload_path,
        )
    }
}

deinit_blur :: proc(b: ^Blur) {
    rl.UnloadShader(b.shader)
}

setup_blur_stages :: proc(c: ^Chain, first: int, b: ^Blur) {
    set_stage(c, first,     b.shader, b, blur_prepare_h)
    set_stage(c, first + 1, b.shader, b, blur_prepare_v)
}

@(private)
blur_prepare_h :: proc(c: ^Chain, s: ^Stage) {
    b := cast(^Blur)s.user
    s.shader = b.shader                   // ← актуализирует ссылку после reload
    blur_set_uniforms(c, b, {1, 0})
}

@(private)
blur_prepare_v :: proc(c: ^Chain, s: ^Stage) {
    b := cast(^Blur)s.user
    s.shader = b.shader
    blur_set_uniforms(c, b, {0, 1})
}

@(private)
blur_set_uniforms :: proc(c: ^Chain, b: ^Blur, dir: rl.Vector2) {
    texel := rl.Vector2{
        1.0 / f32(c.virtual_size[0]),
        1.0 / f32(c.virtual_size[1]),
    }
    t_loc := rl.GetShaderLocation(b.shader, "uTexel")
    d_loc := rl.GetShaderLocation(b.shader, "uDirection")
    r_loc := rl.GetShaderLocation(b.shader, "uRadius")
    if t_loc >= 0 { core.set_shader_vec2(b.shader, t_loc, texel) }
    if d_loc >= 0 { core.set_shader_vec2(b.shader, d_loc, dir) }
    if r_loc >= 0 { core.set_shader_f32 (b.shader, r_loc, b.radius) }
}
