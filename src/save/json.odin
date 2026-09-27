package save

import "core:encoding/json"
import "core:log"
import "core:os"

// Сериализует value в JSON и пишет в path.
// Если key непустой — данные XOR-обрабатываются перед записью.
// Возвращает true при успехе.
save_json :: proc(
    path:    string,
    value:   $T,
    key:     []u8 = nil,
    options := json.Marshal_Options{},
) -> bool {
    data, err := json.marshal(value, options, context.allocator)
    defer delete(data)

    if err != .None {
        log.errorf("save.save_json: marshal %q: %v", path, err)
        return false
    }

    if len(key) > 0 {
        xor_in_place(data, key)
    }

    werr := os.write_entire_file(path, data)
    if werr != os.ERROR_NONE {
        log.errorf("save.save_json: write %q: %v", path, werr)
        return false
    }
    return true
}

// Читает файл, опционально расшифровывает, парсит в ptr.
// Возвращает true при успехе. При ошибке ptr не трогается.
load_json :: proc(
    path: string,
    ptr:  ^$T,
    key:  []u8 = nil,
) -> bool {
    data, ok := os.read_entire_file_from_path(path, context.allocator)
    if ok != os.ERROR_NONE {
        log.errorf("save.load_json: read %q: %v", path, ok)
        return false
    }
    defer delete(data)

    if len(key) > 0 {
        xor_in_place(data, key)
    }

    err := json.unmarshal(data, ptr)
    if err != .None {
        log.errorf("save.load_json: unmarshal %q: %v", path, err)
        return false
    }
    return true
}

// То же, что load_json, но при ошибке (нет файла / битый JSON)
// присваивает fallback и возвращает false.
// Удобно для первого запуска: load_json_or(path, &cfg, default_cfg).
load_json_or :: proc(
    path:     string,
    ptr:      ^$T,
    fallback: T,
    key:      []u8 = nil,
) -> bool {
    if load_json(path, ptr, key) {
        return true
    }
    ptr^ = fallback
    return false
}

// Проверяет существование файла.
exists :: proc(path: string) -> bool {
    return os.exists(path)
}

// Удаляет файл. Возвращает true при успехе.
remove :: proc(path: string) -> bool {
    err := os.remove(path)
    if err != os.ERROR_NONE {
        log.errorf("save.remove: %q: %v", path, err)
        return false
    }
    return true
}