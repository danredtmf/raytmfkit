package core

import "core:c"
import rl "deps:raylib"

set_shader_f32 :: proc(shader: rl.Shader, loc: c.int, value: f32) {
    v := value
    rl.SetShaderValue(shader, rl.ShaderLocationIndex(loc), &v, .FLOAT)
}

set_shader_i32 :: proc(shader: rl.Shader, loc: c.int, value: i32) {
    v := value
    rl.SetShaderValue(shader, rl.ShaderLocationIndex(loc), &v, .INT)
}

set_shader_vec2 :: proc(shader: rl.Shader, loc: c.int, value: rl.Vector2) {
    v := value
    rl.SetShaderValue(shader, rl.ShaderLocationIndex(loc), &v, .VEC2)
}

set_shader_vec3 :: proc(shader: rl.Shader, loc: c.int, value: rl.Vector3) {
    v := value
    rl.SetShaderValue(shader, rl.ShaderLocationIndex(loc), &v, .VEC3)
}

set_shader_vec4 :: proc(shader: rl.Shader, loc: c.int, value: rl.Vector4) {
    v := value
    rl.SetShaderValue(shader, rl.ShaderLocationIndex(loc), &v, .VEC4)
}

set_shader_color :: proc(shader: rl.Shader, loc: c.int, color: rl.Color) {
    v := rl.Vector4{
        f32(color.r) / 255,
        f32(color.g) / 255,
        f32(color.b) / 255,
        f32(color.a) / 255,
    }
    rl.SetShaderValue(shader, rl.ShaderLocationIndex(loc), &v, .VEC4)
}

set_shader_mat4 :: proc(shader: rl.Shader, loc: c.int, m: rl.Matrix) {
    mat := m
    rl.SetShaderValueMatrix(shader, rl.ShaderLocationIndex(loc), mat)
}
