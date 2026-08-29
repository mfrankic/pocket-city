package main

import "core:math/rand"
import city "./city"
import window "./window"
import rl "vendor:raylib"

TICK_DT :: 0.25

main :: proc() {
	rl.InitWindow(window.WIN_W, window.WIN_H, "Pocket City")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	c := city.city_new()
	defer free(c)
	paused := true
	speed := 1
	tool := window.Tool.Road
	overlay := window.Overlay.None
	tick_acc: f32
	cam := rl.Camera2D {
		zoom   = 1,
		target = {f32(city.MAP_SIZE * window.LOT_PX) / 2, f32(city.MAP_SIZE * window.LOT_PX) / 2},
		offset = {f32(window.LEFT_W) + f32(window.MAP_W) / 2, f32(window.MAP_H) / 2},
	}

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)

		if rl.IsKeyPressed(.ONE) do tool = .Road
		if rl.IsKeyPressed(.TWO) do tool = .Residential
		if rl.IsKeyPressed(.THREE) do tool = .Commercial
		if rl.IsKeyPressed(.FOUR) do tool = .Industrial
		if rl.IsKeyPressed(.FIVE) do tool = .Bulldoze
		if rl.IsKeyPressed(.SIX) do tool = .Station
		if rl.IsKeyPressed(.SEVEN) do tool = .Tower
		if rl.IsKeyPressed(.EIGHT) do tool = .Park
		if rl.IsKeyPressed(.NINE) do tool = .School
		if rl.IsKeyPressed(.ZERO) do tool = .Police
		if rl.IsKeyPressed(.F) do tool = .Firehouse
		if rl.IsKeyPressed(.H) do tool = .Hospital
		if rl.IsKeyPressed(.P) do overlay = .None if overlay == .Power else .Power
		if rl.IsKeyPressed(.W) do overlay = .None if overlay == .Water else .Water
		if rl.IsKeyPressed(.O) do overlay = .None if overlay == .Pollution else .Pollution
		if rl.IsKeyPressed(.V) do overlay = .None if overlay == .Land_Value else .Land_Value
		if rl.IsKeyPressed(.E) do overlay = .None if overlay == .Education else .Education
		if rl.IsKeyPressed(.T) do overlay = .None if overlay == .Traffic else .Traffic
		if rl.IsKeyPressed(.C) do overlay = .None if overlay == .Crime else .Crime
		if rl.IsKeyPressed(.I) do overlay = .None if overlay == .Fire else .Fire
		if rl.IsKeyPressed(.LEFT_BRACKET) do city.city_set_tax(c, city.city_tax(c) - 1)
		if rl.IsKeyPressed(.RIGHT_BRACKET) do city.city_set_tax(c, city.city_tax(c) + 1)
		if rl.IsKeyPressed(.MINUS) || rl.IsKeyPressed(.KP_SUBTRACT) {
			if speed > 1 do speed /= 2
		}
		if rl.IsKeyPressed(.EQUAL) || rl.IsKeyPressed(.KP_ADD) {
			if speed < 4 do speed *= 2
		}
		if rl.IsKeyPressed(.SPACE) do paused = !paused
		if rl.IsKeyPressed(.S) {
			city.city_save(c, city.SAVE_PATH)
		}
		if rl.IsKeyPressed(.L) {
			if loaded, ok := city.city_load(city.SAVE_PATH); ok {
				free(c)
				c = loaded
				tick_acc = 0
			}
		}

		wheel := rl.GetMouseWheelMove()
		if wheel != 0 {
			mouse := rl.GetMousePosition()
			before := rl.GetScreenToWorld2D(mouse, cam)
			cam.zoom *= 1.1 if wheel > 0 else 1 / 1.1
			cam.zoom = clamp(cam.zoom, 0.25, 4)
			after := rl.GetScreenToWorld2D(mouse, cam)
			cam.target.x += before.x - after.x
			cam.target.y += before.y - after.y
		}
		if rl.IsMouseButtonDown(.RIGHT) {
			d := rl.GetMouseDelta()
			cam.target.x -= d.x / cam.zoom
			cam.target.y -= d.y / cam.zoom
		}

		hover := window.hover_lot(cam)
		if rl.IsMouseButtonDown(.LEFT) && hover.ok {
			switch tool {
			case .Road:
				city.paint_road(c, hover.x, hover.y)
			case .Residential:
				city.paint_zone(c, hover.x, hover.y, .Residential)
			case .Commercial:
				city.paint_zone(c, hover.x, hover.y, .Commercial)
			case .Industrial:
				city.paint_zone(c, hover.x, hover.y, .Industrial)
			case .Bulldoze:
				city.bulldoze(c, hover.x, hover.y)
			case .Station:
				size := 2 if rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT) else 1
				city.stamp(c, hover.x, hover.y, .Station, size)
			case .Tower:
				city.stamp(c, hover.x, hover.y, .Tower)
			case .Park:
				city.stamp(c, hover.x, hover.y, .Park)
			case .School:
				city.stamp(c, hover.x, hover.y, .School)
			case .Police:
				city.stamp(c, hover.x, hover.y, .Police)
			case .Firehouse:
				city.stamp(c, hover.x, hover.y, .Firehouse)
			case .Hospital:
				city.stamp(c, hover.x, hover.y, .Hospital)
			}
		}

		if !paused {
			tick_acc += rl.GetFrameTime() * f32(speed)
			for tick_acc >= TICK_DT {
				tick_acc -= TICK_DT
				city.tick(c, pick)
			}
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.DARKGREEN)
		window.draw(c, cam, overlay, paused, speed, tool, hover)
		rl.EndDrawing()
	}
}

pick :: proc(n: int) -> int {
	return rand.int_max(n)
}
