package window

import "core:fmt"
import "core:math"
import city "../city"
import rl "vendor:raylib"

MAP_W :: 960
MAP_H :: 560
LEFT_W :: 220
INSPECT_W :: 280
KEYS_H :: 36
WIN_W :: LEFT_W + MAP_W + INSPECT_W
WIN_H :: MAP_H + KEYS_H
LOT_PX :: 16

@(private)
HUD_FONT :: 18
@(private)
HUD_LINE :: 22
@(private)
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

Hover_Lot :: struct {
	x, y: int,
	ok:   bool,
}

on_hud :: proc(mx, my: f32) -> bool {
	return mx < LEFT_W || mx >= f32(LEFT_W + MAP_W) || my >= f32(MAP_H)
}

hover_lot :: proc(cam: rl.Camera2D) -> Hover_Lot {
	mouse := rl.GetMousePosition()
	if on_hud(mouse.x, mouse.y) {
		return {}
	}
	world := rl.GetScreenToWorld2D(mouse, cam)
	x := int(math.floor(world.x / f32(LOT_PX)))
	y := int(math.floor(world.y / f32(LOT_PX)))
	if x < 0 || y < 0 || x >= city.MAP_SIZE || y >= city.MAP_SIZE {
		return {}
	}
	return {x, y, true}
}

draw :: proc(
	c: ^city.City,
	cam: rl.Camera2D,
	overlay: Overlay,
	paused: bool,
	speed: int,
	tool: Tool,
	hover: Hover_Lot,
) {
	rl.BeginMode2D(cam)
	for y in 0 ..< city.MAP_SIZE {
		for x in 0 ..< city.MAP_SIZE {
			col := overlay_color(c, x, y, overlay) if overlay != .None else lot_base_color(c, x, y)
			rl.DrawRectangle(i32(x * LOT_PX), i32(y * LOT_PX), LOT_PX, LOT_PX, col)
		}
	}
	if overlay == .None {
		draw_stamps(c)
	}
	rl.EndMode2D()
	draw_hud(c, paused, speed, tool, overlay, hover)
}

@(private)
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
@(private)
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

@(private)
CONSTRUCTION_STAMP :: [16]u16 {
	0xFFFF, 0xC003, 0xA005, 0x9009,
	0x8811, 0x8421, 0x8241, 0x8181,
	0x8181, 0x8241, 0x8421, 0x8811,
	0x9009, 0xA005, 0xC003, 0xFFFF,
}

@(private)
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

@(private)
band_tint :: proc(c: ^city.City, x, y: int, col: rl.Color) -> (out: rl.Color, label: cstring) {
	if city.building_abandoned_at(c, x, y) {
		return rl.Color{90, 85, 80, 255}, "Abandoned"
	}
	if city.building_struggling_at(c, x, y) {
		return rl.Color{col.r / 2, col.g / 2, col.b / 2, 255}, "Struggling"
	}
	return col, ""
}

@(private)
stamp_color :: proc(c: ^city.City, x, y: int, kind: city.Building_Kind) -> (mask: [16]u16, col: rl.Color) {
	stamps := STAMP
	col = building_color(kind)
	mask = stamps[kind]
	if city.building_construction_at(c, x, y) {
		return CONSTRUCTION_STAMP, rl.Color{col.r / 3 + 90, col.g / 3 + 70, col.b / 3 + 30, 255}
	}
	col, _ = band_tint(c, x, y, col)
	return mask, col
}

@(private)
draw_stamps :: proc(c: ^city.City) {
	for y in 0 ..< city.MAP_SIZE {
		for x in 0 ..< city.MAP_SIZE {
			size, nw := city.building_northwest_at(c, x, y)
			if !nw {
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

@(private)
lot_base_color :: proc(c: ^city.City, x, y: int) -> rl.Color {
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

@(private)
overlay_color :: proc(c: ^city.City, x, y: int, overlay: Overlay) -> rl.Color {
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
	return lot_base_color(c, x, y)
}

@(private)
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

@(private)
hud_line :: proc(x: i32, y: ^i32, text: cstring, col := rl.WHITE) {
	rl.DrawText(text, x, y^, HUD_FONT, col)
	y^ += HUD_LINE
}

@(private)
draw_hud :: proc(c: ^city.City, paused: bool, speed: int, tool: Tool, overlay: Overlay, hover: Hover_Lot) {
	rl.DrawRectangle(0, 0, LEFT_W, MAP_H, rl.BLACK)
	rl.DrawRectangle(i32(LEFT_W + MAP_W), 0, INSPECT_W, MAP_H, rl.BLACK)
	rl.DrawRectangle(0, MAP_H, WIN_W, KEYS_H, rl.BLACK)

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

	draw_graphs(c, 8, MAP_H - (4 * GRAPH_ROW + 8), LEFT_W - 16)
	if hover.ok {
		draw_inspect(c, hover.x, hover.y)
	}
	rl.DrawText(
		"1-5 paint  6-0 F H stamp  P W O V E T C I overlay  [ ] tax  -/= speed  space pause  S/L save",
		8,
		MAP_H + 8,
		HUD_FONT,
		rl.LIGHTGRAY,
	)
}

@(private)
draw_inspect :: proc(c: ^city.City, x, y: int) {
	lot := city.city_lot(c, x, y)
	ix: i32 = i32(LEFT_W + MAP_W) + 8
	iy: i32 = 8
	hud_line(ix, &iy, fmt.ctprintf("Terrain %v", lot.terrain))
	hud_line(ix, &iy, fmt.ctprintf("%v", lot.kind))
	hud_line(ix, &iy, fmt.ctprintf("Zone %v", lot.zone))
	if kind, ok := city.building_kind_at(c, x, y); ok {
		hud_line(ix, &iy, fmt.ctprintf("%v", kind))
		if city.building_construction_at(c, x, y) {
			rem, _ := city.building_construction_remaining_at(c, x, y)
			hud_line(ix, &iy, fmt.ctprintf("Construction %d", rem))
		} else {
			level, _ := city.building_level_at(c, x, y)
			if level >= 1 {
				hud_line(ix, &iy, fmt.ctprintf("Level %d", level))
			}
			_, label := band_tint(c, x, y, rl.WHITE)
			if label != "" {
				hud_line(ix, &iy, label)
			}
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

@(private)
Graph :: enum {
	Population,
	Jobs,
	Money,
	Happiness,
}

@(private)
Graph_Look :: struct {
	label: cstring,
	color: rl.Color,
}

@(private)
GRAPH_LOOK :: [Graph]Graph_Look {
	.Population = {"Population", rl.GREEN},
	.Jobs       = {"Jobs", rl.SKYBLUE},
	.Money      = {"Money", rl.GOLD},
	.Happiness  = {"Happiness", rl.PINK},
}

@(private)
graph_value :: proc(p: city.Graph_Point, g: Graph) -> f32 {
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

@(private)
draw_graphs :: proc(c: ^city.City, x, y, w: i32) {
	n := city.city_graph_len(c)
	looks := GRAPH_LOOK
	for g in Graph {
		row := i32(g)
		gy := y + row * GRAPH_ROW
		look := looks[g]
		rl.DrawText(look.label, x, gy, 14, look.color)
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
		if n == 1 {
			p := graph_value(city.city_graph_at(c, 0), g) / hi
			rl.DrawPixel(x0, line_y + h - i32(p * f32(h)), look.color)
			continue
		}
		for i in 1 ..< n {
			a := graph_value(city.city_graph_at(c, i - 1), g) / hi
			b := graph_value(city.city_graph_at(c, i), g) / hi
			x1 := x0 + i32(f32(w) * f32(i - 1) / f32(n - 1))
			x2 := x0 + i32(f32(w) * f32(i) / f32(n - 1))
			y1 := line_y + h - i32(a * f32(h))
			y2 := line_y + h - i32(b * f32(h))
			rl.DrawLine(x1, y1, x2, y2, look.color)
		}
	}
}
