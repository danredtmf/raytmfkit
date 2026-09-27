package main

import rl "deps:raylib"
import "raytmfkit:core"

main :: proc() {
	core.ctx.default_size = {1280, 720}
	core.ctx.virtual_size = {1920, 1080}
	rl.InitWindow(core.ctx.default_size.x, core.ctx.default_size.y, "RayTMFKit - Simple Window")
	defer rl.CloseWindow()

	core.toggle_fps_limit(true)
	core.set_vsync(true)

	for !rl.WindowShouldClose() {
		core.begin_frame()

		rl.BeginDrawing()
		{
			rl.ClearBackground(rl.BLACK)
		}
		rl.EndDrawing()
		free_all(context.temp_allocator)
	}
}
