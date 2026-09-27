package transitions

import rl "deps:raylib"
import "raytmfkit:effects"

Phase :: enum {
	IDLE,
	FADE_IN,
	HOLD,
	FADE_OUT,
}

MidCallback :: #type proc()

Transition :: struct {
	phase:     Phase,
	fade:      effects.FadeTranslate,
	hold:      effects.Timer,
	cover:     rl.Color, // во что затемняемся
	reveal:    rl.Color, // что открывается после
	in_dur:    f32,
	hold_dur:  f32,
	out_dur:   f32,
	on_mid:    MidCallback,
	fired_mid: bool,
}

init :: proc(t: ^Transition) {
    t.phase     = .IDLE
    t.fired_mid = false
    effects.init_fade_translate(&t.fade, rl.BLANK)
    effects.init_timer(&t.hold)
    t.cover  = rl.BLACK
    t.reveal = rl.BLANK
    t.in_dur = 1
    t.hold_dur = 2
    t.out_dur  = 1
}

is_active :: proc(t: Transition) -> bool {
    return t.phase != .IDLE
}

// Запустить переход. on_mid вызовется, когда экран полностью закрыт.
begin :: proc(
    t:            ^Transition,
    on_mid:       MidCallback,
    cover  := rl.BLACK,
    reveal := rl.BLANK,
    in_dur := f32(1),
    hold_dur := f32(2),
    out_dur  := f32(1),
) {
    // Если уже идёт переход — отменяем старый, стартуем новый от текущего цвета
    t.cover     = cover
    t.reveal    = reveal
    t.in_dur    = in_dur
    t.hold_dur  = hold_dur
    t.out_dur   = out_dur
    t.on_mid    = on_mid
    t.fired_mid = false
    t.phase     = .FADE_IN

    effects.fade_translate_to(&t.fade, cover, in_dur)
}

// Обновление. Зови раз в кадр.
update :: proc(t: ^Transition, dt: f32) {
    switch t.phase {
    case .IDLE:
        return

    case .FADE_IN:
        effects.fade_translate_update(&t.fade, dt)
        if !t.fade.active {
            t.phase = .HOLD
            effects.timer_to(&t.hold, t.hold_dur)
        }

    case .HOLD:
        effects.timer_update(&t.hold, dt)
        if !t.fired_mid {
            t.fired_mid = true
            if t.on_mid != nil { t.on_mid() }
        }
        // Ждём, пока timer доиграет — но колбэк уже сработал
        if !t.hold.active {
            t.phase = .FADE_OUT
            effects.fade_translate_to(&t.fade, t.reveal, t.out_dur)
        }

    case .FADE_OUT:
        effects.fade_translate_update(&t.fade, dt)
        if !t.fade.active {
            t.phase = .IDLE
        }
    }
}
