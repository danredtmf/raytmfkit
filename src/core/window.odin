package core

import "core:c"
import rl "deps:raylib"

windowed_position: [2]i32

is_fullscreen :: proc() -> bool {
	return rl.IsWindowState({.FULLSCREEN_MODE}) || rl.IsWindowState({.WINDOW_UNDECORATED})
}

toggle_fullscreen :: proc() {
	if !ctx.fullscreen {
		when ODIN_OS == .Windows {
			rl.SetWindowState({.WINDOW_UNDECORATED})

			monitor := rl.GetCurrentMonitor()
			current_position := rl.GetWindowPosition()
			windowed_position = {i32(current_position.x), i32(current_position.y)}
			rl.SetWindowPosition(0, 0)
			rl.SetWindowSize(rl.GetMonitorWidth(monitor), rl.GetMonitorHeight(monitor))

		} else when ODIN_OS == .Linux {
			monitor := rl.GetCurrentMonitor()
			current_position := rl.GetWindowPosition()
			windowed_position = {i32(current_position.x), i32(current_position.y)}
			rl.SetWindowSize(rl.GetMonitorWidth(monitor), rl.GetMonitorHeight(monitor))

			rl.SetWindowState({.FULLSCREEN_MODE})
		}
	} else {
		when ODIN_OS == .Windows {
			rl.ClearWindowState({.WINDOW_UNDECORATED})

			rl.SetWindowPosition(windowed_position.x, windowed_position.y)
			rl.SetWindowSize(ctx.default_size.x, ctx.default_size.y)
		} else when ODIN_OS == .Linux {
			rl.ClearWindowState({.FULLSCREEN_MODE})

			rl.SetWindowPosition(windowed_position.x, windowed_position.y)
			rl.SetWindowSize(ctx.default_size.x, ctx.default_size.y)
		}
	}
}

set_vsync :: proc(enabled: bool) {
	if enabled {rl.SetWindowState({.VSYNC_HINT})} else {rl.ClearWindowState({.VSYNC_HINT})}
}

toggle_fps_limit :: proc(enabled: bool) {
	if !enabled {
		rl.SetTargetFPS(0)
	} else {
		rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))
	}
}

render_resolution :: proc() -> [2]i32 {
	return {rl.GetRenderWidth(), rl.GetRenderHeight()}
}
