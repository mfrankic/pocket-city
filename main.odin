package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import city "./city"
import hud "./hud"
import rl "vendor:raylib"

LOT_PX :: 16
TICK_DT :: 0.25
HUD_FONT :: 18
HUD_LINE :: 22
GRAPH_ROW :: 44

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
	rl.InitWindow(hud.WIN_W, hud.WIN_H, "Pocket City")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	c := city.city_new()
	defer free(c)
	paused := true
	speed := 1
	tool := Tool.Road
	overlay := Overlay.None
	tick_acc: f32
	cam := rl.Camera2D {
		zoom   = 1,
		target = {f32(city.MAP_SIZE * LOT_PX) / 2, f32(city.MAP_SIZE * LOT_PX) / 2},
		offset = {f32(hud.LEFT_W) + f32(hud.MAP_W) / 2, f32(hud.MAP_H) / 2},
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

		hover_x, hover_y, hover_ok := hover_lot(cam)
		if rl.IsMouseButtonDown(.LEFT) && hover_ok {
			switch tool {
			case .Road:
				city.paint_road(c, hover_x, hover_y)
			case .Residential:
				city.paint_zone(c, hover_x, hover_y, .Residential)
			case .Commercial:
				city.paint_zone(c, hover_x, hover_y, .Commercial)
			case .Industrial:
				city.paint_zone(c, hover_x, hover_y, .Industrial)
			case .Bulldoze:
				city.bulldoze(c, hover_x, hover_y)
			case .Station:
				size := 2 if rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT) else 1
				city.stamp(c, hover_x, hover_y, .Station, size)
			case .Tower:
				city.stamp(c, hover_x, hover_y, .Tower)
			case .Park:
				city.stamp(c, hover_x, hover_y, .Park)
			case .School:
				city.stamp(c, hover_x, hover_y, .School)
			case .Police:
				city.stamp(c, hover_x, hover_y, .Police)
			case .Firehouse:
				city.stamp(c, hover_x, hover_y, .Firehouse)
			case .Hospital:
				city.stamp(c, hover_x, hover_y, .Hospital)
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
		rl.BeginMode2D(cam)
		for y in 0 ..< city.MAP_SIZE {
			for x in 0 ..< city.MAP_SIZE {
				col := ground_color(c, x, y) if overlay == .None else lot_color(c, x, y, overlay)
				rl.DrawRectangle(i32(x * LOT_PX), i32(y * LOT_PX), LOT_PX, LOT_PX, col)
			}
		}
		if overlay == .None {
			draw_stamps(c)
		}
		rl.EndMode2D()
		draw_hud(c, paused, speed, tool, overlay, hover_x, hover_y, hover_ok)
		rl.EndDrawing()
	}
}

pick :: proc(n: int) -> int {
	return rand.int_max(n)
}

hover_lot :: proc(cam: rl.Camera2D) -> (x, y: int, ok: bool) {
	mouse := rl.GetMousePosition()
	if hud.on_hud(mouse.x, mouse.y) {
		return 0, 0, false
	}
	world := rl.GetScreenToWorld2D(mouse, cam)
	x = int(math.floor(world.x / f32(LOT_PX)))
	y = int(math.floor(world.y / f32(LOT_PX)))
	if x < 0 || y < 0 || x >= city.MAP_SIZE || y >= city.MAP_SIZE {
		return 0, 0, false
	}
	return x, y, true
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

// 16×16 templates, bit 15 is the left pixel. Scaled to the occupancy rectangle.
STAMP :: [city.Building_Kind][16]u16 {
	.House = {
		0x03C0, 0x07E0, 0x0FF0, 0x1FF8,
		0x3FFC, 0x7FFE, 0xFFFF, 0xE7E7,
		0xE3C7, 0xE187, 0xE007, 0xE7E7,
		0xE7E7, 0xE7E7, 0xE007, 0xFFFF,
	},
	.Shop = {
		0x1FF8, 0x2AAC, 0x5556, 0xFFFF,
		0xC003, 0xCFF3, 0xCFF3, 0xCC33,
		0xCC33, 0xCFF3, 0xC003, 0xC003,
		0xCFF3, 0xCFF3, 0xC003, 0xFFFF,
	},
	.Factory = {
		0x1818, 0x1818, 0x1818, 0x1818,
		0x6666, 0xFFFF, 0xFFFF, 0xC303,
		0xC303, 0xFFFF, 0xC003, 0xCFF3,
		0xCFF3, 0xC003, 0xFFFF, 0xFFFF,
	},
	.Station = {
		0x0180, 0x03C0, 0x0180, 0x07E0,
		0x3FFC, 0x7FFE, 0xF3CF, 0xF3CF,
		0xFFFF, 0xF00F, 0xF7EF, 0xF7EF,
		0xF00F, 0xFFFF, 0x300C, 0x300C,
	},
	.Tower = {
		0x07E0, 0x07E0, 0x03C0, 0x0180,
		0x0180, 0x07E0, 0x07E0, 0x0180,
		0x0180, 0x07E0, 0x0FF0, 0x1FF8,
		0x3FFC, 0x7FFE, 0x07E0, 0x0FF0,
	},
	.Park = {
		0x03C0, 0x07E0, 0x0FF0, 0x1FF8,
		0x0FF0, 0x1FF8, 0x3FFC, 0x1FF8,
		0x0FF0, 0x0180, 0x0180, 0x0180,
		0x0180, 0x07E0, 0x0FF0, 0x3FFC,
	},
	.School = {
		0x0800, 0x0F00, 0x0F00, 0x0800,
		0x0800, 0x3FFC, 0x7FFE, 0x63C6,
		0x63C6, 0x7FFE, 0x6006, 0x67E6,
		0x67E6, 0x6006, 0x7FFE, 0xFFFF,
	},
	.Police = {
		0x0180, 0x03C0, 0x07E0, 0x0DB0,
		0x07E0, 0x03C0, 0x3FFC, 0x7FFE,
		0x6006, 0x67E6, 0x6006, 0x7FFE,
		0x63C6, 0x63C6, 0x7FFE, 0xFFFF,
	},
	.Firehouse = {
		0x1818, 0x1818, 0xFFFF, 0xFFFF,
		0xC003, 0xDFFB, 0xD00B, 0xD7EB,
		0xD00B, 0xDFFB, 0xC003, 0xFFFF,
		0xCC33, 0xCC33, 0xCC33, 0xFFFF,
	},
	.Hospital = {
		0x03C0, 0x03C0, 0x03C0, 0x3FFC,
		0x3FFC, 0x3FFC, 0x03C0, 0x03C0,
		0x3FFC, 0x7FFE, 0x6006, 0x67E6,
		0x67E6, 0x6006, 0x7FFE, 0xFFFF,
	},
}

CONSTRUCTION_STAMP :: [16]u16 {
	0xFFFF, 0xC003, 0xA005, 0x9009,
	0x8811, 0x8421, 0x8241, 0x8181,
	0x8181, 0x8241, 0x8421, 0x8811,
	0x9009, 0xA005, 0xC003, 0xFFFF,
}

stamp_footprint :: proc(c: ^city.City, x, y: int) -> (size: int, ok: bool) {
	id := city.city_lot(c, x, y).building_id
	if id == 0 {
		return 0, false
	}
	if x > 0 && city.city_lot(c, x - 1, y).building_id == id {
		return 0, false
	}
	if y > 0 && city.city_lot(c, x, y - 1).building_id == id {
		return 0, false
	}
	size = 1
	if x + 1 < city.MAP_SIZE && y + 1 < city.MAP_SIZE {
		if city.city_lot(c, x + 1, y).building_id == id && city.city_lot(c, x, y + 1).building_id == id {
			size = 2
		}
	}
	return size, true
}

draw_stamp :: proc(ox, oy, scale: i32, mask: [16]u16, col: rl.Color) {
	for row in 0 ..< 16 {
		bits := mask[row]
		for px in 0 ..< 16 {
			if bits & (u16(0x8000) >> u16(px)) != 0 {
				rl.DrawRectangle(ox + i32(px) * scale, oy + i32(row) * scale, scale, scale, col)
			}
		}
	}
}

stamp_color :: proc(c: ^city.City, x, y: int, kind: city.Building_Kind) -> (mask: [16]u16, col: rl.Color) {
	stamps := STAMP
	col = building_color(kind)
	mask = stamps[kind]
	if rem, rok := city.building_construction_remaining_at(c, x, y); rok && rem > 0 {
		return CONSTRUCTION_STAMP, rl.Color{col.r / 3 + 90, col.g / 3 + 70, col.b / 3 + 30, 255}
	}
	if h, hok := city.building_health_at(c, x, y); hok {
		if h <= city.HEALTH_ABANDONED {
			return mask, rl.Color{90, 85, 80, 255}
		}
		if h < city.HEALTH_STRUGGLING {
			return mask, rl.Color{col.r / 2, col.g / 2, col.b / 2, 255}
		}
	}
	return mask, col
}

draw_stamps :: proc(c: ^city.City) {
	for y in 0 ..< city.MAP_SIZE {
		for x in 0 ..< city.MAP_SIZE {
			size, origin := stamp_footprint(c, x, y)
			if !origin {
				continue
			}
			kind, kok := city.building_kind_at(c, x, y)
			if !kok {
				continue
			}
			mask, col := stamp_color(c, x, y, kind)
			draw_stamp(i32(x * LOT_PX), i32(y * LOT_PX), i32(size), mask, col)
		}
	}
}

ground_color :: proc(c: ^city.City, x, y: int) -> rl.Color {
	lot := city.city_lot(c, x, y)
	if lot.kind == .Road {
		return rl.GRAY
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

lot_color :: proc(c: ^city.City, x, y: int, overlay: Overlay) -> rl.Color {
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
	if kind, ok := city.building_kind_at(c, x, y); ok {
		_, col := stamp_color(c, x, y, kind)
		return col
	}
	return ground_color(c, x, y)
}

overlay_label :: proc(o: Overlay) -> string {
	switch o {
	case .None:
		return "None"
	case .Power:
		return "Power"
	case .Water:
		return "Water"
	case .Pollution:
		return "Pollution"
	case .Land_Value:
		return "Land value"
	case .Education:
		return "Education"
	case .Traffic:
		return "Traffic"
	case .Crime:
		return "Crime"
	case .Fire:
		return "Fire"
	}
	return "?"
}

hud_line :: proc(x: i32, y: ^i32, text: cstring, col := rl.WHITE) {
	rl.DrawText(text, x, y^, HUD_FONT, col)
	y^ += HUD_LINE
}

draw_hud :: proc(c: ^city.City, paused: bool, speed: int, tool: Tool, overlay: Overlay, hover_x, hover_y: int, hover_ok: bool) {
	rl.DrawRectangle(0, 0, hud.LEFT_W, hud.MAP_H, rl.BLACK)
	rl.DrawRectangle(i32(hud.LEFT_W + hud.MAP_W), 0, hud.INSPECT_W, hud.MAP_H, rl.BLACK)
	rl.DrawRectangle(0, hud.MAP_H, hud.WIN_W, hud.KEYS_H, rl.BLACK)

	x: i32 = 8
	y: i32 = 8
	hud_line(x, &y, fmt.ctprintf("Money %d", city.city_money(c)))
	hud_line(x, &y, fmt.ctprintf("Population %d", city.city_population(c)))
	hud_line(x, &y, fmt.ctprintf("Jobs %d", city.city_jobs(c)))
	hud_line(x, &y, "Demand")
	hud_line(x, &y, fmt.ctprintf("R %d  C %d  I %d", city.city_residential_demand(c), city.city_commercial_demand(c), city.city_industrial_demand(c)))
	hud_line(x, &y, fmt.ctprintf("Tax %d", city.city_tax(c)))
	hud_line(x, &y, fmt.ctprintf("Happiness %d", int(city.city_happiness(c) * 100)))
	hud_line(x, &y, fmt.ctprintf("Power %d", int(city.city_power_percent(c) * 100)))
	hud_line(x, &y, fmt.ctprintf("Water %d", int(city.city_water_percent(c) * 100)))
	hud_line(x, &y, fmt.ctprintf("%d/%d/%d %02dh", city.city_year(c), city.city_month(c), city.city_day(c), city.city_hour(c)))
	run := "Paused" if paused else "Running"
	hud_line(x, &y, fmt.ctprintf("%s %dx", run, speed))
	hud_line(x, &y, fmt.ctprintf("Tool %v", tool))
	hud_line(x, &y, fmt.ctprintf("Overlay %s", overlay_label(overlay)))

	draw_graphs(c, 8, hud.MAP_H - (4 * GRAPH_ROW + 8), hud.LEFT_W - 16)
	if hover_ok {
		draw_inspect(c, hover_x, hover_y)
	}
	rl.DrawText(
		"1-5 paint  6-0 F H stamp  P W O V E T C I overlay  [ ] tax  -/= speed  space pause  S/L save",
		8,
		hud.MAP_H + 8,
		HUD_FONT,
		rl.LIGHTGRAY,
	)
}

draw_inspect :: proc(c: ^city.City, x, y: int) {
	lot := city.city_lot(c, x, y)
	ix: i32 = i32(hud.LEFT_W + hud.MAP_W) + 8
	iy: i32 = 8
	hud_line(ix, &iy, fmt.ctprintf("Terrain %v", lot.terrain))
	hud_line(ix, &iy, fmt.ctprintf("%v", lot.kind))
	hud_line(ix, &iy, fmt.ctprintf("Zone %v", lot.zone))
	if kind, ok := city.building_kind_at(c, x, y); ok {
		hud_line(ix, &iy, fmt.ctprintf("%v", kind))
		rem, _ := city.building_construction_remaining_at(c, x, y)
		if rem > 0 {
			hud_line(ix, &iy, fmt.ctprintf("Construction %d", rem))
		} else {
			level, _ := city.building_level_at(c, x, y)
			health, _ := city.building_health_at(c, x, y)
			if level >= 1 {
				hud_line(ix, &iy, fmt.ctprintf("Level %d", level))
			}
			hud_line(ix, &iy, fmt.ctprintf("Health %.2f", health))
		}
	}
	hud_line(ix, &iy, fmt.ctprintf("Power %s", "Yes" if city.lot_powered(c, x, y) else "No"))
	hud_line(ix, &iy, fmt.ctprintf("Water %s", "Yes" if city.lot_watered(c, x, y) else "No"))
	hud_line(ix, &iy, fmt.ctprintf("Pollution %.2f", city.lot_pollution(c, x, y)))
	hud_line(ix, &iy, fmt.ctprintf("Land value %.2f", city.lot_land_value(c, x, y)))
	hud_line(ix, &iy, fmt.ctprintf("Traffic %.2f", city.lot_traffic(c, x, y)))
	hud_line(ix, &iy, fmt.ctprintf("Crime %.2f", city.lot_crime(c, x, y)))
	hud_line(ix, &iy, fmt.ctprintf("Fire %.2f", city.lot_fire(c, x, y)))
	hud_line(ix, &iy, fmt.ctprintf("Education %s", "Yes" if city.lot_education(c, x, y) else "No"))
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
		return "Population"
	case .Jobs:
		return "Jobs"
	case .Money:
		return "Money"
	case .Happiness:
		return "Happiness"
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

draw_graphs :: proc(c: ^city.City, x, y, w: i32) {
	n := city.city_graph_len(c)
	for g in Hud_Graph {
		row := i32(g)
		gy := y + row * GRAPH_ROW
		rl.DrawText(graph_label(g), x, gy, 14, graph_color(g))
		if n == 0 {
			continue
		}
		hi: f32 = 1
		for i in 0 ..< n {
			hi = max(hi, graph_value(city.city_graph_at(c, i), g))
		}
		x0 := x
		line_y := gy + 16
		h: i32 = 22
		col := graph_color(g)
		if n == 1 {
			p := graph_value(city.city_graph_at(c, 0), g) / hi
			rl.DrawPixel(x0, line_y + h - i32(p * f32(h)), col)
			continue
		}
		for i in 1 ..< n {
			a := graph_value(city.city_graph_at(c, i - 1), g) / hi
			b := graph_value(city.city_graph_at(c, i), g) / hi
			x1 := x0 + i32(f32(w) * f32(i - 1) / f32(n - 1))
			x2 := x0 + i32(f32(w) * f32(i) / f32(n - 1))
			y1 := line_y + h - i32(a * f32(h))
			y2 := line_y + h - i32(b * f32(h))
			rl.DrawLine(x1, y1, x2, y2, col)
		}
	}
}
