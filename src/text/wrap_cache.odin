package text

import rl "deps:raylib"

// ---------- LRU-кэш wrap_text ----------
//
// Кэширует разбиение текста на строки по ключу
// (font.texture.id, font.baseSize, size, spacing_h, max_width, word_wrap, hash(text)).
// Экономит glyph_advance-итерацию для тултипов, логов, диалогов —
// текста, который не меняется кадр к кадру.
//
// Семантика: оба возвращаемых среза (runes и lines) живут ВНУТРИ кэша.
// Их нельзя освобождать, нельзя мутировать и нельзя держать между
// вызовами wrap_text_cached: LRU может вытеснить запись.
// Для длительного хранения используйте wrap_text + свой runes-буфер.

@(private)
DEFAULT_WRAP_CACHE_CAPACITY :: 128

@(private)
WrapCacheKey :: struct {
    font_id:      u32,
    font_base:    i32,
    size_bits:    u32,
    spacing_bits: u32,
    width_bits:   u32,
    word_wrap:    bool,
    text_hash:    u64,
    text_len:     int,
}

@(private)
WrapCacheEntry :: struct {
    key:     WrapCacheKey,
    runes:   []rune,
    lines:   []Line,
    used_at: u64,
}

@(private)
WrapCache :: struct {
    entries:  [dynamic]WrapCacheEntry,
    capacity: int,
    tick:     u64,
}

@(private)
wrap_cache: WrapCache

// Устанавливает ёмкость кэша. Существующие записи уничтожаются.
// Зовите один раз при загрузке — дальше кэш работает лениво.
wrap_cache_configure :: proc(capacity: int) {
    wrap_cache_clear()
    if wrap_cache.entries != nil {
        delete(wrap_cache.entries)
    }
    wrap_cache.capacity = max(1, capacity)
    wrap_cache.entries  = make([dynamic]WrapCacheEntry, 0, wrap_cache.capacity)
    wrap_cache.tick     = 0
}

// Удаляет все записи, оставляя кэш работоспособным.
wrap_cache_clear :: proc() {
    if wrap_cache.entries == nil { return }
    for &e in wrap_cache.entries {
        delete(e.runes)
        delete(e.lines)
    }
    clear(&wrap_cache.entries)
}

// Освобождает всю память кэша. После этого wrap_text_cached
// снова сработает лениво, с ёмкостью по умолчанию.
wrap_cache_deinit :: proc() {
    if wrap_cache.entries == nil { return }
    wrap_cache_clear()
    delete(wrap_cache.entries)
    wrap_cache.entries = nil
    wrap_cache.tick    = 0
}

@(private)
wrap_cache_ensure :: proc() {
    if wrap_cache.entries != nil { return }
    wrap_cache.capacity = DEFAULT_WRAP_CACHE_CAPACITY
    wrap_cache.entries  = make([dynamic]WrapCacheEntry, 0, wrap_cache.capacity)
    wrap_cache.tick     = 0
}

@(private)
wrap_cache_lookup :: proc(key: WrapCacheKey) -> ^WrapCacheEntry {
    if wrap_cache.entries == nil { return nil }
    for &e in wrap_cache.entries {
        if e.key == key {
            wrap_cache.tick += 1
            e.used_at = wrap_cache.tick
            return &e
        }
    }
    return nil
}

@(private)
wrap_cache_insert :: proc(key: WrapCacheKey, runes: []rune, lines: []Line) {
    wrap_cache_ensure()

    // Кэш полон — вытесняем LRU-запись на месте.
    if len(wrap_cache.entries) >= wrap_cache.capacity {
        lru_idx := 0
        lru_t   := wrap_cache.entries[0].used_at
        for i in 1 ..< len(wrap_cache.entries) {
            if wrap_cache.entries[i].used_at < lru_t {
                lru_t   = wrap_cache.entries[i].used_at
                lru_idx = i
            }
        }
        delete(wrap_cache.entries[lru_idx].runes)
        delete(wrap_cache.entries[lru_idx].lines)

        wrap_cache.tick += 1
        wrap_cache.entries[lru_idx] = WrapCacheEntry{
            key     = key,
            runes   = runes,
            lines   = lines,
            used_at = wrap_cache.tick,
        }
        return
    }

    wrap_cache.tick += 1
    append(&wrap_cache.entries, WrapCacheEntry{
        key     = key,
        runes   = runes,
        lines   = lines,
        used_at = wrap_cache.tick,
    })
}

// Кэшированный вариант wrap_text.
//
// Возвращаемые срезы принадлежат кэшу. Правила:
//   - не освобождать (delete/free);
//   - не мутировать;
//   - использовать сразу — до следующего вызова wrap_text_cached.
//
// При промахе аллоцирует через context.allocator, а не temp —
// запись переживает free_all(temp_allocator) в конце кадра.
wrap_text_cached :: proc(
    font:      rl.Font,
    text:      string,
    max_width: f32,
    size:      f32,
    spacing_h: f32,
    word_wrap: bool,
) -> (runes: []rune, lines: []Line) {
    key := WrapCacheKey{
        font_id      = font.texture.id,
        font_base    = font.baseSize,
        size_bits    = f32_bits(size),
        spacing_bits = f32_bits(spacing_h),
        width_bits   = f32_bits(max_width),
        word_wrap    = word_wrap,
        text_hash    = fnv1a_string(text),
        text_len     = len(text),
    }

    if e := wrap_cache_lookup(key); e != nil {
        return e.runes, e.lines
    }

    r := utf8_to_runes(text, context.allocator)
    l := wrap_text(font, r, max_width, size, spacing_h, word_wrap, context.allocator)
    wrap_cache_insert(key, r, l)
    return r, l
}

@(private)
f32_bits :: proc(f: f32) -> u32 {
    return transmute(u32)f
}

@(private)
fnv1a_string :: proc(s: string) -> u64 {
    h: u64 = 0xcbf29ce484222325
    for b in s {
        h ~= u64(b)
        h *= 0x100000001b3
    }
    return h
}
