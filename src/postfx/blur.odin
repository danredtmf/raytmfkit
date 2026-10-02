package postfx

import "core:c"
import rl "deps:raylib"
import "raytmfkit:core"

@(private)
BLUR_FS :: #load("shaders/blur.fshader", cstring)

// Разделяемый (separable) гауссов blur: H-проход, затем V-проход.
// Каждый проход — отдельная Stage, шейдер общий, различается uDirection.
//
// Занимает 2 подряд идущих stage'а в Chain. Радиус можно менять
// между кадрами — шейдер читает его каждый prepare.
Blur :: struct {
    shader:        rl.Shader,
    texel_loc:     c.int,
    direction_loc: c.int,
    radius_loc:    c.int,

    radius: f32,   // в текселях виртуального рендера
}

init_blur :: proc(b: ^Blur, radius := f32(2)) {
    b.shader        = rl.LoadShaderFromMemory(nil, BLUR_FS)
    b.texel_loc     = rl.GetShaderLocation(b.shader, "uTexel")
    b.direction_loc = rl.GetShaderLocation(b.shader, "uDirection")
    b.radius_loc    = rl.GetShaderLocation(b.shader, "uRadius")
    b.radius        = radius
}

deinit_blur :: proc(b: ^Blur) {
    rl.UnloadShader(b.shader)
}

// Настраивает stage'ы `first` (H) и `first+1` (V).
setup_blur_stages :: proc(c: ^Chain, first: int, b: ^Blur) {
    set_stage(c, first,     b.shader, b, blur_prepare_h)
    set_stage(c, first + 1, b.shader, b, blur_prepare_v)
}

@(private)
blur_prepare_h :: proc(c: ^Chain, s: ^Stage) {
    blur_set_uniforms(c, cast(^Blur)s.user, {1, 0})
}

@(private)
blur_prepare_v :: proc(c: ^Chain, s: ^Stage) {
    blur_set_uniforms(c, cast(^Blur)s.user, {0, 1})
}

@(private)
blur_set_uniforms :: proc(c: ^Chain, b: ^Blur, dir: rl.Vector2) {
    texel := rl.Vector2{
        1.0 / f32(c.virtual_size[0]),
        1.0 / f32(c.virtual_size[1]),
    }
    if b.texel_loc     >= 0 { core.set_shader_vec2(b.shader, b.texel_loc, texel) }
    if b.direction_loc >= 0 { core.set_shader_vec2(b.shader, b.direction_loc, dir) }
    if b.radius_loc    >= 0 { core.set_shader_f32 (b.shader, b.radius_loc, b.radius) }
}
