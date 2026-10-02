package debug

import rl "deps:raylib"
import "raytmfkit:core"

// F5 при debug.enabled → core.reload_all_shaders().
// Возвращает true, если попытка была в этом кадре.
// Звать один раз в кадр ПОСЛЕ debug.begin_frame, ДО draw_overlay.
//
// addf пишет метку в буфер меток текущего кадра — она будет видна
// только один кадр (F5 нажат). Этого достаточно для визуального отклика;
// подробности уходят в stdout через log.
try_hot_reload_shaders :: proc() -> bool {
    if !enabled { return false }
    if !rl.IsKeyPressed(.F5) { return false }

    ok, failed := core.reload_all_shaders()
    addf("ShadersReloaded", "%d ok, %d failed", ok, failed)
    return true
}
