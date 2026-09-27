package audio

import rl "deps:raylib"

Manager :: struct {
    master:      f32,   // 0..1
    music:       f32,
    sfx:         f32,
    muted:       bool,
    initialized: bool,
}

manager: Manager

// Игра регистрирует свою функцию пересчёта громкостей.
// Kit не знает, где лежат карты звуков и музыки — игра решает сама.
@(private)
on_volume_changed: proc() = nil

// Устанавливает колбэк, который вызывается после каждой смены
// master / music / sfx / muted. Передай nil, чтобы отключить.
//
// call_now = true — сразу вызвать колбэк один раз после установки.
// Полезно, если карты звуков уже загружены до регистрации хука.
set_on_volume_changed :: proc(h: proc(), call_now := false) {
    on_volume_changed = h
    if call_now {
        notify_volume_changed()
    }
}

@(private)
notify_volume_changed :: proc() {
    if on_volume_changed != nil {
        on_volume_changed()
    }
}

init :: proc() {
    if manager.initialized { return }

    if !rl.IsAudioDeviceReady() {
        rl.InitAudioDevice()
    }

    manager.master      = 1
    manager.music       = 1
    manager.sfx         = 1
    manager.muted       = false
    manager.initialized = true
}

shutdown :: proc() {
    if !manager.initialized { return }

    rl.CloseAudioDevice()
    manager.initialized = false
}

set_master :: proc(v: f32) {
    manager.master = clamp(v, 0, 1)
    notify_volume_changed()
}

set_music :: proc(v: f32) {
    manager.music = clamp(v, 0, 1)
    notify_volume_changed()
}

set_sfx :: proc(v: f32) {
    manager.sfx = clamp(v, 0, 1)
    notify_volume_changed()
}

set_muted :: proc(m: bool) {
    manager.muted = m
    notify_volume_changed()
}

// Хелперы ниже остаются публичными: игра может звать их вручную,
// например после загрузки карты ассетов или при первом запуске.

recompute_sounds :: proc(sounds: []^SoundTemplate) {
    for s in sounds {
        if s == nil { continue }
        v := (s.volume * manager.sfx) * manager.master
        if manager.muted { v = 0 }
        s.save_volume = v
        rl.SetSoundVolume(s.sound, v)
    }
}

recompute_music :: proc(tracks: []^MusicTemplate) {
    for m in tracks {
        if m == nil { continue }
        v := (m.volume * manager.music) * manager.master
        if manager.muted { v = 0 }
        m.save_volume = v
        rl.SetMusicVolume(m.music, v)
    }
}
