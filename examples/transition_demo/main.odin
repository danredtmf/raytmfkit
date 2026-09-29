package main

import "raytmfkit:debug"
import "raytmfkit:postfx"
import rl "deps:raylib"
import "raytmfkit:core"
import "raytmfkit:text"
import "raytmfkit:transitions"

Scene :: struct {
	clear_color: rl.Color,
}

scenes: [3]Scene
current_scene_idx: i32

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

	scenes = {
		Scene{clear_color = rl.BLACK},
		Scene{clear_color = rl.DARKGRAY},
		Scene{clear_color = rl.GRAY},
	}

	trans := transitions.Transition{}
	transitions.init(&trans)

	for !rl.WindowShouldClose() {
		core.begin_frame()

		transitions.update(&trans, core.ctx.delta)

		if rl.IsKeyPressed(.F) {core.toggle_fullscreen()}
		if rl.IsKeyPressed(.R) && !transitions.is_active(trans) {
			transitions.begin(&trans, proc() {current_scene_idx += 1}, rl.BLACK, rl.BLANK, f32(0.5), f32(0.5), f32(0.5))
		}
		if current_scene_idx >= len(scenes) {current_scene_idx = 0}

		rl.BeginDrawing()
		{
			rl.ClearBackground(scenes[current_scene_idx].clear_color)

			text.draw_text_aligned(
				"Нажми R / Press R",
				core.get_scale(64),
				core.ctx.screen_half,
				rl.SKYBLUE,
				.CENTER,
				.MIDDLE,
				{0, -core.get_scale(32)},
			)
			text.draw_text_aligned(
				rl.TextFormat("Сцена / Scene: %d", current_scene_idx + 1),
				core.get_scale(64),
				core.ctx.screen_half,
				rl.SKYBLUE,
				.CENTER,
				.MIDDLE,
				{0, core.get_scale(32)},
			)

			transitions.draw_fullscreen(trans)
		}
		rl.EndDrawing()
		free_all(context.temp_allocator)
	}
}
