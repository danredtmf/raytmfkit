package core

import rl "deps:raylib"

begin_frame :: proc() {
    ctx.delta       = rl.GetFrameTime()
    ctx.time        = rl.GetTime()
    ctx.frame      += 1
    sync_screen()
    ctx.mouse       = rl.GetMousePosition()
    ctx.mouse_delta = rl.GetMouseDelta()
    ctx.fullscreen  = is_fullscreen()
    ctx.focused     = rl.IsWindowFocused()
    reset_cursor_intent()
}

// Обновляет только размеры экрана в ctx, не трогая delta/time/frame/mouse.
// Нужно, если код ДО первого begin_frame читает get_scale / ctx.screen_vec2
// (типичный сценарий — посчитать размеры UI-элементов при загрузке).
sync_screen :: proc() {
    ctx.screen      = render_resolution()
    ctx.screen_vec2 = {f32(ctx.screen.x), f32(ctx.screen.y)}
    ctx.screen_half = ctx.screen_vec2 / 2
}

// Парная к begin_frame. Звать в самом конце кадра, после rl.EndDrawing().
//
// Делает две вещи:
//   1. apply_cursor — физически применяет последнее cursor-намерение кадра.
//      Если end_frame не позвать, желание курсора потеряется, а иконка
//      может остаться от предыдущего кадра.
//   2. free_all(temp_allocator) — освобождает всю память, выделенную
//      через context.temp_allocator в этом кадре. Это соответствует
//      соглашению kit'а: temp живёт ровно один кадр. Если вашей игре
//      нужны данные, переживающие кадр, — выделяйте context.allocator.
end_frame :: proc() {
    apply_cursor()
    free_all(context.temp_allocator)
}
