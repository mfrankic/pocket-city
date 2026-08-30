package main

import "core:fmt"
import "core:math/rand"
import "core:os"
import city "../city"

SEED :: u64(1)
TRIALS :: 100
MONTHS :: 24
TICKS :: MONTHS * city.MONTH_TICKS

CARDINAL :: [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

main :: proc() {
	rand.reset(SEED)
	alive, husk, broke, outage: int
	sum_pop, sum_jobs, sum_money: int
	for _ in 0 ..< TRIALS {
		c := city.city_new()
		if !tiny_opener(c) {
			fmt.eprintf("tiny opener failed to boot\n")
			os.exit(1)
		}
		saw_outage := false
		for _ in 0 ..< TICKS {
			city.tick(c, pick)
			if city.city_outage(c) {
				saw_outage = true
			}
		}
		if city.city_population(c) > 0 {
			alive += 1
		}
		if abandoned_house(c) {
			husk += 1
		}
		if city.city_money(c) == 0 {
			broke += 1
		}
		if saw_outage {
			outage += 1
		}
		sum_pop += city.city_population(c)
		sum_jobs += city.city_jobs(c)
		sum_money += city.city_money(c)
		free(c)
	}
	fmt.printf("playtest seed=%v trials=%d months=%d\n", SEED, TRIALS, MONTHS)
	fmt.println("tiny opener: road + station + tower + 2R + 2C, tax 1")
	rate("population > 0", alive)
	rate("abandoned house", husk)
	rate("money 0", broke)
	rate("saw outage", outage)
	fmt.printf("  mean population    %.1f\n", f64(sum_pop) / TRIALS)
	fmt.printf("  mean jobs          %.1f\n", f64(sum_jobs) / TRIALS)
	fmt.printf("  mean money         %.1f\n", f64(sum_money) / TRIALS)
}

pick :: proc(n: int) -> int {
	return rand.int_max(n)
}

rate :: proc(label: string, n: int) {
	fmt.printf("  %-18s %d/%d (%d%%)\n", label, n, TRIALS, n * 100 / TRIALS)
}

tiny_opener :: proc(c: ^city.City) -> bool {
	p, ok := supplied_plots(c, 4)
	if !ok {
		return false
	}
	return city.paint_zone(c, p[0][0], p[0][1], .Residential) &&
		city.paint_zone(c, p[1][0], p[1][1], .Residential) &&
		city.paint_zone(c, p[2][0], p[2][1], .Commercial) &&
		city.paint_zone(c, p[3][0], p[3][1], .Commercial)
}

abandoned_house :: proc(c: ^city.City) -> bool {
	for y in 0 ..< city.MAP_SIZE {
		for x in 0 ..< city.MAP_SIZE {
			occ := city.city_lot(c, x, y).occupant
			if occ.present && occ.kind == .House && occ.band == .Abandoned {
				return true
			}
		}
	}
	return false
}

supplied_plots :: proc(c: ^city.City, n: int) -> (out: [8][2]int, ok: bool) {
	lx, ly, lake := find_terrain(c, .Lake)
	if !lake {
		return
	}
	tx, ty, grass := find_cardinal_grass(c, lx, ly)
	if !grass {
		return
	}
	if !paint_access_road(c, tx, ty) {
		return
	}
	if !city.stamp(c, tx, ty, .Tower) {
		return
	}
	rx, ry, road := find_cardinal_road(c, tx, ty)
	if !road {
		return
	}
	sx, sy, plot := find_empty_cardinal_plot(c, rx, ry)
	if !plot {
		return
	}
	if !city.stamp(c, sx, sy, .Station) {
		return
	}
	for dy in 1 ..= n + 2 {
		ny := ry + dy
		if ny >= city.MAP_SIZE {
			break
		}
		if is_empty_grass(c, rx, ny) {
			city.paint_road(c, rx, ny)
		}
	}
	count := 0
	for y in 0 ..< city.MAP_SIZE {
		for x in 0 ..< city.MAP_SIZE {
			if count >= n {
				return out, true
			}
			if !is_empty_grass(c, x, y) {
				continue
			}
			lot := city.city_lot(c, x, y)
			if !lot.powered || !lot.watered {
				continue
			}
			if !plot_touches_road(c, x, y) {
				continue
			}
			out[count] = {x, y}
			count += 1
		}
	}
	return out, count >= n
}

find_terrain :: proc(c: ^city.City, want: city.Terrain) -> (x, y: int, ok: bool) {
	for y in 0 ..< city.MAP_SIZE {
		for x in 0 ..< city.MAP_SIZE {
			if city.city_lot(c, x, y).terrain == want {
				return x, y, true
			}
		}
	}
	return
}

find_cardinal_grass :: proc(c: ^city.City, x, y: int) -> (gx, gy: int, ok: bool) {
	for n in CARDINAL {
		nx, ny := x + n[0], y + n[1]
		if !in_bounds(nx, ny) {
			continue
		}
		lot := city.city_lot(c, nx, ny)
		if lot.kind == .Plot && lot.terrain == .Grass {
			return nx, ny, true
		}
	}
	return
}

find_cardinal_road :: proc(c: ^city.City, x, y: int) -> (rx, ry: int, ok: bool) {
	for n in CARDINAL {
		nx, ny := x + n[0], y + n[1]
		if in_bounds(nx, ny) && city.city_lot(c, nx, ny).kind == .Road {
			return nx, ny, true
		}
	}
	return
}

find_empty_cardinal_plot :: proc(c: ^city.City, x, y: int) -> (px, py: int, ok: bool) {
	for n in CARDINAL {
		nx, ny := x + n[0], y + n[1]
		if is_empty_grass(c, nx, ny) {
			return nx, ny, true
		}
	}
	return
}

paint_access_road :: proc(c: ^city.City, x, y: int) -> bool {
	nx, ny, ok := find_cardinal_grass(c, x, y)
	return ok && city.paint_road(c, nx, ny)
}

plot_touches_road :: proc(c: ^city.City, x, y: int) -> bool {
	for n in CARDINAL {
		nx, ny := x + n[0], y + n[1]
		if in_bounds(nx, ny) && city.city_lot(c, nx, ny).kind == .Road {
			return true
		}
	}
	return false
}

is_empty_grass :: proc(c: ^city.City, x, y: int) -> bool {
	if !in_bounds(x, y) {
		return false
	}
	lot := city.city_lot(c, x, y)
	return lot.kind == .Plot && lot.terrain == .Grass && !lot.occupant.present
}

in_bounds :: proc(x, y: int) -> bool {
	return x >= 0 && y >= 0 && x < city.MAP_SIZE && y < city.MAP_SIZE
}
