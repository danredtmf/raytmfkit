package ui

import rl "deps:raylib"

// Куда относительно элемента указывает переданная точка.
Anchor :: enum {
    TOP_LEFT,
    TOP_CENTER,
    TOP_RIGHT,
    CENTER,
    BOTTOM_LEFT,
    BOTTOM_CENTER,
    BOTTOM_RIGHT,
}

// Верхний-левый угол элемента size при данной опорной точке и привязке.
resolve_anchor :: proc(anchor: rl.Vector2, size: rl.Vector2, mode: Anchor) -> rl.Vector2 {
    switch mode {
    case .TOP_LEFT:      return anchor
    case .TOP_CENTER:    return {anchor.x - size.x / 2, anchor.y}
    case .TOP_RIGHT:     return {anchor.x - size.x, anchor.y}
    case .CENTER:        return anchor - size / 2
    case .BOTTOM_LEFT:   return {anchor.x, anchor.y - size.y}
    case .BOTTOM_CENTER: return {anchor.x - size.x / 2, anchor.y - size.y}
    case .BOTTOM_RIGHT:  return anchor - size
    }
    return anchor
}
