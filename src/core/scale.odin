package core

import "base:intrinsics"
import rl "deps:raylib"

IS_INT :: intrinsics.type_is_integer
IS_FLOAT :: intrinsics.type_is_float

ScaleCfg :: struct {
	virtual_size: rl.Vector2,
	min, max:     f32,
}

scale_cfg := ScaleCfg {
	virtual_size = {1920, 1080},
	min          = 0.5,
	max          = 2,
}

get_scale :: proc(value: $T, lo := scale_cfg.min, hi := scale_cfg.max) -> f32
    where IS_INT(T) || IS_FLOAT(T) {

    scale := f32(1)
    if ctx.fullscreen {
        scale = min(
            ctx.screen_vec2.x / scale_cfg.virtual_size.x,
            ctx.screen_vec2.y / scale_cfg.virtual_size.y,
        )
    }
    scale = clamp(scale, lo, hi)

    when IS_INT(T) {
        return f32(value) * scale
    } else {
        return value * scale
    }
}

// get_scale_raw :: proc(value: $T) -> f32 {}
