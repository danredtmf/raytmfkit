package audio

import rl "deps:raylib"

// Проигрывает звук. Если `multi = false` и звук уже играет — не перезапускает.
// Возвращает true, если звук был запущен.
play_sound :: proc(s: ^SoundTemplate, volume := f32(0), multi := false) -> bool {
    if s == nil { return false }

    if !multi && rl.IsSoundPlaying(s.sound) {
        return false
    }

    v := volume
    if v == 0 {
        v = s.volume * manager.sfx * manager.master
    } else {
        v = v * manager.sfx * manager.master
    }
    if manager.muted { v = 0 }

    s.save_volume = v
    rl.SetSoundVolume(s.sound, v)
    rl.SetSoundPitch(s.sound, s.pitch)
    rl.PlaySound(s.sound)
    return true
}

// Останавливает звук, если он играет.
stop_sound :: proc(s: ^SoundTemplate) {
    if s == nil { return }
    if rl.IsSoundPlaying(s.sound) {
        rl.StopSound(s.sound)
    }
}

// Проигрывает музыку с её сохранённой громкостью.
play_music :: proc(m: ^MusicTemplate) {
    if m == nil { return }

    v := m.volume * manager.music * manager.master
    if manager.muted { v = 0 }

    m.save_volume = v
    rl.SetMusicVolume(m.music, v)
    rl.SetMusicPitch(m.music, m.pitch)
    rl.PlayMusicStream(m.music)
}

stop_music :: proc(m: ^MusicTemplate) {
    if m == nil { return }
    rl.StopMusicStream(m.music)
}

// Зови раз в кадр для каждой играющей музыки.
update_music :: proc(m: ^MusicTemplate) {
    if m == nil { return }
    rl.UpdateMusicStream(m.music)
}

// Пересчитывает и обновляет громкость одной музыки — на случай, если master изменился.
refresh_music_volume :: proc(m: ^MusicTemplate) {
    if m == nil { return }
    v := m.volume * manager.music * manager.master
    if manager.muted { v = 0 }
    m.save_volume = v
    rl.SetMusicVolume(m.music, v)
}
