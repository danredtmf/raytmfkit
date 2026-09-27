#+build windows
package locale

import "core:log"
import "core:unicode/utf16"
import "core:sys/windows"

foreign import kernel32 "system:Kernel32.lib"
@(default_calling_convention="system")
foreign kernel32 {
    @(private = "file")
    GetUserDefaultLocaleName :: proc(buf: windows.LPWSTR, cch: i32) -> i32 ---
}

@(private = "package")
detect_windows :: proc() -> Language {
    buf: [windows.LOCALE_NAME_MAX_LENGTH]u16
    n := GetUserDefaultLocaleName(&buf[0], windows.LOCALE_NAME_MAX_LENGTH)
    if n <= 0 {
        log.warn("locale.detect_windows: GetUserDefaultLocaleName returned 0")
        return .EN
    }

    // n включает null-терминатор
    utf16_slice := buf[:n - 1]

    utf8_buf: [128]byte
    m := utf16.decode_to_utf8(utf8_buf[:], utf16_slice)
    return parse_locale_string(string(utf8_buf[:m]))
}
