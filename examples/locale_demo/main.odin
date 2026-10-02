package main

import "core:fmt"
import "core:strings"
import rl "deps:raylib"
import "raytmfkit:core"
import "raytmfkit:debug"
import "raytmfkit:input"
import "raytmfkit:locale"
import "raytmfkit:text"
import "raytmfkit:ui"

PACKAGE_NAME :: "RayTMFKit"

my_locale: locale.Localization
my_lang: locale.Language

app_title, app_test_text, app_lang_text: cstring

main :: proc() {
	core.ctx.default_size = {1280, 720}
	rl.InitWindow(core.ctx.default_size.x, core.ctx.default_size.y, PACKAGE_NAME)
	defer rl.CloseWindow()

	core.toggle_fps_limit(true)
	core.set_vsync(true)
	// core.sync_screen()

	data_locale := #load("../_assets/locales/locale_demo.json")
	my_locale = locale.load_from_bytes(data_locale)
	if my_locale == nil {return}
	defer delete(my_locale)

	my_lang = locale.detect()

	defer {
		delete(app_title)
		delete(app_test_text)
		delete(app_lang_text)
	}

	data_font := #load("../_assets/fonts/OpenSans-Regular.ttf")
	text.sdf_shader = text.load_default_sdf_shader("../_assets/shaders/sdf.fshader")
	cps := text.get_default_codepoints()
	fonts := text.load_font_pair(data_font, 128, cps[:])
	fonts.active = .SDF
	defer text.unload_font_pair(&fonts)
	text.set_font(fonts)

	btn_en_label := cstring("English")
	btn_ru_label := cstring("Русский")

	btn_en, btn_ru := rl.Rectangle{}, rl.Rectangle{}

	update_locales_text()

	debug.enabled = true

	for !rl.WindowShouldClose() {
		core.begin_frame()
		debug.begin_frame()

		debug.try_hot_reload_shaders()

		if rl.IsKeyPressed(.F) {
			core.toggle_fullscreen()
		}

		// --- Размеры кнопок: одинаковой ширины, единообразно ---
		btn_sizes := ui.button_sizes_uniform(
			text.font_of(fonts),
			[]cstring{btn_en_label, btn_ru_label},
			32,
		)
		btn_en_size := btn_sizes[0]
		btn_ru_size := btn_sizes[1]

		btn_gap := core.get_scale(16)
		btn_total := ui.measure_stack(btn_sizes[:], btn_gap, .HORIZONTAL)

		lang_size := text.measure_text_current(app_lang_text, core.get_scale(32))

		block_sizes := [2]rl.Vector2{lang_size, btn_total}
		block_gap := core.get_scale(5)
		block_total := ui.measure_stack(block_sizes[:], block_gap, .VERTICAL)

		block_origin := ui.resolve_anchor(
			{core.ctx.screen_half.x, core.ctx.screen_vec2.y - core.get_scale(32)},
			block_total,
			.BOTTOM_CENTER,
		)
		outer := ui.vbox(block_origin, gap = block_gap)
		outer.cross_align = .CENTER
		outer.cross_size  = block_total.x

		lang_slot := ui.layout_next(&outer, lang_size)
		btn_slot := ui.layout_next(&outer, btn_total)

		inner := ui.hbox(btn_slot, gap = btn_gap)
		inner.cross_align = .CENTER
		p_en := ui.layout_next_center(&inner, btn_en_size)
		p_ru := ui.layout_next_center(&inner, btn_ru_size)

		// --- Диагностика. Убери после того, как разберёмся. ---
		fmt.println("=== layout debug ===")
		fmt.printf("scale          = %v\n", core.get_scale_value())
		fmt.printf("btn_en_size    = %v %v\n", btn_en_size.x, btn_en_size.y)
		fmt.printf("btn_ru_size    = %v %v\n", btn_ru_size.x, btn_ru_size.y)
		// fmt.printf("total          = %v %v\n", total.x, total.y)
		// fmt.printf("origin         = %v %v\n", origin.x, origin.y)
		// fmt.printf("slot_en        = %v %v\n", slot_en.x, slot_en.y)
		// fmt.printf("slot_ru        = %v %v\n", slot_ru.x, slot_ru.y)
		fmt.printf("p_en (center)  = %v %v\n", p_en.x, p_en.y)
		fmt.printf("p_ru (center)  = %v %v\n", p_ru.x, p_ru.y)
		fmt.printf("dx(centers)    = %v\n", p_ru.x - p_en.x)
		fmt.printf(
			"gap expected   = %v\n",
			(p_ru.x - p_en.x) - btn_en_size.x / 2 - btn_ru_size.x / 2,
		)

		// --- Input (btn_en/btn_ru — из прошлого кадра draw) ---
		if input.pressed_on_rect(btn_en) {
			my_lang = .EN
			update_locales_text()
		}
		if input.pressed_on_rect(btn_ru) {
			my_lang = .RU
			update_locales_text()
		}

		rl.BeginDrawing()
		{
			rl.ClearBackground(rl.BLACK)

			text.draw_text_aligned(app_test_text, 64, core.ctx.screen_half, rl.WHITE)
			lang_rect := text.draw_text_aligned(
				app_lang_text,
				32,
				lang_slot + lang_size / 2,
				rl.WHITE,
				.CENTER,
				.MIDDLE,
			)
			rl.DrawRectangleLinesEx(lang_rect, 1, rl.RED)
			rl.DrawLine(i32(core.ctx.screen_half.x), 0, i32(core.ctx.screen_half.x), i32(core.ctx.screen_vec2.y), rl.WHITE)

			ui.draw_button(text.font_of(fonts), btn_en_label, 32, p_en, .CENTER, &btn_en,
               min_size = btn_en_size)
			ui.draw_button(text.font_of(fonts), btn_ru_label, 32, p_ru, .CENTER, &btn_ru,
               min_size = btn_ru_size)
		}
		rl.EndDrawing()

		core.end_frame()
	}
}

update_locales_text :: proc() {
	delete(app_title)
	delete(app_test_text)
	delete(app_lang_text)

	app_title = core.cstring_alloc(
		strings.concatenate({PACKAGE_NAME, " - ", locale.get(my_locale, "APP_NAME", my_lang)}),
	)
	app_test_text = core.cstring_alloc(locale.get(my_locale, "TEST_TEXT", my_lang))
	app_lang_text = core.cstring_alloc(locale.get(my_locale, "LANG_TEXT", my_lang))

	rl.SetWindowTitle(app_title)
}
