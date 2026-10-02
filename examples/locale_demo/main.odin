package main

import "raytmfkit:debug"
import "raytmfkit:input"
import "core:fmt"
import "core:strings"
import rl "deps:raylib"
import "raytmfkit:core"
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
			text.draw_text_aligned(
				app_lang_text,
				32,
				{core.ctx.screen_half.x, core.ctx.screen_vec2.y - core.get_scale(32 * 3)},
				rl.WHITE,
			)

			ui.draw_button(
				text.font_of(fonts),
				"English",
				32,
				{core.ctx.screen_half.x - core.get_scale(32*2), core.ctx.screen_vec2.y - core.get_scale(32)},
				.BOTTOM_CENTER,
				&btn_en,
			)
			ui.draw_button(
				text.font_of(fonts),
				"Русский",
				32,
				{core.ctx.screen_half.x + core.get_scale(32*2), core.ctx.screen_vec2.y - core.get_scale(32)},
				.BOTTOM_CENTER,
				&btn_ru,
			)
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
