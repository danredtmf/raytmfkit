package main

import rl "deps:raylib"
import "core:fmt"
import "raytmfkit:core"
import "raytmfkit:text"
import "raytmfkit:ui"

main :: proc() {
	core.ctx.default_size = {1280, 720}
	rl.InitWindow(
		core.ctx.default_size.x, core.ctx.default_size.y,
		"RayTMFKit - Menu Demo",
	)
	defer rl.CloseWindow()

	core.toggle_fps_limit(true)
	core.set_vsync(true)

	data_font := #load("../_assets/fonts/Monocraft.ttf")
	text.sdf_shader = text.load_default_sdf_shader()
	cps := text.get_default_codepoints()
	fonts := text.load_font_pair(data_font, 128, cps[:])
	fonts.active = .SDF
	defer text.unload_font_pair(&fonts)
	text.set_font(fonts)

	items := []ui.MenuItem{
		{label = "Новая игра / New Game",      enabled = true},
		{label = "Продолжить / Continue",      enabled = true},
		{label = "Настройки / Settings",       enabled = true},
		{label = "Загрузить / Load (disabled)", enabled = false},
		{label = "Выход / Quit",                enabled = true},
	}

	menu: ui.Menu
	ui.menu_init(&menu, items)
	defer ui.menu_deinit(&menu)

	picked       := -1
	picked_timer := f32(0)

	for !rl.WindowShouldClose() {
		core.begin_frame()

		if rl.IsKeyPressed(.F) { core.toggle_fullscreen() }

		if idx := ui.menu_update(
			&menu, text.font_of(fonts),
			core.ctx.screen_half, .CENTER,
		); idx >= 0 {
			picked       = idx
			picked_timer = 1.5
			fmt.printf("Menu picked: %d (%s)\n",
				idx, string(items[idx].label))
		}

		if picked_timer > 0 { picked_timer -= core.ctx.delta }

		rl.BeginDrawing()
		{
			rl.ClearBackground(rl.BLACK)

			ui.menu_draw(menu, text.font_of(fonts))

			if picked >= 0 && picked_timer > 0 {
				msg := rl.TextFormat("Выбрано / Picked: %d", picked)
				text.draw_text_aligned(
					msg, 24,
					{core.ctx.screen_half.x, core.get_scale(40)},
					rl.LIME,
				)
			}

			text.draw_text_aligned(
				"↑/↓ — навигация, Enter — выбор, F — fullscreen",
				20,
				{core.ctx.screen_half.x,
				 core.ctx.screen_vec2.y - core.get_scale(30)},
				rl.GRAY,
			)
		}
		rl.EndDrawing()

		core.end_frame()
	}
}
