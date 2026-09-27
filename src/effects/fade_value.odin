package effects

import "core:math"
import "core:math/linalg"
import "core:math/ease"
import "base:intrinsics"

IS_ARRAY :: intrinsics.type_is_array
IS_INT :: intrinsics.type_is_integer

FadeValue :: struct($T: typeid) {
	using effect:      Effect,
	from, to, current: T,
}

init_fade_value :: proc(fv: ^FadeValue($T), start: T, e: ease.Ease = .Exponential_Out) {
	fv.effect = Effect{ ease_type = e }
    fv.from    = start
    fv.to      = start
    fv.current = start
}

fade_value_to :: proc(fv: ^FadeValue($T), target: T, duration: f32) {
	fv.current = fv.to
    fv.from    = fv.current
    fv.to      = target
    fv.effect.duration = duration
    fv.effect.elapsed  = 0
    fv.effect.active   = true
}

fade_value_update :: proc(fv: ^FadeValue($T), dt: f32) {
	finished := effect_update(&fv.effect, dt)
    t := effect_progress(&fv.effect)

    when IS_ARRAY(T) {
        for i in 0 ..< len(T) {
            fv.current[i] = linalg.lerp(fv.from[i], fv.to[i], t)
        }
    } else when IS_INT(T) {
        fv.current = T(math.round(linalg.lerp(f32(fv.from), f32(fv.to), t)))
    } else {
        fv.current = linalg.lerp(fv.from, fv.to, t)
    }

    if finished { fv.current = fv.to }
}

fade_value_set :: proc(fv: ^FadeValue($T), value: T) {
	fv.effect.active = false
    fv.from    = value
    fv.to      = value
    fv.current = value
}
