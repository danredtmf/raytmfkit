package main

import "core:fmt"
import rl "deps:raylib"
import "raytmfkit:core"
import "raytmfkit:debug"
import "raytmfkit:input"
import "raytmfkit:text"
import "raytmfkit:ui"

// Layout Demo — самодостаточная площадка для ui/layout.odin.
//
// Три панели:
//   1. cross_align (слева-сверху) — три vbox'а START/CENTER/END
//      с одинаковым cross_size. Кнопки НЕ uniform — их ширины разные,
//      чтобы было видно, что cross_align сдвигает слот, а не кнопку.
//   2. Диалог (центр) — vbox + hbox + button_sizes_uniform +
//      min_size + layout_next_center(.CENTER). Полный паттерн ряда кнопок.
//   3. anchored_stack (справа-снизу) — кнопки, прижатые к BOTTOM_RIGHT,
//      одним вызовом measure + resolve_anchor + vbox.
//
// Клавиши:
//   F  — fullscreen
//   D  — toggle debug-обводок
//   F5 — hot-reload шейдеров

main :: proc() {
	core.ctx.default_size = {1280, 720}
	rl.InitWindow(core.ctx.default_size.x, core.ctx.default_size.y, "RayTMFKit - Layout Demo")
	defer rl.CloseWindow()

	core.toggle_fps_limit(true)
	core.set_vsync(true)

	data_font := #load("../_assets/fonts/OpenSans-Regular.ttf")
	text.sdf_shader = text.load_default_sdf_shader("../_assets/shaders/sdf.fshader")
	cps := text.get_default_codepoints()
	fonts := text.load_font_pair(data_font, 128, cps[:])
	fonts.active = .SDF
	defer text.unload_font_pair(&fonts)
	text.set_font(fonts)

	debug.enabled = true
	show_debug := true

	picked: cstring = "none"

	for !rl.WindowShouldClose() {
		core.begin_frame()
		debug.begin_frame()

		debug.try_hot_reload_shaders()

		if rl.IsKeyPressed(.F) { core.toggle_fullscreen() }
		if rl.IsKeyPressed(.D) { show_debug = !show_debug }

		rl.BeginDrawing()
		{
			rl.ClearBackground(rl.BLACK)

			draw_cross_align_panel(text.font_of(fonts), show_debug)
			draw_dialog_panel(text.font_of(fonts), &picked, show_debug)
			draw_anchored_panel(text.font_of(fonts), show_debug)

			text.draw_text_aligned(
				"D — debug · F — fullscreen · F5 — reload shaders",
				18,
				{core.ctx.screen_half.x, core.ctx.screen_vec2.y - core.get_scale(16)},
				rl.GRAY,
			)

			debug.add("picked", string(picked))
			debug.addf("scale", "%.3f", core.get_scale_value())

			debug.draw_overlay()
		}
		rl.EndDrawing()

		core.end_frame()
	}
}

// -----------------------------------------------------------------------------
// Панель 1: cross_align
//
// Три колонки фиксированной ширины (cross_size = col_w), в каждой
// vbox с gap и своим cross_align. Кнопки имеют собственные ширины —
// без min_size — поэтому видно: слот смещается по cross-оси.
// -----------------------------------------------------------------------------

draw_cross_align_panel :: proc(font: rl.Font, show_debug: bool) {
	items     := []cstring{"Short", "Medium item", "A very long label"}
	gap       := core.get_scale(6)
	col_w     := core.get_scale(200)
	col_gap   := core.get_scale(16)
	font_size := f32(20)

	origin := rl.Vector2{core.get_scale(32) * 10, core.get_scale(32) * 3.25}

	text.draw_text_ex(font, "cross_align", core.get_scale(22), origin, rl.GRAY)
	origin.y += core.get_scale(34)

	aligns := []ui.CrossAlign{ .START, .CENTER, .END }
	names  := []cstring{ "START", "CENTER", "END" }

	for align, ai in aligns {
		col_x := origin.x + f32(ai) * (col_w + col_gap)

		text.draw_text_ex(font, names[ai], core.get_scale(16), {col_x, origin.y}, rl.GRAY)

		top := origin.y + core.get_scale(22)

		lay := ui.vbox({col_x, top}, gap = gap)
		lay.cross_align = align
		lay.cross_size  = col_w

		rect: rl.Rectangle
		for item in items {
			sz := ui.button_size(font, item, font_size)
			p  := ui.layout_next(&lay, sz)
			ui.draw_button(font, item, font_size, p, .TOP_LEFT, &rect)
			if show_debug {
				rl.DrawRectangleLinesEx(rect, 1, {60, 120, 60, 120})
			}
		}

		if show_debug {
			sz    := ui.layout_size(lay)
			panel := rl.Rectangle{col_x, top, sz.x, sz.y}
			rl.DrawRectangleLinesEx(panel, 1, rl.DARKGRAY)
		}
	}
}

// -----------------------------------------------------------------------------
// Панель 2: диалог
//
// Классический паттерн:
//   vbox (CENTER, cross_size = block_total.x)
//     ├── title (текст)
//     ├── subtitle (текст)
//     └── hbox (CENTER)
//           ├── button_sizes_uniform → одинаковая ширина
//           ├── layout_next_center + .CENTER
//           └── min_size = btn_sizes[i]
//
// Все три части паттерна обязательны — без любой из них кнопки разъедутся.
// -----------------------------------------------------------------------------

draw_dialog_panel :: proc(font: rl.Font, picked: ^cstring, show_debug: bool) {
	labels   := []cstring{"OK", "Cancel", "Apply"}
	btn_size := f32(24)
	btn_gap  := core.get_scale(12)

	btn_sizes := ui.button_sizes_uniform(font, labels, btn_size)
	btn_total := ui.measure_stack(btn_sizes, btn_gap, .HORIZONTAL)

	title    := cstring("Layout Demo")
	subtitle := cstring("vbox + hbox + uniform buttons + min_size")
	title_sz := text.measure_text_current(title,    core.get_scale(36))
	sub_sz   := text.measure_text_current(subtitle, core.get_scale(18))

	block_sizes := [3]rl.Vector2{title_sz, sub_sz, btn_total}
	block_gap   := core.get_scale(16)
	block_total := ui.measure_stack(block_sizes[:], block_gap, .VERTICAL)

	origin := ui.resolve_anchor(core.ctx.screen_half, block_total, .CENTER)
	outer  := ui.vbox(origin, gap = block_gap)
	outer.cross_align = .CENTER
	outer.cross_size  = block_total.x

	title_slot := ui.layout_next(&outer, title_sz)
	sub_slot   := ui.layout_next(&outer, sub_sz)
	btn_slot   := ui.layout_next(&outer, btn_total)

	inner := ui.hbox(btn_slot, gap = btn_gap)
	inner.cross_align = .CENTER

	rects: [3]rl.Rectangle
	for label, i in labels {
		p := ui.layout_next_center(&inner, btn_sizes[i])
		ui.draw_button(font, label, btn_size, p, .CENTER, &rects[i], min_size = btn_sizes[i])
	}

	text.draw_text_ex(font, title,    core.get_scale(36), title_slot, rl.WHITE)
	text.draw_text_ex(font, subtitle, core.get_scale(18), sub_slot,   rl.GRAY)

	// Строка «Picked: …» — ниже блока.
	picked_msg := rl.TextFormat("Picked: %s", string(picked^))
	text.draw_text_aligned(
		picked_msg,
		18,
		{core.ctx.screen_half.x, origin.y + block_total.y + core.get_scale(30)},
		rl.LIME,
	)

	if show_debug {
		block_rect := rl.Rectangle{origin.x, origin.y, block_total.x, block_total.y}
		rl.DrawRectangleLinesEx(block_rect, 1, {0, 200, 0, 120})
		for r in rects {
			rl.DrawRectangleLinesEx(r, 1, {0, 200, 0, 80})
		}
	}

	// Input. Всё уже посчитано в этом кадре — можно проверить сразу.
	if input.pressed_on_rect(rects[0]) { picked^ = "OK" }
	if input.pressed_on_rect(rects[1]) { picked^ = "Cancel" }
	if input.pressed_on_rect(rects[2]) { picked^ = "Apply" }
}

// -----------------------------------------------------------------------------
// Панель 3: anchored_stack
//
// Всё в одну строку: measure_stack + resolve_anchor + vbox.
// Используем uniform-размеры + min_size, чтобы кнопки были одинаковыми.
// -----------------------------------------------------------------------------

draw_anchored_panel :: proc(font: rl.Font, show_debug: bool) {
	labels   := []cstring{"Save", "Load", "Exit"}
	btn_size := f32(22)
	gap      := core.get_scale(8)

	sizes := ui.button_sizes_uniform(font, labels, btn_size)

	anchor := rl.Vector2{
		core.ctx.screen_vec2.x - core.get_scale(32),
		core.ctx.screen_vec2.y - core.get_scale(32),
	}
	lay := ui.anchored_stack(sizes, anchor, .BOTTOM_RIGHT, gap, .VERTICAL)

	rect: rl.Rectangle
	for label, i in labels {
		p := ui.layout_next(&lay, sizes[i])
		ui.draw_button(font, label, btn_size, p, .TOP_LEFT, &rect, min_size = sizes[i])
	}

	if show_debug {
		sz    := ui.layout_size(lay)
		panel := rl.Rectangle{lay.pos.x, lay.pos.y, sz.x, sz.y}
		rl.DrawRectangleLinesEx(panel, 1, {80, 80, 200, 120})
	}
}
