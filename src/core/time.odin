package core

import rl "deps:raylib"

begin_frame :: proc() {
    ctx.delta       = rl.GetFrameTime()
    ctx.time        = rl.GetTime()
    ctx.frame      += 1
    ctx.screen      = render_resolution()
    ctx.screen_vec2 = {f32(ctx.screen.x), f32(ctx.screen.y)}
    ctx.screen_half = ctx.screen_vec2 / 2
    ctx.mouse       = rl.GetMousePosition()
    ctx.mouse_delta = rl.GetMouseDelta()
    ctx.fullscreen  = is_fullscreen()
    ctx.focused     = rl.IsWindowFocused()
    reset_cursor_intent()
}
