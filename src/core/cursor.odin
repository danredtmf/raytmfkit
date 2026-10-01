package core

import rl "deps:raylib"

CursorIntent :: enum {
    DEFAULT,
    POINTING_HAND,
    IBEAM,
    CROSSHAIR,
    RESIZE_EW,
    RESIZE_NS,
    NOT_ALLOWED,
}

@(private)
current_cursor := CursorIntent.DEFAULT

@(private)
next_cursor := CursorIntent.DEFAULT

// Сообщить, какой курсор нужен в этом кадре.
// Можно звать сколько угодно раз — выигрывает последний вызов.
// По умолчанию — DEFAULT, если никто не позвал.
want_cursor :: proc(c: CursorIntent) {
    next_cursor = c
}

// Применить желание. Звать один раз в конце кадра (см. ниже).
// Если совпадает с текущим — физически SetMouseCursor не вызывается.
apply_cursor :: proc() {
    if next_cursor != current_cursor {
        rl.SetMouseCursor(to_rl(next_cursor))
        current_cursor = next_cursor
    }
}

// Сброс намерения на новый кадр.
@(private)
reset_cursor_intent :: proc() {
    next_cursor = .DEFAULT
}

@(private)
to_rl :: proc(c: CursorIntent) -> rl.MouseCursor {
    switch c {
    case .DEFAULT:       return .DEFAULT
    case .POINTING_HAND: return .POINTING_HAND
    case .IBEAM:         return .IBEAM
    case .CROSSHAIR:     return .CROSSHAIR
    case .RESIZE_EW:     return .RESIZE_EW
    case .RESIZE_NS:     return .RESIZE_NS
    case .NOT_ALLOWED:   return .NOT_ALLOWED
    }
    return .DEFAULT
}
