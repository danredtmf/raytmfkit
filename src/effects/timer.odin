package effects

Timer :: struct {
	using effect: Effect,
	current:      f32, // 0..1
}

init_timer :: proc(t: ^Timer, start := f32(0)) {
	t.effect = Effect{}
	t.current = start
}

timer_to :: proc(t: ^Timer, duration: f32) {
	t.current = 0
	t.effect.duration = duration
	t.effect.elapsed = 0
	t.effect.active = true
}

timer_update :: proc(t: ^Timer, dt: f32) {
	finished := effect_update(&t.effect, dt)
	t.current = effect_progress(&t.effect)
	if finished {t.current = 1}
}
