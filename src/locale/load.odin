package locale

import "core:encoding/json"
import "core:log"

// Парсит JSON-байты в Localization.
// Возвращает nil при ошибке — вызывающий сам решает, что делать.
load_from_bytes :: proc(data: []u8) -> Localization {
    loc: Localization
    err := json.unmarshal(data, &loc)
    if err != nil {
        log.errorf("locale.load_from_bytes: %v", err)
        return nil
    }
    return loc
}

// Возвращает строку для текущего языка.
// Если id не найден — возвращает сам id (чтобы было видно в UI, что забыли перевести).
get :: proc(loc: Localization, id: string, lang: Language) -> string {
    entry, ok := loc[id]
    if !ok {
        return id
    }
    switch lang {
    case .EN: return entry.en
    case .RU: return entry.ru
    }
    return id
}
