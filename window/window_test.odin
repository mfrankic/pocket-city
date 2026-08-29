package window

import "core:testing"

@(test)
on_hud_is_chrome_not_map :: proc(t: ^testing.T) {
	testing.expect(t, !on_hud(f32(LEFT_W), 0))
	testing.expect(t, !on_hud(f32(LEFT_W + MAP_W / 2), f32(MAP_H / 2)))
	testing.expect(t, !on_hud(f32(LEFT_W + MAP_W - 1), f32(MAP_H - 1)))
	testing.expect(t, on_hud(0, 0))
	testing.expect(t, on_hud(f32(LEFT_W - 1), 10))
	testing.expect(t, on_hud(f32(LEFT_W + MAP_W), 10))
	testing.expect(t, on_hud(f32(WIN_W - 1), 10))
	testing.expect(t, on_hud(f32(LEFT_W + 10), f32(MAP_H)))
	testing.expect(t, on_hud(f32(LEFT_W + 10), f32(WIN_H - 1)))
}
