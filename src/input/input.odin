package input

import rl "deps:raylib"
import kcore "raytmfkit:core"

is_mouse_pressed :: proc(button := rl.MouseButton.LEFT) -> bool {
	return rl.IsMouseButtonPressed(button)
}

is_mouse_down :: proc(button := rl.MouseButton.LEFT) -> bool {
	return rl.IsMouseButtonDown(button)
}

is_mouse_up :: proc(button := rl.MouseButton.LEFT) -> bool {
	return rl.IsMouseButtonUp(button)
}

is_mouse_released :: proc(button := rl.MouseButton.LEFT) -> bool {
	return rl.IsMouseButtonReleased(button)
}

hover_rect :: proc(rect: rl.Rectangle) -> bool {
	return rl.CheckCollisionPointRec(kcore.ctx.mouse, rect)
}

pressed_on_rect :: proc(rect: rl.Rectangle, b := rl.MouseButton.LEFT) -> bool {
	return hover_rect(rect) && is_mouse_pressed(b)
}

down_on_rect :: proc(rect: rl.Rectangle, b := rl.MouseButton.LEFT) -> bool {
	return hover_rect(rect) && is_mouse_down(b)
}

up_on_rect :: proc(rect: rl.Rectangle, b := rl.MouseButton.LEFT) -> bool {
	return hover_rect(rect) && is_mouse_up(b)
}

released_on_rect :: proc(rect: rl.Rectangle, b := rl.MouseButton.LEFT) -> bool {
	return hover_rect(rect) && is_mouse_released(b)
}

hover_circle :: proc(c: rl.Vector2, r: f32) -> bool {
	return rl.CheckCollisionPointCircle(kcore.ctx.mouse, c, r)
}

pressed_on_circle :: proc(c: rl.Vector2, r: f32, b := rl.MouseButton.LEFT) -> bool {
	return hover_circle(c, r) && is_mouse_pressed(b)
}

wheel :: proc() -> f32 {
	return rl.GetMouseWheelMove()
}
