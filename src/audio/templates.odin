package audio

import rl "deps:raylib"

SoundTemplate :: struct {
    sound:       rl.Sound,
    volume:      f32,  // базовая громкость этого конкретного звука
    pitch:       f32,
    save_volume: f32,  // последняя применённая (для пересчёта при смене master)
}

MusicTemplate :: struct {
    music:       rl.Music,
    volume:      f32,
    pitch:       f32,
    save_volume: f32,
}
