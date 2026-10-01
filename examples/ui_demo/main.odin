package main

import rl "deps:raylib"
import "raytmfkit:core"
import "raytmfkit:input"
import "raytmfkit:text"
import "raytmfkit:ui"

main :: proc() {
	core.ctx.default_size = {1280, 720}
	rl.InitWindow(core.ctx.default_size.x, core.ctx.default_size.y, "RayTMFKit - Simple Window")
	defer rl.CloseWindow()

	core.toggle_fps_limit(true)
	core.set_vsync(true)

	data_font := #load("../_assets/fonts/OpenSans-Regular.ttf")
	text.sdf_shader = text.load_default_sdf_shader()
	cps := text.get_default_codepoints()
	fonts := text.load_font_pair(data_font, 128, cps[:])
	fonts.active = .SDF
	defer text.unload_font_pair(&fonts)
	text.set_font(fonts)

	btn_apply := rl.Rectangle{}
	btn_apply_1 := cstring("Кнопка / Button")
	btn_apply_2 := cstring("Наводимся / Hovering")
	btn_apply_3 := cstring("Удерживаем / Pressing")
	btn_apply_4 := cstring("Отпустили / Released")
	btn_apply_text := &btn_apply_1

	btn_released_timer := f32(0)

	slider := ui.Slider {
		min = 1,
		max = 10,
	}
	dropdown := ui.Dropdown {
		items = {"First", "Абракадабра", "Oh My Goodness!"},
	}
	sv := ui.ScrollView {
		speed     = 40,
		bar_width = 12,
	}
	items: []string
	items = {
		"Первый элемент / First item",
		"Второй элемент / Second item",
		"Третий элемент / Third item",
		"Четвёртый элемент / Fourth item",
		"Пятый элемент / Fifth item",
		"Шестой элемент / Sixth item",
		"Седьмой элемент / Seventh item",
		"Восьмой элемент / Eighth item",
		"Девятый элемент / Ninth item",
		"Десятый элемент / Tenth item",
	}

	for !rl.WindowShouldClose() {
		core.begin_frame()

		if rl.IsKeyPressed(.F) {
			core.toggle_fullscreen()
		}

		if btn_released_timer >=0 {btn_released_timer -= core.ctx.delta}
		if input.hover_rect(btn_apply) {
			if btn_released_timer <= 0 {btn_apply_text = &btn_apply_2}
		} else {
			if btn_released_timer <= 0 {btn_apply_text = &btn_apply_1}
		}
		if input.down_on_rect(btn_apply) {
			btn_apply_text = &btn_apply_3
		}
		if input.released_on_rect(btn_apply) {
			btn_apply_text = &btn_apply_4
			btn_released_timer = 1
		}

		sv.view_rect = {core.get_scale(50), core.get_scale(50), core.ctx.screen_half.x, core.ctx.screen_half.y}
		sv.content_h = f32(len(items)) * core.get_scale(40)
		ui.update_scrollview(&sv)

		ui.update_dropdown(
			&dropdown,
			text.font_of(fonts),
			32,
			{core.ctx.screen_half.x + core.get_scale(64), core.get_scale(50)},
			.TOP_LEFT
		)

		rl.BeginDrawing()
		{
			rl.ClearBackground(rl.BLACK)
			ui.draw_button(
				text.font_of(fonts),
				btn_apply_text^,
				32,
				core.ctx.screen_half + {0, core.ctx.screen_half.y - core.get_scale(32)},
				.CENTER,
				&btn_apply,
			)
			ui.update_slider(
				&slider,
				"Слайдер / Slider",
				text.font_of(fonts),
				24,
				{core.ctx.screen_half.x, btn_apply.y - core.get_scale(32) * 2.5},
			)
			ui.draw_dropdown(dropdown, text.font_of(fonts), 32)
			rl.BeginScissorMode(
				i32(sv.view_rect.x),
				i32(sv.view_rect.y),
				i32(sv.view_rect.width),
				i32(sv.view_rect.height),
			)
			{
				// inner := sv.view_rect
				// inner.y -= sv.scroll
				// inner.height = sv.content_h

				item_h := core.get_scale(40)
				for item, i in items {
					y := sv.view_rect.y - sv.scroll + f32(i) * item_h
					text.draw_text_ex(
						text.font_of(fonts),
						core.cstring_temp(item),
						core.get_scale(32), // ← scaled
						{sv.view_rect.x, y},
						rl.WHITE,
					)
				}
			}
			rl.EndScissorMode()
			ui.draw_scrollview_bar(sv)
		}
		rl.EndDrawing()
		free_all(context.temp_allocator)
	}
}
