package text

import "core:c"
import rl "deps:raylib"

@(private)
DEFAULT_SDF_FS :: #load("shaders/sdf.fshader", cstring)

sdf_shader: rl.Shader

load_default_sdf_shader :: proc() -> rl.Shader {
	sdf_shader = rl.LoadShaderFromMemory(nil, DEFAULT_SDF_FS)
	sdf_shader_set(0.5, 1.0)
	return sdf_shader
}

sdf_shader_set :: proc(threshold, sharpness: f32) {
	t_loc := rl.GetShaderLocation(sdf_shader, "uThreshold")
	s_loc := rl.GetShaderLocation(sdf_shader, "uSharpness")

	threshold_local := threshold
    sharpness_local := sharpness

	if t_loc >=
	   0 {set_shader_f32(sdf_shader, t_loc, threshold_local)}
	if s_loc >=
	   0 {set_shader_f32(sdf_shader, s_loc, sharpness_local)}
}

@(private)
set_shader_f32 :: proc(shader: rl.Shader, loc: c.int, value: f32) {
    v := value
    rl.SetShaderValue(shader, rl.ShaderLocationIndex(loc), &v, .FLOAT)
}
