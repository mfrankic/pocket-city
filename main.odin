package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import city "./city"
import rl "vendor:raylib"

LOT_PX :: 16
HUD_H :: 64
WIN_W :: 960
WIN_H :: 640
TICK_DT :: 0.25

Tool :: enum {
	Road,
	Residential,
	Commercial,
	Bulldoze,
}

main :: proc() {
	rl.InitWindow(WIN_W, WIN_H, "Pocket City")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	c := city.city_new()
	paused := true
	tool := Tool.Road
	tick_acc: f32
	cam := rl.Camera2D {
		zoom   = 1,
		target = {f32(city.MAP_SIZE * LOT_PX) / 2, f32(city.MAP_SIZE * LOT_PX) / 2},
		offset = {f32(WIN_W) / 2, f32(HUD_H) + f32(WIN_H - HUD_H) / 2},
	}

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)

		if rl.IsKeyPressed(.ONE) do tool = .Road
		if rl.IsKeyPressed(.TWO) do tool = .Residential
		if rl.IsKeyPressed(.THREE) do tool = .Commercial
		if rl.IsKeyPressed(.FOUR) do tool = .Bulldoze
		if rl.IsKeyPressed(.SPACE) do paused = !paused
		if rl.IsKeyPressed(.S) {
			city.city_save(c, city.SAVE_PATH)
		}
		if rl.IsKeyPressed(.L) {
			if loaded, ok := city.city_load(city.SAVE_PATH); ok {
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

		if rl.IsMouseButtonDown(.LEFT) && rl.GetMouseY() >= HUD_H {
			world := rl.GetScreenToWorld2D(rl.GetMousePosition(), cam)
			lot_x := int(math.floor(world.x / f32(LOT_PX)))
			lot_y := int(math.floor(world.y / f32(LOT_PX)))
			switch tool {
			case .Road:
				city.paint_road(&c, lot_x, lot_y)
			case .Residential:
				city.paint_zone(&c, lot_x, lot_y, .Residential)
			case .Commercial:
				city.paint_zone(&c, lot_x, lot_y, .Commercial)
			case .Bulldoze:
				city.bulldoze(&c, lot_x, lot_y)
			}
		}

		if !paused {
			tick_acc += rl.GetFrameTime()
			for tick_acc >= TICK_DT {
				tick_acc -= TICK_DT
				city.tick(&c, pick)
			}
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.DARKGREEN)
		rl.BeginMode2D(cam)
		for y in 0 ..< city.MAP_SIZE {
			for x in 0 ..< city.MAP_SIZE {
				rl.DrawRectangle(
					i32(x * LOT_PX),
					i32(y * LOT_PX),
					LOT_PX,
					LOT_PX,
					lot_color(c, x, y),
				)
			}
		}
		rl.EndMode2D()
		draw_hud(c, paused, tool)
		rl.EndDrawing()
	}
}

pick :: proc(n: int) -> int {
	return rand.int_max(n)
}

lot_color :: proc(c: city.City, x, y: int) -> rl.Color {
	lot := city.city_lot(c, x, y)
	if lot.kind == .Road {
		return rl.GRAY
	}
	if kind, ok := city.building_kind_at(c, x, y); ok {
		switch kind {
		case .House:
			return rl.GREEN
		case .Shop:
			return rl.BLUE
		}
	}
	switch lot.zone {
	case .Residential:
		return rl.Color{160, 210, 160, 255}
	case .Commercial:
		return rl.Color{150, 180, 230, 255}
	case .None:
		switch lot.terrain {
		case .Grass:
			return rl.Color{40, 90, 40, 255}
		case .Lake:
			return rl.Color{30, 90, 160, 255}
		case .Forest:
			return rl.Color{20, 70, 25, 255}
		case .Rock:
			return rl.Color{110, 105, 95, 255}
		}
	}
	return rl.MAGENTA
}

draw_hud :: proc(c: city.City, paused: bool, tool: Tool) {
	rl.DrawRectangle(0, 0, WIN_W, HUD_H, rl.BLACK)
	line1 := fmt.ctprintf(
		"$%d   pop %d   jobs %d   R %d   C %d",
		city.city_money(c),
		city.city_population(c),
		city.city_jobs(c),
		city.city_residential_demand(c),
		city.city_commercial_demand(c),
	)
	run := "PAUSED" if paused else "RUNNING"
	line2 := fmt.ctprintf(
		"%s   %v    1-4 tools  space pause  S save  L load  wheel zoom  RMB pan",
		run,
		tool,
	)
	rl.DrawText(line1, 8, 8, 18, rl.WHITE)
	rl.DrawText(line2, 8, 36, 16, rl.LIGHTGRAY)
}
