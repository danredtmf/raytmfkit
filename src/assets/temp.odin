package assets

import "core:log"
import "core:os"

// Writes `data` to `path` (relative to CWD).
save_temp_file :: proc(path: string, data: []u8) -> bool {
    err := os.write_entire_file(path, data)
    if err != nil {
        log.errorf("save_temp_file: %s: %v", path, err)
        return false
    }
    return true
}

// Removes the file at `path`.
delete_temp_file :: proc(path: string) -> bool {
    err := os.remove(path)
    if err != nil {
        log.errorf("delete_temp_file: %s: %v", path, err)
        return false
    }
    return true
}