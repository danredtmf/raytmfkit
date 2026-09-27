package assets

import rl "deps:raylib"

load_wave :: proc(data: []u8, ext: cstring = ".ogg") -> rl.Wave {
    return rl.LoadWaveFromMemory(ext, raw_data(data), i32(len(data)))
}

// LoadSoundFromWave copies sample data, so the wave is freed immediately.
load_sound :: proc(data: []u8, ext: cstring = ".ogg") -> rl.Sound {
    wave := load_wave(data, ext)
    defer rl.UnloadWave(wave)
    return rl.LoadSoundFromWave(wave)
}

load_music :: proc(data: []u8, ext: cstring = ".ogg") -> rl.Music {
    return rl.LoadMusicStreamFromMemory(ext, raw_data(data), i32(len(data)))
}