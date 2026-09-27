#+build linux
package debug

import "core:fmt"
import os "core:os"
import "core:strconv"
import "core:strings"
import "core:sys/linux"

ram_usage_mb :: proc() -> u64 {
    path := fmt.tprintf("/proc/%d/status", linux.getpid())

    data, ok := os.read_entire_file(path, context.temp_allocator)
    if ok != os.ERROR_NONE {
        return 0
    }

    lines := strings.split_lines(string(data), context.temp_allocator)
    for line in lines {
        if !strings.has_prefix(line, "VmRSS:") { continue }

        fields := strings.fields(line, context.temp_allocator)
        if len(fields) < 2 { return 0 }

        kb, ok := strconv.parse_i64(fields[1])
        if !ok { return 0 }

        return u64(kb) / 1024
    }
    return 0
}
