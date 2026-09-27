package assets

import rl "deps:raylib"

load_image :: proc(data: []u8, ext: cstring = ".png") -> rl.Image {
    return rl.LoadImageFromMemory(ext, raw_data(data), i32(len(data)))
}

// LoadTextureFromImage copies pixel data to GPU,
// so the CPU-side image is unloaded immediately.
load_texture :: proc(data: []u8, ext: cstring = ".png") -> rl.Texture2D {
    img := load_image(data, ext)
    defer rl.UnloadImage(img)
    return rl.LoadTextureFromImage(img)
}
