package assets

import rl "deps:raylib"
import kcore "raytmfkit:core"

// Extra file that must sit next to the main model file
// because the model references it by name (material, texture).
ExtraFile :: struct {
    path: string,
    data: []u8,
}

// Writes the model file and extras to the working directory,
// calls LoadModel, then removes them.
//
// Uses fixed paths, so concurrent calls with the same path collide.
// Intended to be called sequentially during the loading phase.
load_model :: proc(
    path:   string,
    data:   []u8,
    extras: []ExtraFile = nil,
) -> rl.Model {
    if !save_temp_file(path, data) {
        return rl.Model{}
    }
    for f in extras {
        save_temp_file(f.path, f.data)
    }

    defer {
        delete_temp_file(path)
        for f in extras {
            delete_temp_file(f.path)
        }
    }

    cs := kcore.cstring_temp(path)
    if cs == nil {
        return rl.Model{}
    }

    return rl.LoadModel(cs)
}
