package effects

import rl "deps:raylib"
import "core:math/linalg"
import "core:math/ease"

FadeTranslate :: struct {
    using effect: Effect,
    from, to, current: rl.Color,
}

init_fade_translate   :: proc(ft: ^FadeTranslate, start := rl.BLACK, e := ease.Ease.Exponential_Out) {
	ft.effect = Effect{ ease_type = e }
    ft.from    = start
    ft.to      = start
    ft.current = start
}

fade_translate_to     :: proc(ft: ^FadeTranslate, target: rl.Color, duration: f32) {
	ft.current = ft.to
    ft.from    = ft.current
    ft.to      = target
    ft.effect.duration = duration
    ft.effect.elapsed  = 0
    ft.effect.active   = true
}

fade_translate_update :: proc(ft: ^FadeTranslate, dt: f32) {
	finished := effect_update(&ft.effect, dt)
    t := effect_progress(&ft.effect)
    ft.current = lerp_color(ft.from, ft.to, t)
    if finished { ft.current = ft.to }
}

fade_translate_set    :: proc(ft: ^FadeTranslate, value: rl.Color) {
	ft.effect.active = false
    ft.from    = value
    ft.to      = value
    ft.current = value
}

lerp_color :: proc(a, b: rl.Color, t: f32) -> rl.Color {
	r := clamp(linalg.lerp(f32(a.r), f32(b.r), t) + 0.5, 0, 255)
    g := clamp(linalg.lerp(f32(a.g), f32(b.g), t) + 0.5, 0, 255)
    bl := clamp(linalg.lerp(f32(a.b), f32(b.b), t) + 0.5, 0, 255)
    al := clamp(linalg.lerp(f32(a.a), f32(b.a), t) + 0.5, 0, 255)
    return { u8(r), u8(g), u8(bl), u8(al) }
}
