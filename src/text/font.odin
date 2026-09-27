package text

import rl "deps:raylib"
import "core:c"

FontKind :: enum { NORMAL, SDF }

FontPair :: struct {
    normal: rl.Font,
    sdf:    rl.Font,
    active: FontKind,
}

font_of :: proc(fp: FontPair) -> rl.Font {
    return fp.sdf if fp.active == .SDF else fp.normal
}

is_sdf :: proc(fp: FontPair) -> bool {
    return fp.active == .SDF
}

get_default_codepoints :: proc(allocator := context.allocator) -> [dynamic]rune {
    cps := make([dynamic]rune, allocator = allocator)

    // Basic Latin: пробел..тильда
    for r in 0x0020 ..= 0x007E { append(&cps, rune(r)) }

    // Кириллица: А-я
    for r in 0x0410 ..= 0x044F { append(&cps, rune(r)) }

    // Ё / ё
    append(&cps, 0x0401, 0x0451)

    // Типографика
    append(&cps,
        0x2014, // —
        0x2026, // …
        0x00AB, 0x00BB, // « »
        0x2116, // №
    )

    return cps
}

load_font_normal :: proc(data: []u8, size: c.int, cps: []rune) -> rl.Font {
    return rl.LoadFontFromMemory(
        ".ttf", raw_data(data), i32(len(data)),
        size, raw_data(cps), i32(len(cps)),
    )
}

load_font_sdf :: proc(data: []u8, size: c.int, cps: []rune, padding: c.int = 6) -> rl.Font {
    glyph_count: c.int
    glyphs := rl.LoadFontData(
        raw_data(data), i32(len(data)),
        size, raw_data(cps), i32(len(cps)),
        .SDF, &glyph_count,
    )

    glyph_recs: [^]rl.Rectangle
    atlas := rl.GenImageFontAtlas(glyphs, &glyph_recs, glyph_count, size, padding, 0)

    texture := rl.LoadTextureFromImage(atlas)
    rl.SetTextureFilter(texture, .TRILINEAR)
    rl.UnloadImage(atlas)

    return rl.Font {
        baseSize     = size,
        glyphCount   = glyph_count,
        glyphPadding = padding,
        texture      = texture,
        recs         = glyph_recs,
        glyphs       = glyphs,
    }
}

load_font_pair :: proc(data: []u8, size: c.int, cps: []rune) -> FontPair {
    fp: FontPair
    fp.normal = load_font_normal(data, size, cps)
    fp.sdf    = load_font_sdf(data, size, cps)
    fp.active = .NORMAL
    return fp
}

unload_font_pair :: proc(fp: ^FontPair) {
    rl.UnloadFont(fp.normal)
    rl.UnloadFont(fp.sdf)
}
