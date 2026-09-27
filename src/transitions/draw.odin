package transitions

import rl "deps:raylib"
import kcore "raytmfkit:core"

// Рисует полноэкранный прямоугольник текущего цвета перехода.
// Вызывать ПОСЛЕ всего игрового рендера, НО ДО UI (если UI должен быть поверх fade — то после UI).
draw_fullscreen :: proc(t: Transition) {
    rl.DrawRectangle(
        0, 0,
        kcore.ctx.screen.x,
        kcore.ctx.screen.y,
        t.fade.current,
    )
}
