#+build darwin, linux, freebsd, openbsd, netbsd
package locale

import "core:sys/posix"

@(private = "package")
detect_posix :: proc() -> Language {
    // Порядок как в стандарте: LC_ALL > LC_MESSAGES > LANG
    for key in ([]cstring{"LC_ALL", "LC_MESSAGES", "LANG"}) {
        v := posix.getenv(key)
        if v != "" {
            return parse_locale_string(string(v))
        }
    }
    return .EN
}
