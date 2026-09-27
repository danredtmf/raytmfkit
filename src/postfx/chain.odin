package postfx

import "core:math"
import rl "deps:raylib"
import kcore "raytmfkit:core"

// Как растягивать финальную текстуру на экран.
FinalScaleMode :: enum {
    STRETCH,    // заполнить окно, аспект не сохраняется
    LETTERBOX,  // вписать с сохранением аспекта, чёрные полосы
    INTEGER,    // пиксель-перфект: целый множитель, минимум 1
}

Stage :: struct {
    target: RenderTarget,
    shader: rl.Shader,
}

Chain :: struct {
    scene:        RenderTarget,
    stages:       [dynamic]Stage,

    // Размер, в котором рисуется и обрабатывается сцена.
    // Фиксирован, не реагирует на ресайз окна.
    virtual_size: [2]i32,

    mode:         FinalScaleMode,

    // Заполняется в draw_final. Нужен для маппинга мыши.
    _dst_rect:    rl.Rectangle,
}

// init_chain создаёт scene и n_stages таргетов в размере virtual_size.
init_chain :: proc(
    c:            ^Chain,
    virtual_size: [2]i32,
    n_stages:     int,
    mode:         FinalScaleMode = .LETTERBOX,
) {
    c.virtual_size = virtual_size
    c.mode         = mode

    init_target(&c.scene, virtual_size[0], virtual_size[1])

    c.stages = make([dynamic]Stage, n_stages)
    for i in 0 ..< n_stages {
        init_target(&c.stages[i].target, virtual_size[0], virtual_size[1])
    }
}

deinit_chain :: proc(c: ^Chain) {
    deinit_target(&c.scene)
    for &s in c.stages {
        deinit_target(&s.target)
    }
    delete(c.stages)
}

// Пересоздаёт таргеты, если их размер разошёлся с virtual_size.
// Нужно только если virtual_size поменяли после init_chain.
// При ресайзе окна вызывать не требуется — размер не зависит от окна.
ensure_chain_size :: proc(c: ^Chain) {
    check :: proc(t: ^RenderTarget, w, h: i32) {
        if t.tex.texture.width != w || t.tex.texture.height != h {
            rl.UnloadRenderTexture(t.tex)
            t.tex = rl.LoadRenderTexture(w, h)
        }
    }
    check(&c.scene, c.virtual_size[0], c.virtual_size[1])
    for &s in c.stages {
        check(&s.target, c.virtual_size[0], c.virtual_size[1])
    }
}

// Прогоняет scene → stage[0] → stage[1] → ... → stage[n-1].
// Все стадии работают в virtual_size, независимо от окна.
run_chain :: proc(c: ^Chain) {
    if len(c.stages) == 0 { return }

    prev := c.scene.tex.texture
    for i in 0 ..< len(c.stages) {
        blit(c.stages[i].target, prev, c.stages[i].shader)
        prev = c.stages[i].target.tex.texture
    }
}

final_texture :: proc(c: ^Chain) -> rl.Texture2D {
    if len(c.stages) == 0 {
        return c.scene.tex.texture
    }
    return c.stages[len(c.stages) - 1].target.tex.texture
}

// Рисует финальную текстуру на экран с учётом mode.
// Заполняет c._dst_rect — прямоугольник на экране, куда попадает рендер.
// Фон для полос (при LETTERBOX / INTEGER) заливается чёрным.
draw_final :: proc(c: ^Chain) {
    win_w := f32(kcore.ctx.screen.x)
    win_h := f32(kcore.ctx.screen.y)
    src_w := f32(c.virtual_size[0])
    src_h := f32(c.virtual_size[1])

    dst: rl.Rectangle

    switch c.mode {
    case .STRETCH:
        dst = {0, 0, win_w, win_h}

    case .LETTERBOX:
        scale := min(win_w / src_w, win_h / src_h)
        dst_w := src_w * scale
        dst_h := src_h * scale
        dst = {(win_w - dst_w) / 2, (win_h - dst_h) / 2, dst_w, dst_h}

    case .INTEGER:
        scale := max(f32(1), f32(math.floor(min(win_w / src_w, win_h / src_h))))
        dst_w := src_w * scale
        dst_h := src_h * scale
        dst = {
            f32(math.floor((win_w - dst_w) / 2)),
            f32(math.floor((win_h - dst_h) / 2)),
            dst_w, dst_h,
        }
    }

    c._dst_rect = dst

    if c.mode != .STRETCH {
        rl.DrawRectangle(0, 0, kcore.ctx.screen.x, kcore.ctx.screen.y, rl.BLACK)
    }

    // Render target в raylib хранится перевёрнутым по Y — отрицательная высота.
    src := rl.Rectangle{0, 0, src_w, src_h}
    rl.DrawTexturePro(final_texture(c), src, dst, {0, 0}, 0, rl.WHITE)
}

set_stage_shader :: proc(c: ^Chain, i: int, shader: rl.Shader) {
    c.stages[i].shader = shader
}

// --- Маппинг координат ---

// Точка экрана → координаты виртуального рендера.
// Для точек вне _dst_rect результат выходит за границы [0..virtual_size]
// — проверяй screen_in_bounds, если это критично.
screen_to_virtual :: proc(c: Chain, p: rl.Vector2) -> rl.Vector2 {
    if c._dst_rect.width <= 0 || c._dst_rect.height <= 0 {
        return {0, 0}
    }
    u := (p.x - c._dst_rect.x) / c._dst_rect.width
    v := (p.y - c._dst_rect.y) / c._dst_rect.height
    return {u * f32(c.virtual_size[0]), v * f32(c.virtual_size[1])}
}

// Точка виртуального рендера → экранные координаты.
virtual_to_screen :: proc(c: Chain, p: rl.Vector2) -> rl.Vector2 {
    u := p.x / f32(c.virtual_size[0])
    v := p.y / f32(c.virtual_size[1])
    return {
        c._dst_rect.x + u * c._dst_rect.width,
        c._dst_rect.y + v * c._dst_rect.height,
    }
}

// Попадает ли точка экрана в область виртуального рендера.
// При LETTERBOX/INTEGER точки в чёрных полосах возвращают false.
screen_in_bounds :: proc(c: Chain, p: rl.Vector2) -> bool {
    return p.x >= c._dst_rect.x &&
           p.x <  c._dst_rect.x + c._dst_rect.width &&
           p.y >= c._dst_rect.y &&
           p.y <  c._dst_rect.y + c._dst_rect.height
}
