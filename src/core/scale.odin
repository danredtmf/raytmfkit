package core

import "base:intrinsics"
import rl "deps:raylib"

IS_INT :: intrinsics.type_is_integer
IS_FLOAT :: intrinsics.type_is_float

ScaleCfg :: struct {
	virtual_size: rl.Vector2,
}

scale_cfg := ScaleCfg {
	virtual_size = {1280, 720},
}

// Удобный сеттер, чтобы не лезть в структуру.
set_virtual_size :: proc(w, h: f32) {
	scale_cfg.virtual_size = {w, h}
}

// Возвращает значение, отмасштабированное под текущий экран.
// Модель Godot canvas_items: scale = min(screen / virtual_size), без ветвлений по fullscreen.
get_scale :: proc(value: $T) -> f32 where IS_INT(T) || IS_FLOAT(T) {
	scale := min(
		ctx.screen_vec2.x / scale_cfg.virtual_size.x,
		ctx.screen_vec2.y / scale_cfg.virtual_size.y,
	)

	when IS_INT(T) {return f32(value) * scale} else {return value * scale}
}

// Только множитель, без применения к значению.
// Полезно, когда нужно умножить что-то вручную (например, всю позицию).
get_scale_value :: proc() -> f32 {
	return min(
		ctx.screen_vec2.x / scale_cfg.virtual_size.x,
		ctx.screen_vec2.y / scale_cfg.virtual_size.y,
	)
}
