package core

import "core:log"
import "core:strings"

// Allocates a cstring with context.temp_allocator.
// Memory is valid until free_all(temp_allocator). Returns nil on failure.
cstring_temp :: proc(s: string) -> cstring {
    cs, err := strings.clone_to_cstring(s, context.temp_allocator)
    if err != .None {
        log.errorf("cstring_temp: %q failed: %v", s, err)
        return nil
    }
    return cs
}

// Allocates a cstring with context.allocator.
// Caller must `delete(cs)` when done. Returns "" on failure.
cstring_alloc :: proc(s: string) -> cstring {
    cs, err := strings.clone_to_cstring(s)
    if err != .None {
        log.errorf("cstring_alloc: %q failed: %v", s, err)
        return ""
    }
    return cs
}