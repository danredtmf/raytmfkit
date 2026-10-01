package ui

import rl "deps:raylib"
import "raytmfkit:core"
import "raytmfkit:input"

// Хелпер: если мышь над rect — сообщить core желаемый курсор.
// Возвращает hovered, чтобы вызывающий не проверял дважды.
want_cursor_over :: proc(rect: rl.Rectangle, c: core.CursorIntent) -> bool {
    if input.hover_rect(rect) {
        core.want_cursor(c)
        return true
    }
    return false
}

want_cursor_over_circle :: proc(c: rl.Vector2, r: f32, intent: core.CursorIntent) -> bool {
    if input.hover_circle(c, r) {
        core.want_cursor(intent)
        return true
    }
    return false
}