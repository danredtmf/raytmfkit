package postfx

import rl "deps:raylib"

RenderTarget :: struct {
    tex: rl.RenderTexture2D,
}

// Размер передаётся явно — RenderTarget больше не привязан к окну.
init_target :: proc(t: ^RenderTarget, w, h: i32) {
    t.tex = rl.LoadRenderTexture(w, h)
}

deinit_target :: proc(t: ^RenderTarget) {
    rl.UnloadRenderTexture(t.tex)
}

size_of_target :: proc(t: RenderTarget) -> [2]i32 {
    return {t.tex.texture.width, t.tex.texture.height}
}

begin_target :: proc(t: RenderTarget) {
    rl.BeginTextureMode(t.tex)
}

end_target :: proc() {
    rl.EndTextureMode()
}

// Рисует src в dst. Если shader валиден — через BeginShaderMode, иначе — просто копия.
blit :: proc(dst: RenderTarget, src: rl.Texture2D, shader: rl.Shader = {}) {
    rl.BeginTextureMode(dst.tex)
    defer rl.EndTextureMode()

    if rl.IsShaderValid(shader) {
        _draw_through_shader(src, shader)
    } else {
        rl.DrawTexture(src, 0, 0, rl.WHITE)
    }
}

@(private)
_draw_through_shader :: proc(src: rl.Texture2D, shader: rl.Shader) {
    rl.BeginShaderMode(shader)
    defer rl.EndShaderMode()
    rl.DrawTexture(src, 0, 0, rl.WHITE)
}