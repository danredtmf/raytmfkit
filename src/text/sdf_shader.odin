package text

import "core:c"
import "raytmfkit:core"
import rl "deps:raylib"

@(private)
DEFAULT_SDF_FS :: #load("shaders/sdf.fshader", cstring)

sdf_shader: rl.Shader

@(private)
sdf_threshold := f32(0.5)
@(private)
sdf_sharpness := f32(1.0)

// Если hot_reload_path != "" — регистрирует шейдер для F5-перезагрузки.
// Путь относителен cwd (обычно корень проекта при запуске примера из IDE).
load_default_sdf_shader :: proc(
    hot_reload_path: string = "",
) -> rl.Shader {
    sdf_shader = rl.LoadShaderFromMemory(nil, DEFAULT_SDF_FS)
    sdf_shader_set(sdf_threshold, sdf_sharpness)

    if hot_reload_path != "" {
        core.register_reloadable_shader(
            name         = "sdf",
            target       = &sdf_shader,
            fs_path      = hot_reload_path,
            after_reload = reapply_sdf_values,
        )
    }
    return sdf_shader
}

sdf_shader_set :: proc(threshold, sharpness: f32) {
    sdf_threshold = threshold
    sdf_sharpness = sharpness
    t_loc := rl.GetShaderLocation(sdf_shader, "uThreshold")
    s_loc := rl.GetShaderLocation(sdf_shader, "uSharpness")
    if t_loc >= 0 { core.set_shader_f32(sdf_shader, t_loc, threshold) }
    if s_loc >= 0 { core.set_shader_f32(sdf_shader, s_loc, sharpness) }
}

@(private)
reapply_sdf_values :: proc(_: rawptr) {
    sdf_shader_set(sdf_threshold, sdf_sharpness)
}
