package game

import "raytmfkit:core"
import "raytmfkit:debug"
import "raytmfkit:transitions"
import rl "deps:raylib"

Game :: struct {
	player: PlayerCube,
	trans: transitions.Transition,
}

PlayerCube :: struct {
	position: [2]f32,
	size:     [2]f32,
	speed:    f32,
}

create :: proc() -> Game {return Game{}}

update :: proc(g: ^Game, dt: f32) {
	if rl.IsKeyPressed(.F1) {debug.enabled = !debug.enabled}
	if rl.IsKeyPressed(.F2) {core.toggle_fullscreen()}
	if rl.IsKeyPressed(.R) {
		if !transitions.is_active(g.trans) {
			transitions.begin(&g.trans, nil)
		}
	}

	if rl.IsKeyDown(.A) {g.player.position.x -= g.player.speed * dt}
	if rl.IsKeyDown(.D) {g.player.position.x += g.player.speed * dt}
	if rl.IsKeyDown(.W) {g.player.position.y -= g.player.speed * dt}
	if rl.IsKeyDown(.S) {g.player.position.y += g.player.speed * dt}
}

draw_world :: proc(g: Game) {
	rl.DrawRectangleRec(
		{g.player.position.x, g.player.position.y, g.player.size.x, g.player.size.y},
		rl.WHITE,
	)
}

draw_ui :: proc(g: Game) {

}
