package text

import rl "deps:raylib"

Line :: struct {
    start, end:  int,    // индексы в runes; end включительный
    width:       f32,    // ширина в пикселях (с spacing_h)
    space_count: int,    // для justify
    is_para_end: bool,   // последняя строка абзаца (не растягивать)
}

// Разбивает runes на строки шириной не больше max_width.
// НЕ рисует. Возвращает слайс в переданный аллокатор.
wrap_text :: proc(
    font:        rl.Font,
    runes:       []rune,
    max_width:   f32,
    size:        f32,
    spacing_h:   f32,
    word_wrap:   bool,
    allocator := context.temp_allocator,
) -> []Line {
    lines := make([dynamic]Line, 0, 16, allocator)
    n := len(runes)

    i := 0
    for i < n {
        start       := i
        width       := f32(0)
        last_space  := -1
        line_emitted := false

        j := i
        for j < n {
            r := runes[j]

            // Явный перевод строки
            if r == '\n' {
                append(&lines, Line{
                    start       = start,
                    end         = j - 1,
                    width       = width,
                    space_count = 0,
                    is_para_end = true,
                })
                i = j + 1
                line_emitted = true
                break
            }

            adv := glyph_advance(font, r, size)
            // Пробел в конце строки не должен добавлять spacing_h
            adv_with_spacing := adv + spacing_h

            if r == ' ' || r == '\t' { last_space = j }

            // Перенос
            if word_wrap && width + adv_with_spacing > max_width {
                end := j - 1
                if last_space >= start {
                    end = last_space
                } else if end < start {
                    // Единственное слово длиннее max_width — режем по буквам
                    end = j
                }

                append(&lines, Line{
                    start       = start,
                    end         = end,
                    width       = width,
                    space_count = count_spaces(runes[start:end+1]),
                    is_para_end = false,
                })
                i = end + 1
                line_emitted = true
                break
            }

            width += adv_with_spacing
            j += 1

            if j >= n {
                append(&lines, Line{
                    start       = start,
                    end         = j - 1,
                    width       = width,
                    space_count = count_spaces(runes[start:j]),
                    is_para_end = true,
                })
                i = j
                line_emitted = true
                break
            }
        }

        if !line_emitted {
            // Пустая строка (двойной \n) или пустой вход — эмитим пустую
            append(&lines, Line{
                start       = start,
                end         = start - 1,
                is_para_end = true,
            })
            i = start + 1
        }
    }

    return lines[:]
}

@(private)
glyph_advance :: proc(font: rl.Font, r: rune, size: f32) -> f32 {
    if r == '\n' { return 0 }
    scale := size / f32(font.baseSize)
    idx := rl.GetGlyphIndex(font, r)
    if font.glyphs[idx].advanceX == 0 {
        return f32(font.recs[idx].width) * scale
    }
    return f32(font.glyphs[idx].advanceX) * scale
}

@(private)
count_spaces :: proc(runes: []rune) -> int {
    n := 0
    for r in runes { if r == ' ' { n += 1 } }
    return n
}

measure_lines_height :: proc(
    lines: []Line,
    font: rl.Font,
    size: f32,
    spacing_v: f32,
) -> f32 {
    if len(lines) == 0 { return 0 }
    line_h := f32(font.baseSize) * (size / f32(font.baseSize)) * 1.5 * spacing_v
    return line_h * f32(len(lines))
}

draw_lines :: proc(
    font:      rl.Font,
    runes:     []rune,
    lines:     []Line,
    rect:      rl.Rectangle,
    size:      f32,
    color:     rl.Color,
    align_h:   TextAlignH,
    align_v:   TextAlignV,
    spacing_v: f32,
    spacing_h: f32,
    use_sdf:   bool,
) {
    if len(lines) == 0 { return }

    line_h := size * 1.5 * spacing_v
    total_h := line_h * f32(len(lines))

    base_y := rect.y
    switch align_v {
    case .TOP:    // ничего
    case .MIDDLE: base_y += (rect.height - total_h) / 2
    case .BOTTOM: base_y += rect.height - total_h
    }

    if use_sdf { rl.BeginShaderMode(sdf_shader) }
    defer if use_sdf { rl.EndShaderMode() }

    for line, li in lines {
        x0 := rect.x
        per_space_extra := f32(0)

        switch align_h {
        case .LEFT:  // ничего
        case .CENTER: x0 += (rect.width - line.width) / 2
        case .RIGHT:  x0 += rect.width - line.width
        case .JUSTIFY:
            if line.space_count > 0 && !line.is_para_end {
                extra := rect.width - line.width
                if extra > 0 { per_space_extra = extra / f32(line.space_count) }
            }
        }

        x := x0
        y := base_y + f32(li) * line_h

        if line.start > line.end { continue }  // пустая строка

        for k in line.start ..= line.end {
            r := runes[k]
            if r == '\n' { continue }

            adv := glyph_advance(font, r, size)

            if r == ' ' || r == '\t' {
                x += adv
                if align_h == .JUSTIFY { x += per_space_extra }
                if k < line.end { x += spacing_h }
            } else {
                rl.DrawTextCodepoint(font, r, {x, y}, size, color)
                x += adv
                if k < line.end { x += spacing_h }
            }
        }
    }
}

draw_text_boxed :: proc(
    font:      rl.Font,
    text:      string,
    rect:      rl.Rectangle,
    size:      f32,
    word_wrap: bool,
    color:     rl.Color,
    align_h:   TextAlignH = .LEFT,
    align_v:   TextAlignV = .TOP,
    spacing_v: f32 = 1,
    spacing_h: f32 = 0,
    use_sdf:   bool = false,
) {
    runes := utf8_to_runes(text, context.temp_allocator)
    lines := wrap_text(font, runes, rect.width, size, spacing_h, word_wrap)

    draw_lines(font, runes, lines, rect, size, color,
        align_h, align_v, spacing_v, spacing_h, use_sdf)
}

utf8_to_runes :: proc(s: string, allocator := context.temp_allocator) -> []rune {
    out := make([dynamic]rune, 0, len(s), allocator)
    for r in s { append(&out, r) }
    return out[:]
}
