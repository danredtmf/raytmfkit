package postfx

import rl "deps:raylib"
import "raytmfkit:core"

@(private)
CHROMA_FS :: #load("shaders/chroma.fshader", cstring)

Chroma :: struct {
    shader: rl.Shader,
    amount: f32,
}

init_chroma :: proc(
    ch:              ^Chroma,
    amount           := f32(0.003),
    hot_reload_path  := "",
) {
    ch.shader = rl.LoadShaderFromMemory(nil, CHROMA_FS)
    ch.amount = amount
    if hot_reload_path != "" {
        core.register_reloadable_shader(
            name    = "chroma",
            target  = &ch.shader,
            fs_path = hot_reload_path,
        )
    }
}

deinit_chroma :: proc(ch: ^Chroma) {
    rl.UnloadShader(ch.shader)
}

setup_chroma_stage :: proc(c: ^Chain, i: int, ch: ^Chroma) {
    set_stage(c, i, ch.shader, ch, chroma_prepare)
}

@(private)
chroma_prepare :: proc(c: ^Chain, s: ^Stage) {
    ch := cast(^Chroma)s.user
    s.shader = ch.shader

    a_loc := rl.GetShaderLocation(ch.shader, "uAmount")
    if a_loc >= 0 { core.set_shader_f32(ch.shader, a_loc, ch.amount) }
}