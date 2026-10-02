package postfx

import "core:c"
import rl "deps:raylib"
import "raytmfkit:core"

@(private)
CHROMA_FS :: #load("shaders/chroma.fshader", cstring)

// Радиальная хроматическая аберрация: R сдвигается наружу,
// B — внутрь, G остаётся. Одна стадия в Chain.
Chroma :: struct {
    shader:     rl.Shader,
    amount_loc: c.int,

    amount: f32,   // 0 — выключено, 0.002..0.01 — заметно
}

init_chroma :: proc(ch: ^Chroma, amount := f32(0.003)) {
    ch.shader     = rl.LoadShaderFromMemory(nil, CHROMA_FS)
    ch.amount_loc = rl.GetShaderLocation(ch.shader, "uAmount")
    ch.amount     = amount
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
    if ch.amount_loc >= 0 {
        core.set_shader_f32(ch.shader, ch.amount_loc, ch.amount)
    }
}