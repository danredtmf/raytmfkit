package locale

// Определяет язык системы.
// Возвращает .EN, если ничего подходящего не найдено.
detect :: proc() -> Language {
    when ODIN_OS == .Windows {
        return detect_windows()
    } else when ODIN_OS == .Linux || ODIN_OS == .Darwin || \
               ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD {
        return detect_posix()
    } else {
        return .EN
    }
}

// Парсит строку локали вида "ru_RU.UTF-8", "en-US", "ru" → Language.
parse_locale_string :: proc(s: string) -> Language {
    // Проверяем только первые два символа — этого хватает для ru/en.
    if len(s) < 2 {
        return .EN
    }
    lo := s[0] | 0x20   // ASCII lowercase для ASCII
    hi := s[1] | 0x20
    if lo == 'r' && hi == 'u' {
        return .RU
    }
    return .EN
}
