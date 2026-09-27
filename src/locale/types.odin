package locale

Language :: enum {
    EN,
    RU,
}

// Одна строка локализации для всех языков.
// Добавить новый язык = добавить поле + значение в JSON.
Entry :: struct {
    en: string `json:"EN"`,
    ru: string `json:"RU"`,
}

Localization :: map[string]Entry
