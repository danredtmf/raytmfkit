package core

import rl "deps:raylib"

Ctx :: struct {
    screen:       [2]i32,
    screen_vec2:  rl.Vector2,
    screen_half:  rl.Vector2,
    mouse:        rl.Vector2,
    mouse_delta:  rl.Vector2,
    virtual_size: rl.Vector2,   // "эталон", обычно 1920x1080
    default_size: [2]i32,
    delta:        f32,
    time:         f64,
    frame:        u64,
    fullscreen:   bool,
    focused:      bool,
}

ctx: Ctx
