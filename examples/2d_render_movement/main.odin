package main

import "game"
import rl "deps:raylib"
import "raytmfkit:core"
import "raytmfkit:postfx"
import "raytmfkit:transitions"
import "raytmfkit:debug"

// 2D Square Movement, WASD keys
// Using core, postfx, transitions, debug
// 720p, simple fade transition on R key
// debug on F1 key, toggle fullscreen on F2 key

main :: proc() {
	core.ctx.default_size = {1280, 720}
	core.ctx.virtual_size = {1920, 1080}

	rl.InitWindow(core.ctx.default_size.x, core.ctx.default_size.y, "RayTMFKit - Simple Window")
	// rl.SetWindowState({.WINDOW_RESIZABLE})
	defer rl.CloseWindow()

	core.toggle_fps_limit(true)
	core.set_vsync(true)
	debug.enabled = true

	chain := postfx.Chain{}
	postfx.init_chain(&chain, core.ctx.default_size, 1)
	defer postfx.deinit_chain(&chain)

	clear_color := rl.DARKGRAY

	g := game.create()
	g.player.position = {100, 100}
	g.player.size = {20, 20}
	g.player.speed = 300

	g.trans = transitions.Transition{}
	transitions.init(&g.trans)

	debug.init()
	defer debug.shutdown()

	for !rl.WindowShouldClose() {
		core.begin_frame()
		debug.begin_frame()

		game.update(&g, core.ctx.delta)
		transitions.update(&g.trans, core.ctx.delta)

		debug.addf("PlayerPos", "(%d, %d)", i32(g.player.position.x), i32(g.player.position.y))

		rl.BeginDrawing()
		{
			postfx.begin_target(chain.scene)
			{
				rl.ClearBackground(clear_color)
				game.draw_world(g)
			}
			postfx.end_target()

			postfx.ensure_chain_size(&chain)
			postfx.run_chain(&chain)

			postfx.draw_final(&chain)
			game.draw_ui(g)
			transitions.draw_fullscreen(g.trans)
			debug.draw_overlay()
		}
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}
}
