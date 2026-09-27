package effects

import "core:math/ease"

Effect :: struct {
	duration, elapsed: f32,
	active:            bool,
	ease_type:         ease.Ease,
}

effect_update :: proc(e: ^Effect, dt: f32) -> bool {
	if !e.active || dt <= 0 {return false}

	if e.duration <= 0 {
		e.elapsed = 0
		e.active = false
		return true
	}

	e.elapsed += dt
	if e.elapsed >= e.duration {
		e.elapsed = e.duration
		e.active = false
		return true
	}
	return false
}

effect_progress :: proc(e: ^Effect) -> f32 { // 0..1 с учётом ease
	if e.duration <= 0 {return 1}
	t := e.elapsed / e.duration
	if t > 1 {t = 1}
	return ease.ease(e.ease_type, t)
}
