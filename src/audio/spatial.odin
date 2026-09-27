package audio

import rl "deps:raylib"

// Вычисляет attenuation (0..1) и pan (0..1, 0.5 = центр)
// для источника относительно камеры-слушателя.
//
// max_dist — расстояние, на котором attenuation падает примерно вдвое.
// beyond ~3*max_dist звук почти не слышен.
spatial :: proc(
    listener:    rl.Camera3D,
    source:      rl.Vector3,
    max_dist:    f32,
) -> (attenuation: f32, pan: f32) {
    dir  := source - listener.position
    dist := rl.Vector3Length(dir)

    attenuation = 1 / (1 + (dist / max_dist))
    attenuation = clamp(attenuation, 0, 1)

    if dist == 0 {
        return attenuation, 0.5
    }

    normalized := dir / dist
    forward    := rl.Vector3Normalize(listener.target - listener.position)
    right      := -rl.Vector3Normalize(rl.Vector3CrossProduct(forward, listener.up))

    // Источники позади слышны тише.
    dot_fwd := rl.Vector3DotProduct(forward, normalized)
    if dot_fwd < 0 {
        attenuation *= (1 + dot_fwd * 0.5)
    }

    pan = 0.5 + 0.5 * rl.Vector3DotProduct(normalized, right)
    pan = clamp(pan, 0, 1)

    return
}

// Обёртка: проигрывает звук с учётом позиции источника.
// Если звук уже играет и multi = false — ничего не делает.
play_sound_at :: proc(
    s:        ^SoundTemplate,
    listener: rl.Camera3D,
    source:   rl.Vector3,
    max_dist: f32,
    multi := false,
) -> bool {
    if s == nil { return false }
    if !multi && rl.IsSoundPlaying(s.sound) {
        return false
    }

    att, pan := spatial(listener, source, max_dist)

    v := s.volume * att * manager.sfx * manager.master
    if manager.muted { v = 0 }

    s.save_volume = v
    rl.SetSoundVolume(s.sound, v)
    rl.SetSoundPitch(s.sound, s.pitch)
    rl.SetSoundPan(s.sound, pan)
    rl.PlaySound(s.sound)
    return true
}
