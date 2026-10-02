package core

import "core:fmt"
import "core:log"
import rl "deps:raylib"

// Реестр шейдеров, которые можно перезагрузить с диска.
// Регистрация — только в dev-сборке; в релизе пути не передаются,
// и реестр остаётся пустым.
ReloadableShader :: struct {
    name:         string,
    fs_path:      string,
    vs_path:      string,   // "" = дефолтный vertex shader raylib
    target:       ^rl.Shader,        // куда писать новый шейдер
    after_reload: proc(user: rawptr), // опциональный hook после успешной замены
    user:         rawptr,
}

@(private)
reloadable_shaders: [dynamic]ReloadableShader

// Регистрирует шейдер для hot-reload.
//
// target должен жить, пока жив шейдер (обычно — поле в структуре,
// владелец которой живёт весь процесс). Старый шейдер будет
// UnloadShader'нут при успешной перезагрузке.
//
// Если fs_path не существует на момент F5 — перезагрузка не произойдёт,
// старый шейдер останется в силе, в log уйдёт error.
register_reloadable_shader :: proc(
    name:         string,
    target:       ^rl.Shader,
    fs_path:      string,
    vs_path:      string = "",
    after_reload: proc(user: rawptr) = nil,
    user:         rawptr = nil,
) {
    append(&reloadable_shaders, ReloadableShader{
        name         = name,
        fs_path      = fs_path,
        vs_path      = vs_path,
        target       = target,
        after_reload = after_reload,
        user         = user,
    })
}

// Перезагружает все зарегистрированные шейдеры из их файлов.
// Возвращает (успешно, с ошибками).
//
// При ошибке компиляции/чтения старый шейдер НЕ трогается —
// битый код не сломает текущий кадр.
reload_all_shaders :: proc() -> (ok, failed: int) {
    for &rs in reloadable_shaders {
        if rs.target == nil { failed += 1; continue }

        new_shader, err := load_shader_from_files(rs.vs_path, rs.fs_path)
        if err != "" {
            log.errorf("shader_hot_reload: %s: %s", rs.name, err)
            failed += 1
            continue
        }

        if rl.IsShaderValid(rs.target^) {
            rl.UnloadShader(rs.target^)
        }
        rs.target^ = new_shader

        if rs.after_reload != nil {
            rs.after_reload(rs.user)
        }

        log.infof("shader_hot_reload: %s reloaded from %s", rs.name, rs.fs_path)
        ok += 1
    }
    return
}

@(private)
load_shader_from_files :: proc(vs_path, fs_path: string) -> (rl.Shader, string) {
    fs_cs := cstring_temp(fs_path)
    if fs_cs == nil { return {}, "fs_path → cstring failed" }

    shader: rl.Shader
    if vs_path == "" {
        shader = rl.LoadShader(nil, fs_cs)
    } else {
        vs_cs := cstring_temp(vs_path)
        if vs_cs == nil { return {}, "vs_path → cstring failed" }
        shader = rl.LoadShader(vs_cs, fs_cs)
    }

    if !rl.IsShaderValid(shader) {
        return {}, fmt.tprintf("compile failed: %s", fs_path)
    }
    return shader, ""
}
