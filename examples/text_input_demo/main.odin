package main

import "core:fmt"
import rl "deps:raylib"
import "raytmfkit:core"
import "raytmfkit:text"
import "raytmfkit:ui"

on_name_submit :: proc(ti: ^ui.TextInput) {
	fmt.printf("submit name: %q\n", ui.text_input_value(ti^))
}

main :: proc() {
	core.ctx.default_size = {1280, 720}
	rl.InitWindow(core.ctx.default_size.x, core.ctx.default_size.y, "RayTMFKit - Text Input Demo")
	defer rl.CloseWindow()

	core.toggle_fps_limit(true)
	core.set_vsync(true)
	rl.SetExitKey(nil)

	data_font := #load("../_assets/fonts/OpenSans-Regular.ttf")
	text.sdf_shader = text.load_default_sdf_shader()
	cps := text.get_default_codepoints()
	fonts := text.load_font_pair(data_font, 128, cps[:])
	fonts.active = .SDF
	defer text.unload_font_pair(&fonts)
	text.set_font(fonts)

	name_field: ui.TextInput
	ui.init_text_input(&name_field, "Игрок / Player")
	name_field.placeholder = "Введите имя / Enter name"
	name_field.max_len = 100
	name_field.on_submit = on_name_submit
	defer ui.deinit_text_input(&name_field)

	pass_field: ui.TextInput
	ui.init_text_input(&pass_field, "секрет")
	pass_field.placeholder = "Пароль / Password"
	pass_field.masked = true
	pass_field.max_len = 16
	pass_field.show_reveal = true
	pass_field.show_clear = true
	defer ui.deinit_text_input(&pass_field)

	for !rl.WindowShouldClose() {
		core.begin_frame()

		if rl.IsKeyPressed(.F1) {core.toggle_fullscreen()}

		ui.update_text_input(
			&name_field,
			text.font_of(fonts),
			{core.ctx.screen_half.x, core.ctx.screen_half.y - core.get_scale(60)},
			.CENTER,
			480,
		)
		ui.update_text_input(
			&pass_field,
			text.font_of(fonts),
			{core.ctx.screen_half.x, core.ctx.screen_half.y + core.get_scale(20)},
			.CENTER,
			480,
		)

		rl.BeginDrawing()
		{
			rl.ClearBackground(rl.BLACK)

			ui.draw_text_input(name_field, text.font_of(fonts))
			ui.draw_text_input(pass_field, text.font_of(fonts))

			// Живой вывод значений через text_input_value
			name_str := ui.text_input_value(name_field)
			pass_str := ui.text_input_value(pass_field)

			msg := rl.TextFormat(
				"name=\"%s\" pass=\"%s\"",
				core.cstring_temp(name_str),
				core.cstring_temp(pass_str),
			)
			text.draw_text_aligned(msg, 20, {core.ctx.screen_half.x, core.get_scale(40)}, rl.LIME)

			text.draw_text_aligned(
				"Enter — submit, Esc — blur, mouse drag — выделить, Ctrl+A/C/X/V, клик по глазу — показать",
				18,
				{core.ctx.screen_half.x, core.ctx.screen_vec2.y - core.get_scale(28)},
				rl.GRAY,
			)
		}
		rl.EndDrawing()

		core.end_frame()
	}
}
