package text

import rl "deps:raylib"

TextAlignH :: enum {
	LEFT,
	CENTER,
	RIGHT,
	JUSTIFY,
}
TextAlignV :: enum {
	TOP,
	MIDDLE,
	BOTTOM,
}

draw_text_aligned :: proc(
	text: cstring,
	size: f32,
	pos: rl.Vector2, // точка якоря
	color: rl.Color,
	align_h: TextAlignH = .CENTER,
	align_v: TextAlignV = .MIDDLE,
	offset: rl.Vector2 = {0, 0},
) -> rl.Rectangle {
	m := measure_text_current(text, size)

	x: f32
	switch align_h {
	case .LEFT, .JUSTIFY:
		x = pos.x
	case .CENTER:
		x = pos.x - m.x / 2
	case .RIGHT:
		x = pos.x - m.x
	}

	y: f32
	switch align_v {
	case .TOP:
		y = pos.y
	case .MIDDLE:
		y = pos.y - m.y / 2
	case .BOTTOM:
		y = pos.y - m.y
	}

	draw_pos := rl.Vector2{x + offset.x, y + offset.y}
	draw_text(text, size, draw_pos, color)
	return rl.Rectangle{draw_pos.x, draw_pos.y, m.x, m.y}
}
