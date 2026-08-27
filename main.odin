package main

import "core:fmt"
import "core:math/rand"
import city "./city"
import rl "vendor:raylib"

LOT_PX :: 16
HUD_H :: 64
TICK_DT :: 0.25

Tool :: enum {
	Road,
	Residential,
	Commercial,
	Bulldoze,
}

main :: proc() {
	w := i32(city.MAP_SIZE * LOT_PX)
	h := i32(city.MAP_SIZE * LOT_PX + HUD_H)
	rl.InitWindow(w, h, "Pocket City")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	c := city.city_new()
	paused := true
	tool := Tool.Road
	tick_acc: f32

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)

		if rl.IsKeyPressed(.ONE) do tool = .Road
		if rl.IsKeyPressed(.TWO) do tool = .Residential
		if rl.IsKeyPressed(.THREE) do tool = .Commercial
		if rl.IsKeyPressed(.FOUR) do tool = .Bulldoze
		if rl.IsKeyPressed(.SPACE) do paused = !paused

		if rl.IsMouseButtonDown(.LEFT) {
		lot_x := int(rl.GetMouseX()) / LOT_PX
		lot_y := (int(rl.GetMouseY()) - HUD_H) / LOT_PX
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
		draw_hud(c, paused, tool)
		for y in 0 ..< city.MAP_SIZE {
			for x in 0 ..< city.MAP_SIZE {
				lot := city.city_lot(c, x, y)
				rl.DrawRectangle(
					i32(x * LOT_PX),
					i32(HUD_H + y * LOT_PX),
					LOT_PX,
					LOT_PX,
					lot_color(lot),
				)
			}
		}
		rl.EndDrawing()
	}
}

pick :: proc(n: int) -> int {
	return rand.int_max(n)
}

lot_color :: proc(lot: city.Lot) -> rl.Color {
	if lot.kind == .Road {
		return rl.GRAY
	}
	switch lot.building {
	case .House:
		return rl.GREEN
	case .Shop:
		return rl.BLUE
	case .None:
		switch lot.zone {
		case .Residential:
			return rl.Color{160, 210, 160, 255}
		case .Commercial:
			return rl.Color{150, 180, 230, 255}
		case .None:
			return rl.Color{40, 90, 40, 255}
		}
	}
	return rl.MAGENTA
}

draw_hud :: proc(c: city.City, paused: bool, tool: Tool) {
	rl.DrawRectangle(0, 0, i32(city.MAP_SIZE * LOT_PX), HUD_H, rl.BLACK)
	line1 := fmt.ctprintf(
		"$%d   pop %d   jobs %d   R %d   C %d",
		city.city_money(c),
		city.city_population(c),
		city.city_jobs(c),
		city.city_residential_demand(c),
		city.city_commercial_demand(c),
	)
	run := "PAUSED" if paused else "RUNNING"
	line2 := fmt.ctprintf("%s   tool: %v    1 road  2 R  3 C  4 bulldoze  space pause", run, tool)
	rl.DrawText(line1, 8, 8, 18, rl.WHITE)
	rl.DrawText(line2, 8, 36, 16, rl.LIGHTGRAY)
}
