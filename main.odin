package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import city "./city"
import rl "vendor:raylib"

LOT_PX :: 16
HUD_H :: 80
WIN_W :: 960
WIN_H :: 640
TICK_DT :: 0.25
GRAPH_X :: 740
GRAPH_W :: 208

Tool :: enum {
	Road,
	Residential,
	Commercial,
	Industrial,
	Bulldoze,
	Station,
	Tower,
	Park,
	School,
	Police,
	Firehouse,
	Hospital,
}

Overlay :: enum {
	None,
	Power,
	Water,
	Pollution,
	Land_Value,
	Education,
	Traffic,
	Crime,
	Fire,
}

main :: proc() {
	rl.InitWindow(WIN_W, WIN_H, "Pocket City")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	c := city.city_new()
	paused := true
	tool := Tool.Road
	overlay := Overlay.None
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
		if rl.IsKeyPressed(.LEFT_BRACKET) do city.city_set_tax(&c, city.city_tax(c) - 1)
		if rl.IsKeyPressed(.RIGHT_BRACKET) do city.city_set_tax(&c, city.city_tax(c) + 1)
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
			case .Industrial:
				city.paint_zone(&c, lot_x, lot_y, .Industrial)
			case .Bulldoze:
				city.bulldoze(&c, lot_x, lot_y)
			case .Station:
				size := 2 if rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT) else 1
				city.stamp(&c, lot_x, lot_y, .Station, size)
			case .Tower:
				city.stamp(&c, lot_x, lot_y, .Tower)
			case .Park:
				city.stamp(&c, lot_x, lot_y, .Park)
			case .School:
				city.stamp(&c, lot_x, lot_y, .School)
			case .Police:
				city.stamp(&c, lot_x, lot_y, .Police)
			case .Firehouse:
				city.stamp(&c, lot_x, lot_y, .Firehouse)
			case .Hospital:
				city.stamp(&c, lot_x, lot_y, .Hospital)
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
					lot_color(c, x, y, overlay),
				)
			}
		}
		rl.EndMode2D()
		draw_hud(c, paused, tool, overlay)
		rl.EndDrawing()
	}
}

pick :: proc(n: int) -> int {
	return rand.int_max(n)
}

building_color :: proc(kind: city.Building_Kind) -> rl.Color {
	switch kind {
	case .House:
		return rl.GREEN
	case .Shop:
		return rl.BLUE
	case .Factory:
		return rl.Color{200, 160, 40, 255}
	case .Station:
		return rl.Color{220, 200, 80, 255}
	case .Tower:
		return rl.Color{70, 130, 200, 255}
	case .Park:
		return rl.Color{80, 170, 70, 255}
	case .School:
		return rl.Color{180, 140, 60, 255}
	case .Police:
		return rl.Color{60, 80, 180, 255}
	case .Firehouse:
		return rl.Color{200, 70, 50, 255}
	case .Hospital:
		return rl.WHITE
	}
	return rl.MAGENTA
}

lot_color :: proc(c: city.City, x, y: int, overlay: Overlay) -> rl.Color {
	lot := city.city_lot(c, x, y)
	switch overlay {
	case .Pollution:
		p := clamp(city.lot_pollution(c, x, y), 0, 1)
		return rl.Color{u8(40 + 170 * p), u8(35 + 50 * p), u8(20), 255}
	case .Traffic:
		if lot.kind == .Road {
			p := clamp(city.lot_traffic(c, x, y), 0, 1)
			return rl.Color{u8(40 + 180 * p), u8(40 + 40 * p), u8(40), 255}
		}
	case .Crime:
		p := clamp(city.lot_crime(c, x, y) / 4, 0, 1)
		return rl.Color{u8(40 + 160 * p), u8(20 + 20 * p), u8(50 + 80 * p), 255}
	case .Fire:
		p := clamp(city.lot_fire(c, x, y), 0, 1)
		return rl.Color{u8(40 + 200 * p), u8(20), u8(10), 255}
	case .Land_Value:
		v := clamp(city.lot_land_value(c, x, y) / 3, 0, 1)
		return rl.Color{u8(30 + 40 * v), u8(50 + 140 * v), u8(40 + 50 * v), 255}
	case .Education:
		if lot.kind != .Road {
			return rl.Color{220, 200, 80, 255} if city.lot_education(c, x, y) else rl.Color{20, 20, 20, 255}
		}
	case .Power:
		if lot.kind != .Road {
			return rl.GOLD if city.lot_powered(c, x, y) else rl.Color{20, 20, 20, 255}
		}
	case .Water:
		if lot.kind != .Road {
			return rl.SKYBLUE if city.lot_watered(c, x, y) else rl.Color{20, 20, 20, 255}
		}
	case .None:
	}
	if lot.kind == .Road {
		return rl.GRAY
	}
	if kind, ok := city.building_kind_at(c, x, y); ok {
		col := building_color(kind)
		if rem, rok := city.building_construction_remaining_at(c, x, y); rok && rem > 0 {
			return rl.Color{col.r / 3 + 90, col.g / 3 + 70, col.b / 3 + 30, 255}
		}
		if h, ok := city.building_health_at(c, x, y); ok {
			if h <= city.HEALTH_ABANDONED {
				return rl.Color{90, 85, 80, 255}
			}
			if h < city.HEALTH_STRUGGLING {
				return rl.Color{col.r / 2, col.g / 2, col.b / 2, 255}
			}
		}
		return col
	}
	switch lot.zone {
	case .Residential:
		return rl.Color{160, 210, 160, 255}
	case .Commercial:
		return rl.Color{150, 180, 230, 255}
	case .Industrial:
		return rl.Color{200, 190, 120, 255}
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

draw_hud :: proc(c: city.City, paused: bool, tool: Tool, overlay: Overlay) {
	rl.DrawRectangle(0, 0, WIN_W, HUD_H, rl.BLACK)
	outage := "  OUTAGE" if city.city_outage(c) else ""
	line1 := fmt.ctprintf(
		"$%d  pop %d  jobs %d  R %d  C %d  I %d  tax %d  hap %d",
		city.city_money(c),
		city.city_population(c),
		city.city_jobs(c),
		city.city_residential_demand(c),
		city.city_commercial_demand(c),
		city.city_industrial_demand(c),
		city.city_tax(c),
		int(city.city_happiness(c) * 100),
	)
	run := "PAUSED" if paused else "RUNNING"
	line2 := fmt.ctprintf(
		"%d/%d/%d %02dh%s  %s  %v  overlay %v  1-5 paint  6-0 F H stamp  P/W/O/V/E/T/C/I  [ ] tax  space  S/L",
		city.city_year(c),
		city.city_month(c),
		city.city_day(c),
		city.city_hour(c),
		outage,
		run,
		tool,
		overlay,
	)
	rl.DrawText(line1, 8, 8, 16, rl.WHITE)
	rl.DrawText(line2, 8, 32, 14, rl.LIGHTGRAY)
	draw_graphs(c)
}

Hud_Graph :: enum {
	Population,
	Jobs,
	Money,
	Happiness,
}

graph_value :: proc(p: city.Graph_Point, g: Hud_Graph) -> f32 {
	switch g {
	case .Population:
		return f32(p.population)
	case .Jobs:
		return f32(p.jobs)
	case .Money:
		return f32(p.money)
	case .Happiness:
		return p.happiness
	}
	return 0
}

graph_label :: proc(g: Hud_Graph) -> cstring {
	switch g {
	case .Population:
		return "P"
	case .Jobs:
		return "J"
	case .Money:
		return "$"
	case .Happiness:
		return "H"
	}
	return "?"
}

graph_color :: proc(g: Hud_Graph) -> rl.Color {
	switch g {
	case .Population:
		return rl.GREEN
	case .Jobs:
		return rl.SKYBLUE
	case .Money:
		return rl.GOLD
	case .Happiness:
		return rl.PINK
	}
	return rl.WHITE
}

draw_graphs :: proc(c: city.City) {
	n := city.city_graph_len(c)
	row_h: i32 = 16
	for g in Hud_Graph {
		row := i32(g)
		y := 8 + row * row_h
		rl.DrawText(graph_label(g), GRAPH_X, y, 10, graph_color(g))
		if n == 0 {
			continue
		}
		hi: f32 = 1
		for i in 0 ..< n {
			hi = max(hi, graph_value(city.city_graph_at(c, i), g))
		}
		x0: i32 = GRAPH_X + 12
		w: i32 = GRAPH_W - 16
		h: i32 = row_h - 4
		col := graph_color(g)
		if n == 1 {
			p := graph_value(city.city_graph_at(c, 0), g) / hi
			rl.DrawPixel(x0, y + h - i32(p * f32(h)), col)
			continue
		}
		for i in 1 ..< n {
			a := graph_value(city.city_graph_at(c, i - 1), g) / hi
			b := graph_value(city.city_graph_at(c, i), g) / hi
			x1 := x0 + i32(f32(w) * f32(i - 1) / f32(n - 1))
			x2 := x0 + i32(f32(w) * f32(i) / f32(n - 1))
			y1 := y + h - i32(a * f32(h))
			y2 := y + h - i32(b * f32(h))
			rl.DrawLine(x1, y1, x2, y2, col)
		}
	}
}
