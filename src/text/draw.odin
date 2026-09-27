package text

import rl "deps:raylib"
import kcore "raytmfkit:core"

current_font: rl.Font
current_is_sdf: bool

set_font :: proc(fp: FontPair) {
	current_font = font_of(fp)
	current_is_sdf = is_sdf(fp)
}

measure_text :: proc(font: rl.Font, text: cstring, size: f32, spacing: f32 = 1) -> rl.Vector2 {
	return rl.MeasureTextEx(font, text, size, spacing)
}

measure_text_current :: proc(text: cstring, size: f32, spacing: f32 = 1) -> rl.Vector2 {
	return rl.MeasureTextEx(current_font, text, size, spacing)
}

draw_text_ex :: proc(font: rl.Font, text: cstring, size: f32, pos: rl.Vector2, color: rl.Color) {
	rl.DrawTextEx(font, text, pos, size, 1, color)
}

draw_text_ex_sdf :: proc(
	font: rl.Font,
	text: cstring,
	size: f32,
	pos: rl.Vector2,
	color: rl.Color,
) {
	rl.BeginShaderMode(sdf_shader)
	rl.DrawTextEx(font, text, pos, size, 1, color)
	rl.EndShaderMode()
}

// Высокоуровневый: использует current font
draw_text :: proc(text: cstring, size: f32, pos: rl.Vector2, color: rl.Color) {
	if current_is_sdf {
		draw_text_ex_sdf(current_font, text, size, pos, color)
	} else {
		draw_text_ex(current_font, text, size, pos, color)
	}
}

// Утилита: масштабировать размер под screen, потом рисовать
draw_text_scaled :: proc(text: cstring, base_size: f32, pos: rl.Vector2, color: rl.Color) {
	draw_text(text, kcore.get_scale(base_size), pos, color)
}
