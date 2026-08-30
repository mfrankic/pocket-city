package city

import "core:os"

MAP_SIZE :: 64
STARTING_MONEY :: 2000
DEMAND_BASE :: 8
ROAD_COST :: 10
ZONE_COST :: 5
FOREST_COST :: 20
HOUSE_POPULATION :: 4
SHOP_JOBS :: 4
FACTORY_JOBS :: 4
TAX_DEFAULT :: 1
STAMP_COST :: 100
ROAD_MAINTENANCE :: 1
FACILITY_MAINTENANCE :: 1
SUPPLY_CAPACITY :: 32
@(private)
HEALTH_ABANDONED :: 0.25
@(private)
HEALTH_STRUGGLING :: 0.6
HEALTH_NIBBLE :: 0.05
HEALTH_REGEN :: 0.02
TAX_HIGH :: 4
POLLUTION_EMIT :: f32(1)
POLLUTION_FALLOFF :: f32(0.5)
POLLUTION_HIGH :: f32(0.2)
TRAFFIC_HIGH :: f32(1)
CRIME_UNEMPLOYED :: f32(1)
CRIME_HIGH :: f32(2)
COVERAGE_RANGE :: 4
LAND_VALUE_HIGH :: f32(2.5)
MONTH_TICKS :: 16
MONTHS_PER_YEAR :: 12
HOURS_PER_DAY :: 24
GRAPH_MONTHS :: 24
OUTAGE_CHANCE :: 8
FIRE_IGNITE_CHANCE :: 11
FIRE_SPREAD_CHANCE :: 13
FIRE_DECAY :: f32(0.25)

Lot_Kind :: enum {
	Plot,
	Road,
}

Terrain :: enum {
	Grass,
	Lake,
	Forest,
	Rock,
}

Zone :: enum {
	None,
	Residential,
	Commercial,
	Industrial,
}

Building_Kind :: enum u8 {
	House,
	Shop,
	Factory,
	Station,
	Tower,
	Park,
	School,
	Police,
	Firehouse,
	Hospital,
}

Building :: struct {
	kind:      Building_Kind,
	present:   bool,
	health:    f32,
	level:     u8,
	remaining: u8,
}

Graph_Point :: struct {
	population: int,
	jobs:       int,
	money:      int,
	happiness:  f32,
}

Lot :: struct {
	kind:    Lot_Kind,
	zone:    Zone,
	terrain: Terrain,
}

@(private)
lot_data :: struct {
	kind:        Lot_Kind,
	zone:        Zone,
	terrain:     Terrain,
	building_id: u16,
}

MAX_BUILDINGS :: MAP_SIZE * MAP_SIZE

City :: struct {
	lots:      [MAP_SIZE * MAP_SIZE]lot_data,
	money:     int,
	tax:       int,
	ticks:     int,
	graph:     [GRAPH_MONTHS]Graph_Point,
	graph_len: int,
	outage:    bool,
	buildings: [MAX_BUILDINGS]Building,
	powered:           [MAP_SIZE * MAP_SIZE]bool,
	watered:           [MAP_SIZE * MAP_SIZE]bool,
	covered_park:      [MAP_SIZE * MAP_SIZE]bool,
	covered_school:    [MAP_SIZE * MAP_SIZE]bool,
	covered_police:    [MAP_SIZE * MAP_SIZE]bool,
	covered_firehouse: [MAP_SIZE * MAP_SIZE]bool,
	covered_hospital:  [MAP_SIZE * MAP_SIZE]bool,
	pollution:         [MAP_SIZE * MAP_SIZE]f32,
	traffic:           [MAP_SIZE * MAP_SIZE]f32,
	crime:             [MAP_SIZE * MAP_SIZE]f32,
	land_value:        [MAP_SIZE * MAP_SIZE]f32,
	fire:              [MAP_SIZE * MAP_SIZE]f32,
}

city_new :: proc() -> ^City {
	c := new(City)
	c.money = STARTING_MONEY
	c.tax = TAX_DEFAULT
	generate_terrain(c)
	recompute_derived(c)
	return c
}

@(private)
generate_terrain :: proc(c: ^City) {
	fill_terrain(c, 36, 8, 14, 8, .Lake)
	fill_terrain(c, 10, 40, 12, 10, .Forest)
	fill_terrain(c, 48, 48, 8, 8, .Rock)
	fill_terrain(c, 22, 22, 8, 5, .Lake)
	fill_terrain(c, 44, 28, 8, 8, .Forest)
	fill_terrain(c, 8, 8, 4, 4, .Rock)
}

@(private)
fill_terrain :: proc(c: ^City, x0, y0, w, h: int, terrain: Terrain) {
	for y in y0 ..< y0 + h {
		for x in x0 ..< x0 + w {
			c.lots[y * MAP_SIZE + x].terrain = terrain
		}
	}
}

city_lot :: proc(c: ^City, x, y: int) -> Lot {
	s := c.lots[y * MAP_SIZE + x]
	return Lot{kind = s.kind, zone = s.zone, terrain = s.terrain}
}

@(private)
building_id_at :: proc(c: ^City, x, y: int) -> u16 {
	return c.lots[y * MAP_SIZE + x].building_id
}

@(private)
plot_unoccupied :: proc(c: ^City, x, y: int) -> bool {
	s := c.lots[y * MAP_SIZE + x]
	return s.kind == .Plot && s.building_id == 0
}

@(private)
building_at :: proc(c: ^City, x, y: int) -> (b: Building, ok: bool) {
	id := building_id_at(c, x, y)
	if id == 0 || id > MAX_BUILDINGS {
		return {}, false
	}
	b = c.buildings[id - 1]
	if !b.present {
		return {}, false
	}
	return b, true
}

building_kind_at :: proc(c: ^City, x, y: int) -> (kind: Building_Kind, ok: bool) {
	b, found := building_at(c, x, y)
	return b.kind, found
}

building_health_at :: proc(c: ^City, x, y: int) -> (health: f32, ok: bool) {
	b, found := building_at(c, x, y)
	return b.health, found
}

building_level_at :: proc(c: ^City, x, y: int) -> (level: u8, ok: bool) {
	b, found := building_at(c, x, y)
	return b.level, found
}

building_construction_remaining_at :: proc(c: ^City, x, y: int) -> (remaining: u8, ok: bool) {
	b, found := building_at(c, x, y)
	return b.remaining, found
}

building_construction_at :: proc(c: ^City, x, y: int) -> bool {
	b, ok := building_at(c, x, y)
	return ok && b.remaining > 0
}

building_northwest_at :: proc(c: ^City, x, y: int) -> (size: int, ok: bool) {
	id := building_id_at(c, x, y)
	if id == 0 {
		return 0, false
	}
	if x > 0 && building_id_at(c, x - 1, y) == id {
		return 0, false
	}
	if y > 0 && building_id_at(c, x, y - 1) == id {
		return 0, false
	}
	size = 1
	if x + 1 < MAP_SIZE && y + 1 < MAP_SIZE {
		if building_id_at(c, x + 1, y) == id && building_id_at(c, x, y + 1) == id {
			size = 2
		}
	}
	return size, true
}

@(private)
finished_at :: proc(c: ^City, x, y: int) -> (b: Building, ok: bool) {
	b, ok = building_at(c, x, y)
	if !ok || b.remaining != 0 {
		return {}, false
	}
	return b, true
}

building_abandoned_at :: proc(c: ^City, x, y: int) -> bool {
	b, ok := finished_at(c, x, y)
	return ok && b.health <= HEALTH_ABANDONED
}

building_struggling_at :: proc(c: ^City, x, y: int) -> bool {
	b, ok := finished_at(c, x, y)
	return ok && b.health > HEALTH_ABANDONED && b.health < HEALTH_STRUGGLING
}

@(private)
alloc_building :: proc(c: ^City, kind: Building_Kind) -> u16 {
	for i in 0 ..< MAX_BUILDINGS {
		if !c.buildings[i].present {
			grown := is_grown(kind)
			c.buildings[i] = Building {
				kind      = kind,
				present   = true,
				health    = 0 if grown else 1,
				level     = 0,
				remaining = MONTH_TICKS if grown else 0,
			}
			return u16(i + 1)
		}
	}
	return 0
}

@(private)
remove_building :: proc(c: ^City, id: u16) {
	if id == 0 || id > MAX_BUILDINGS {
		return
	}
	for &lot in c.lots {
		if lot.building_id == id {
			lot.building_id = 0
		}
	}
	c.buildings[id - 1].present = false
}

@(private)
in_bounds :: proc(x, y: int) -> bool {
	return x >= 0 && y >= 0 && x < MAP_SIZE && y < MAP_SIZE
}

paint_road :: proc(c: ^City, x, y: int) -> bool {
	if !in_bounds(x, y) {
		return false
	}
	lot := &c.lots[y * MAP_SIZE + x]
	if lot.kind == .Road {
		return true
	}
	if lot.terrain != .Grass {
		return false
	}
	if c.money < ROAD_COST {
		return false
	}
	c.money -= ROAD_COST
	if lot.building_id != 0 {
		remove_building(c, lot.building_id)
	}
	lot^ = lot_data {
		kind    = .Road,
		terrain = lot.terrain,
	}
	recompute_derived(c)
	return true
}

stamp :: proc(c: ^City, x, y: int, kind: Building_Kind, size := 1) -> bool {
	if !is_facility(kind) {
		return false
	}
	if size != 1 && (size != 2 || kind != .Station) {
		return false
	}
	access := false
	for dy in 0 ..< size {
		for dx in 0 ..< size {
			px, py := x + dx, y + dy
			if !in_bounds(px, py) {
				return false
			}
			if !plot_unoccupied(c, px, py) || c.lots[py * MAP_SIZE + px].terrain != .Grass {
				return false
			}
			if has_road_access(c, px, py) {
				access = true
			}
		}
	}
	if !access {
		return false
	}
	if kind == .Tower && !has_lake_neighbor(c, x, y) {
		return false
	}
	if c.money < STAMP_COST {
		return false
	}
	id := alloc_building(c, kind)
	if id == 0 {
		return false
	}
	c.money -= STAMP_COST
	for dy in 0 ..< size {
		for dx in 0 ..< size {
			lot := &c.lots[(y + dy) * MAP_SIZE + (x + dx)]
			lot.building_id = id
			lot.zone = .None
		}
	}
	recompute_derived(c)
	return true
}

@(private)
is_facility :: proc(kind: Building_Kind) -> bool {
	switch kind {
	case .House, .Shop, .Factory:
		return false
	case .Station, .Tower, .Park, .School, .Police, .Firehouse, .Hospital:
		return true
	}
	return false
}

paint_zone :: proc(c: ^City, x, y: int, zone: Zone) -> bool {
	if !in_bounds(x, y) {
		return false
	}
	lot := &c.lots[y * MAP_SIZE + x]
	if lot.kind == .Road {
		return false
	}
	if lot.terrain != .Grass {
		return false
	}
	if lot.zone == zone {
		return true
	}
	if c.money < ZONE_COST {
		return false
	}
	c.money -= ZONE_COST
	if lot.building_id != 0 {
		remove_building(c, lot.building_id)
	}
	lot.zone = zone
	recompute_derived(c)
	return true
}

bulldoze :: proc(c: ^City, x, y: int) -> bool {
	if !in_bounds(x, y) {
		return false
	}
	lot := &c.lots[y * MAP_SIZE + x]
	if lot.kind == .Road {
		lot^ = lot_data {
			terrain = lot.terrain,
		}
		recompute_derived(c)
		return true
	}
	if lot.building_id != 0 {
		remove_building(c, lot.building_id)
		recompute_derived(c)
		return true
	}
	if lot.terrain == .Forest {
		if c.money < FOREST_COST {
			return false
		}
		c.money -= FOREST_COST
		lot.terrain = .Grass
		recompute_derived(c)
		return true
	}
	return true
}

city_money :: proc(c: ^City) -> int {
	return c.money
}

city_tax :: proc(c: ^City) -> int {
	return c.tax
}

city_year :: proc(c: ^City) -> int {
	return c.ticks / (MONTH_TICKS * MONTHS_PER_YEAR) + 1
}

city_month :: proc(c: ^City) -> int {
	return c.ticks / MONTH_TICKS % MONTHS_PER_YEAR + 1
}

city_day :: proc(c: ^City) -> int {
	return c.ticks % MONTH_TICKS + 1
}

city_hour :: proc(c: ^City) -> int {
	return c.ticks * HOURS_PER_DAY / MONTH_TICKS % HOURS_PER_DAY
}

city_graph_len :: proc(c: ^City) -> int {
	return c.graph_len
}

city_graph_at :: proc(c: ^City, i: int) -> Graph_Point {
	return c.graph[i]
}

city_outage :: proc(c: ^City) -> bool {
	return c.outage
}

city_set_tax :: proc(c: ^City, tax: int) {
	c.tax = max(tax, 0)
}

lot_powered :: proc(c: ^City, x, y: int) -> bool {
	return c.powered[y * MAP_SIZE + x]
}

lot_watered :: proc(c: ^City, x, y: int) -> bool {
	return c.watered[y * MAP_SIZE + x]
}

lot_pollution :: proc(c: ^City, x, y: int) -> f32 {
	return c.pollution[y * MAP_SIZE + x]
}

lot_traffic :: proc(c: ^City, x, y: int) -> f32 {
	return c.traffic[y * MAP_SIZE + x]
}

lot_crime :: proc(c: ^City, x, y: int) -> f32 {
	return c.crime[y * MAP_SIZE + x]
}

lot_fire :: proc(c: ^City, x, y: int) -> f32 {
	return c.fire[y * MAP_SIZE + x]
}

lot_covered :: proc(c: ^City, x, y: int, kind: Building_Kind) -> bool {
	return coverage_at(c, x, y, kind)
}

@(private)
coverage_at :: proc(c: ^City, x, y: int, kind: Building_Kind) -> bool {
	if !in_bounds(x, y) {
		return false
	}
	dest, ok := coverage_grid(c, kind)
	if !ok {
		return false
	}
	return dest[y * MAP_SIZE + x]
}

@(private)
coverage_grid :: proc(c: ^City, kind: Building_Kind) -> (dest: ^[MAP_SIZE * MAP_SIZE]bool, ok: bool) {
	switch kind {
	case .Park:
		return &c.covered_park, true
	case .School:
		return &c.covered_school, true
	case .Police:
		return &c.covered_police, true
	case .Firehouse:
		return &c.covered_firehouse, true
	case .Hospital:
		return &c.covered_hospital, true
	case .House, .Shop, .Factory, .Station, .Tower:
		return nil, false
	}
	return nil, false
}

@(private)
coverage_needs_power :: proc(kind: Building_Kind) -> bool {
	switch kind {
	case .School, .Police, .Firehouse, .Hospital:
		return true
	case .House, .Shop, .Factory, .Station, .Tower, .Park:
		return false
	}
	return false
}

lot_education :: proc(c: ^City, x, y: int) -> bool {
	return coverage_at(c, x, y, .School)
}

lot_land_value :: proc(c: ^City, x, y: int) -> f32 {
	return c.land_value[y * MAP_SIZE + x]
}

@(private)
recompute_derived :: proc(c: ^City) {
	c.powered = {}
	c.watered = {}
	for id in 1 ..= MAX_BUILDINGS {
		b := c.buildings[id - 1]
		if b.present && b.kind == .Station && !c.outage {
			flood_supply(c, u16(id), &c.powered)
		}
	}
	for id in 1 ..= MAX_BUILDINGS {
		b := c.buildings[id - 1]
		if b.present && b.kind == .Tower && facility_powered(c, u16(id)) {
			flood_supply(c, u16(id), &c.watered)
		}
	}
	recompute_coverage(c)
	recompute_traffic(c)
	recompute_crime(c)
	recompute_pollution(c)
	recompute_land_value(c)
}

@(private)
recompute_coverage :: proc(c: ^City) {
	c.covered_park = {}
	c.covered_school = {}
	c.covered_police = {}
	c.covered_firehouse = {}
	c.covered_hospital = {}
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		id := c.lots[i].building_id
		if id == 0 || id > MAX_BUILDINGS {
			continue
		}
		b := c.buildings[id - 1]
		if !b.present {
			continue
		}
		dest, ok := coverage_grid(c, b.kind)
		if !ok {
			continue
		}
		if coverage_needs_power(b.kind) && !facility_powered(c, id) {
			continue
		}
		stamp_coverage_square(dest, i % MAP_SIZE, i / MAP_SIZE)
	}
}

@(private)
stamp_coverage_square :: proc(dest: ^[MAP_SIZE * MAP_SIZE]bool, fx, fy: int) {
	for y in fy - COVERAGE_RANGE ..= fy + COVERAGE_RANGE {
		for x in fx - COVERAGE_RANGE ..= fx + COVERAGE_RANGE {
			if in_bounds(x, y) {
				dest[y * MAP_SIZE + x] = true
			}
		}
	}
}

@(private)
facility_powered :: proc(c: ^City, id: u16) -> bool {
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if c.lots[i].building_id == id && c.powered[i] {
			return true
		}
	}
	return false
}

@(private)
flood_supply :: proc(c: ^City, id: u16, dest: ^[MAP_SIZE * MAP_SIZE]bool) {
	n_plots := 0
	for lot in c.lots {
		if lot.building_id == id {
			n_plots += 1
		}
	}
	cap := SUPPLY_CAPACITY * n_plots
	visited: [MAP_SIZE * MAP_SIZE]bool
	queue: [MAP_SIZE * MAP_SIZE]int
	head, tail := 0, 0
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if c.lots[i].building_id != id {
			continue
		}
		x, y := i % MAP_SIZE, i / MAP_SIZE
		for n in cardinal {
			nx, ny := x + n[0], y + n[1]
			if !in_bounds(nx, ny) {
				continue
			}
			ni := ny * MAP_SIZE + nx
			if c.lots[ni].kind == .Road && !visited[ni] {
				visited[ni] = true
				queue[tail] = ni
				tail += 1
			}
		}
	}
	for head < tail {
		i := queue[head]
		head += 1
		x, y := i % MAP_SIZE, i / MAP_SIZE
		for n in cardinal {
			nx, ny := x + n[0], y + n[1]
			if !in_bounds(nx, ny) {
				continue
			}
			ni := ny * MAP_SIZE + nx
			if c.lots[ni].kind == .Road {
				if !visited[ni] {
					visited[ni] = true
					queue[tail] = ni
					tail += 1
				}
			} else if !dest[ni] && cap > 0 {
				dest[ni] = true
				cap -= 1
			}
		}
	}
}

@(private)
recompute_traffic :: proc(c: ^City) {
	c.traffic = {}
	visited: [MAP_SIZE * MAP_SIZE]bool
	queue: [MAP_SIZE * MAP_SIZE]int
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for start in 0 ..< MAP_SIZE * MAP_SIZE {
		if c.lots[start].kind != .Road || visited[start] {
			continue
		}
		head, tail := 0, 0
		visited[start] = true
		queue[tail] = start
		tail += 1
		n_roads := 0
		n_grown := 0
		seen: [MAX_BUILDINGS]bool
		for head < tail {
			i := queue[head]
			head += 1
			n_roads += 1
			x, y := i % MAP_SIZE, i / MAP_SIZE
			for n in cardinal {
				nx, ny := x + n[0], y + n[1]
				if !in_bounds(nx, ny) {
					continue
				}
				ni := ny * MAP_SIZE + nx
				if c.lots[ni].kind == .Road {
					if !visited[ni] {
						visited[ni] = true
						queue[tail] = ni
						tail += 1
					}
					continue
				}
				id := c.lots[ni].building_id
				if id == 0 || id > MAX_BUILDINGS {
					continue
				}
				b := c.buildings[id - 1]
				if !b.present || !is_grown(b.kind) || seen[id - 1] {
					continue
				}
				seen[id - 1] = true
				n_grown += 1
			}
		}
		load := f32(n_grown) / f32(n_roads)
		for i in 0 ..< n_roads {
			c.traffic[queue[i]] = load
		}
	}
}

@(private)
recompute_crime :: proc(c: ^City) {
	unemployed := city_population(c) > city_jobs(c)
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			if coverage_at(c, x, y, .Police) {
				c.crime[y * MAP_SIZE + x] = 0
				continue
			}
			n := 0
			for dy in -1 ..= 1 {
				for dx in -1 ..= 1 {
					nx, ny := x + dx, y + dy
					if !in_bounds(nx, ny) {
						continue
					}
					id := c.lots[ny * MAP_SIZE + nx].building_id
					if id == 0 || id > MAX_BUILDINGS {
						continue
					}
					b := c.buildings[id - 1]
					if b.present && is_grown(b.kind) {
						n += 1
					}
				}
			}
			crime := f32(n)
			if unemployed {
				crime += CRIME_UNEMPLOYED
			}
			c.crime[y * MAP_SIZE + x] = crime
		}
	}
}

@(private)
recompute_pollution :: proc(c: ^City) {
	// ponytail: closed-form cardinal spread+decay (Manhattan); a lingering field if demolish should leave smoke
	c.pollution = {}
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		id := c.lots[i].building_id
		if id == 0 || id > MAX_BUILDINGS {
			continue
		}
		b := c.buildings[id - 1]
		if !b.present || b.kind != .Factory {
			continue
		}
		fx, fy := i % MAP_SIZE, i / MAP_SIZE
		for y in 0 ..< MAP_SIZE {
			for x in 0 ..< MAP_SIZE {
				d := abs(x - fx) + abs(y - fy)
				c.pollution[y * MAP_SIZE + x] += pollution_from_distance(d)
			}
		}
	}
}

@(private)
pollution_from_distance :: proc(d: int) -> f32 {
	amount := POLLUTION_EMIT
	for _ in 0 ..< d {
		amount *= POLLUTION_FALLOFF
	}
	return amount
}

@(private)
recompute_land_value :: proc(c: ^City) {
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			lot := city_lot(c, x, y)
			v: f32
			switch lot.terrain {
			case .Grass:
				v = 1
			case .Forest:
				v = 0.5
			case .Lake, .Rock:
				v = 0
			}
			if lot.kind == .Road || has_road_access(c, x, y) {
				v += 1
			}
			if coverage_at(c, x, y, .Park) {
				v += 1
			}
			v -= c.pollution[y * MAP_SIZE + x]
			if kind, ok := building_kind_at(c, x, y); ok && kind == .Shop {
				v -= c.crime[y * MAP_SIZE + x]
			}
			c.land_value[y * MAP_SIZE + x] = v
		}
	}
}

city_population :: proc(c: ^City) -> int {
	return grown_stat(c, .House, HOUSE_POPULATION)
}

city_jobs :: proc(c: ^City) -> int {
	return shop_jobs(c) + factory_jobs(c)
}

city_happiness :: proc(c: ^City) -> f32 {
	n := 0
	sum: f32
	for b in c.buildings {
		if b.present && b.remaining == 0 {
			sum += b.health
			n += 1
		}
	}
	if n == 0 {
		return 1
	}
	return sum / f32(n)
}

city_power_percent :: proc(c: ^City) -> f32 {
	return occupied_supply_percent(c, c.powered)
}

city_water_percent :: proc(c: ^City) -> f32 {
	return occupied_supply_percent(c, c.watered)
}

@(private)
occupied_supply_percent :: proc(c: ^City, flags: [MAP_SIZE * MAP_SIZE]bool) -> f32 {
	n, supplied := 0, 0
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if c.lots[i].building_id == 0 {
			continue
		}
		n += 1
		if flags[i] {
			supplied += 1
		}
	}
	if n == 0 {
		return 1
	}
	return f32(supplied) / f32(n)
}

@(private)
shop_jobs :: proc(c: ^City) -> int {
	return grown_stat(c, .Shop, SHOP_JOBS)
}

@(private)
factory_jobs :: proc(c: ^City) -> int {
	return grown_stat(c, .Factory, FACTORY_JOBS)
}

@(private)
grown_stat :: proc(c: ^City, kind: Building_Kind, base: int) -> int {
	n := 0
	for id in 1 ..= MAX_BUILDINGS {
		b := c.buildings[id - 1]
		if producing(b) && b.kind == kind {
			n += base * int(b.level) * building_plots(c, u16(id))
		}
	}
	return n
}

@(private)
building_plots :: proc(c: ^City, id: u16) -> int {
	n := 0
	for lot in c.lots {
		if lot.building_id == id {
			n += 1
		}
	}
	return n
}

city_residential_demand :: proc(c: ^City) -> int {
	return DEMAND_BASE + city_jobs(c) - city_population(c)
}

city_commercial_demand :: proc(c: ^City) -> int {
	return city_population(c) - shop_jobs(c)
}

city_industrial_demand :: proc(c: ^City) -> int {
	return shop_jobs(c) - factory_jobs(c)
}

Pick :: proc(n: int) -> int

tick :: proc(c: ^City, pick: Pick) {
	month_start := c.ticks % MONTH_TICKS == 0
	if month_start {
		sample_graph(c)
		c.outage = pick(OUTAGE_CHANCE) == OUTAGE_CHANCE - 1
	}
	c.ticks += 1
	recompute_derived(c)
	if month_start {
		apply_fire(c, pick)
	}
	apply_health(c)
	grow_houses := city_residential_demand(c) > 0
	grow_shops := city_commercial_demand(c) > 0
	grow_factories := city_industrial_demand(c) > 0
	if grow_houses {
		grow(c, .Residential, .House, pick)
	}
	if grow_shops {
		grow(c, .Commercial, .Shop, pick)
	}
	if grow_factories {
		grow(c, .Industrial, .Factory, pick)
	}
	if city_residential_demand(c) > 0 {
		level_up(c, .House, pick)
	}
	if city_commercial_demand(c) > 0 {
		level_up(c, .Shop, pick)
	}
	if city_industrial_demand(c) > 0 {
		level_up(c, .Factory, pick)
	}
	c.money += c.tax * city_population(c)
	advance_construction(c)
	apply_maintenance(c)
}

@(private)
apply_maintenance :: proc(c: ^City) {
	maintenance := 0
	for lot in c.lots {
		if lot.kind == .Road {
			maintenance += ROAD_MAINTENANCE
		}
	}
	for b in c.buildings {
		if b.present && is_facility(b.kind) {
			maintenance += FACILITY_MAINTENANCE
		}
	}
	c.money = max(c.money - maintenance, 0)
}

@(private)
advance_construction :: proc(c: ^City) {
	for &b in c.buildings {
		if !b.present || b.remaining == 0 {
			continue
		}
		b.remaining -= 1
		if b.remaining == 0 {
			b.level = 1
			b.health = 1
		}
	}
}

@(private)
apply_fire :: proc(c: ^City, pick: Pick) {
	spread_fire(c, pick)
	decay_fire(c)
	count := 0
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if fire_ignitable(c, i) {
			count += 1
		}
	}
	if count == 0 || pick(FIRE_IGNITE_CHANCE) != FIRE_IGNITE_CHANCE - 1 {
		return
	}
	chosen := pick(count)
	n := 0
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if fire_ignitable(c, i) {
			if n == chosen {
				c.fire[i] = 1
				return
			}
			n += 1
		}
	}
}

@(private)
decay_fire :: proc(c: ^City) {
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if c.fire[i] <= 0 {
			continue
		}
		x, y := i % MAP_SIZE, i / MAP_SIZE
		if coverage_at(c, x, y, .Firehouse) {
			c.fire[i] = max(c.fire[i] - FIRE_DECAY, 0)
		}
	}
}

@(private)
spread_fire :: proc(c: ^City, pick: Pick) {
	onto: [MAP_SIZE * MAP_SIZE]bool
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if c.fire[i] <= 0 {
			continue
		}
		if pick(FIRE_SPREAD_CHANCE) != FIRE_SPREAD_CHANCE - 1 {
			continue
		}
		x, y := i % MAP_SIZE, i / MAP_SIZE
		targets: [4]int
		n_targets := 0
		for n in cardinal {
			nx, ny := x + n[0], y + n[1]
			if !in_bounds(nx, ny) {
				continue
			}
			lot := city_lot(c, nx, ny)
			if lot.kind == .Road || lot.terrain == .Lake || lot.terrain == .Rock {
				continue
			}
			targets[n_targets] = ny * MAP_SIZE + nx
			n_targets += 1
		}
		if n_targets == 0 {
			continue
		}
		onto[targets[pick(n_targets)]] = true
	}
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if onto[i] {
			c.fire[i] = 1
		}
	}
}

@(private)
fire_ignitable :: proc(c: ^City, i: int) -> bool {
	id := c.lots[i].building_id
	if id == 0 || id > MAX_BUILDINGS {
		return false
	}
	b := c.buildings[id - 1]
	x, y := i % MAP_SIZE, i / MAP_SIZE
	return b.present && is_grown(b.kind) && !coverage_at(c, x, y, .Firehouse)
}

@(private)
sample_graph :: proc(c: ^City) {
	if c.graph_len == GRAPH_MONTHS {
		copy(c.graph[:GRAPH_MONTHS - 1], c.graph[1:])
		c.graph_len -= 1
	}
	c.graph[c.graph_len] = Graph_Point {
		population = city_population(c),
		jobs       = city_jobs(c),
		money      = city_money(c),
		happiness  = city_happiness(c),
	}
	c.graph_len += 1
}

@(private)
apply_health :: proc(c: ^City) {
	// ponytail: producing pop, so demand can return; husks may pulse until shops exist
	unemployed := city_population(c) > city_jobs(c)
	for id in 1 ..= MAX_BUILDINGS {
		b := &c.buildings[id - 1]
		if !b.present || b.remaining > 0 {
			continue
		}
		delta: f32
		if is_grown(b.kind) {
			if !lots_supplied(c, u16(id), &c.powered) {
				delta -= HEALTH_NIBBLE
			}
			if !lots_supplied(c, u16(id), &c.watered) {
				delta -= HEALTH_NIBBLE
			}
			if building_traffic(c, u16(id)) >= TRAFFIC_HIGH {
				delta -= HEALTH_NIBBLE
			}
		}
		if unemployed && b.kind == .House {
			delta -= HEALTH_NIBBLE
		}
		if b.kind == .House && building_pollution(c, u16(id)) > POLLUTION_HIGH {
			delta -= HEALTH_NIBBLE
		}
		if b.kind == .Shop && building_crime(c, u16(id)) >= CRIME_HIGH {
			delta -= HEALTH_NIBBLE
		}
		if c.tax >= TAX_HIGH {
			delta -= HEALTH_NIBBLE
		}
		if building_fire(c, u16(id)) > 0 {
			delta -= HEALTH_NIBBLE
		}
		if delta == 0 {
			delta = HEALTH_REGEN
		}
		b.health = clamp(b.health + delta, 0, 1)
	}
}

@(private)
producing :: proc(b: Building) -> bool {
	return b.present && b.remaining == 0 && b.health > HEALTH_ABANDONED
}

@(private)
is_grown :: proc(kind: Building_Kind) -> bool {
	switch kind {
	case .House, .Shop, .Factory:
		return true
	case .Station, .Tower, .Park, .School, .Police, .Firehouse, .Hospital:
		return false
	}
	return false
}

@(private)
lots_supplied :: proc(c: ^City, id: u16, flags: ^[MAP_SIZE * MAP_SIZE]bool) -> bool {
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if c.lots[i].building_id == id && !flags[i] {
			return false
		}
	}
	return true
}

@(private)
building_fire :: proc(c: ^City, id: u16) -> f32 {
	worst: f32
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if c.lots[i].building_id == id && c.fire[i] > worst {
			worst = c.fire[i]
		}
	}
	return worst
}

@(private)
building_pollution :: proc(c: ^City, id: u16) -> f32 {
	worst: f32
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if c.lots[i].building_id == id && c.pollution[i] > worst {
			worst = c.pollution[i]
		}
	}
	return worst
}

@(private)
building_crime :: proc(c: ^City, id: u16) -> f32 {
	worst: f32
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if c.lots[i].building_id == id && c.crime[i] > worst {
			worst = c.crime[i]
		}
	}
	return worst
}

@(private)
building_traffic :: proc(c: ^City, id: u16) -> f32 {
	worst: f32
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if c.lots[i].building_id != id {
			continue
		}
		x, y := i % MAP_SIZE, i / MAP_SIZE
		for n in cardinal {
			nx, ny := x + n[0], y + n[1]
			if !in_bounds(nx, ny) {
				continue
			}
			t := c.traffic[ny * MAP_SIZE + nx]
			if t > worst {
				worst = t
			}
		}
	}
	return worst
}

@(private)
grow :: proc(c: ^City, zone: Zone, kind: Building_Kind, pick: Pick) {
	count := 0
	size := 2
	for y in 0 ..< MAP_SIZE - 1 {
		for x in 0 ..< MAP_SIZE - 1 {
			if eligible_2x2(c, x, y, zone) {
				count += 1
			}
		}
	}
	if count == 0 {
		size = 1
		for y in 0 ..< MAP_SIZE {
			for x in 0 ..< MAP_SIZE {
				if eligible(c, x, y, zone) {
					count += 1
				}
			}
		}
	}
	if count == 0 {
		return
	}
	chosen := pick(count)
	i := 0
	ymax := MAP_SIZE if size == 1 else MAP_SIZE - 1
	xmax := ymax
	for y in 0 ..< ymax {
		for x in 0 ..< xmax {
			ok := eligible_2x2(c, x, y, zone) if size == 2 else eligible(c, x, y, zone)
			if ok {
				if i == chosen {
					id := alloc_building(c, kind)
					if id != 0 {
						for dy in 0 ..< size {
							for dx in 0 ..< size {
								c.lots[(y + dy) * MAP_SIZE + (x + dx)].building_id = id
							}
						}
					}
					return
				}
				i += 1
			}
		}
	}
}

@(private)
eligible_2x2 :: proc(c: ^City, x, y: int, zone: Zone) -> bool {
	sum: f32
	access := false
	for dy in 0 ..< 2 {
		for dx in 0 ..< 2 {
			if !plot_ready(c, x + dx, y + dy, zone) {
				return false
			}
			if has_road_access(c, x + dx, y + dy) {
				access = true
			}
			sum += lot_land_value(c, x + dx, y + dy)
		}
	}
	return access && sum / 4 >= LAND_VALUE_HIGH
}

@(private)
plot_ready :: proc(c: ^City, x, y: int, zone: Zone) -> bool {
	return plot_unoccupied(c, x, y) &&
		c.lots[y * MAP_SIZE + x].zone == zone &&
		lot_powered(c, x, y) &&
		lot_watered(c, x, y)
}

@(private)
eligible :: proc(c: ^City, x, y: int, zone: Zone) -> bool {
	return plot_ready(c, x, y, zone) && has_road_access(c, x, y)
}

@(private)
level_up :: proc(c: ^City, kind: Building_Kind, pick: Pick) {
	count := 0
	for id in 1 ..= MAX_BUILDINGS {
		if eligible_level(c, u16(id), kind) {
			count += 1
		}
	}
	if count == 0 {
		return
	}
	chosen := pick(count)
	i := 0
	for id in 1 ..= MAX_BUILDINGS {
		if eligible_level(c, u16(id), kind) {
			if i == chosen {
				c.buildings[id - 1].level += 1
				return
			}
			i += 1
		}
	}
}

@(private)
eligible_level :: proc(c: ^City, id: u16, kind: Building_Kind) -> bool {
	b := c.buildings[id - 1]
	if !producing(b) || b.kind != kind || b.level < 1 || b.level >= 3 {
		return false
	}
	if !building_has_road(c, id) {
		return false
	}
	if building_avg_land_value(c, id) < LAND_VALUE_HIGH {
		return false
	}
	if kind == .House {
		if b.level == 1 && !building_all_covered(c, id, .School) {
			return false
		}
		if b.level == 2 && !building_all_covered(c, id, .Hospital) {
			return false
		}
	}
	return true
}

@(private)
building_avg_land_value :: proc(c: ^City, id: u16) -> f32 {
	sum: f32
	n := 0
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if c.lots[i].building_id == id {
			sum += lot_land_value(c, i % MAP_SIZE, i / MAP_SIZE)
			n += 1
		}
	}
	if n == 0 {
		return 0
	}
	return sum / f32(n)
}

@(private)
building_has_road :: proc(c: ^City, id: u16) -> bool {
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if c.lots[i].building_id == id && has_road_access(c, i % MAP_SIZE, i / MAP_SIZE) {
			return true
		}
	}
	return false
}

@(private)
building_all_covered :: proc(c: ^City, id: u16, kind: Building_Kind) -> bool {
	found := false
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		if c.lots[i].building_id != id {
			continue
		}
		found = true
		if !coverage_at(c, i % MAP_SIZE, i / MAP_SIZE, kind) {
			return false
		}
	}
	return found
}

@(private)
has_road_access :: proc(c: ^City, x, y: int) -> bool {
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for n in cardinal {
		nx, ny := x + n[0], y + n[1]
		if !in_bounds(nx, ny) {
			continue
		}
		if city_lot(c, nx, ny).kind == .Road {
			return true
		}
	}
	return false
}

@(private)
has_lake_neighbor :: proc(c: ^City, x, y: int) -> bool {
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for n in cardinal {
		nx, ny := x + n[0], y + n[1]
		if !in_bounds(nx, ny) {
			continue
		}
		if city_lot(c, nx, ny).terrain == .Lake {
			return true
		}
	}
	return false
}

SAVE_PATH :: "pocket-city.save"
SAVE_VERSION :: u8(9)
SAVE_HEADER :: 1 + 8 + 8 + 8 + 1 + 2
LOT_BYTES :: 5
BUILDING_BYTES :: 7
FIRE_BYTES :: 4
SAVE_MAX :: SAVE_HEADER + MAX_BUILDINGS * BUILDING_BYTES + MAP_SIZE * MAP_SIZE * (LOT_BYTES + FIRE_BYTES)

city_save :: proc(c: ^City, path: string) -> bool {
	buf: [SAVE_MAX]u8
	buf[0] = SAVE_VERSION
	put_i64le(buf[1:9], i64(c.money))
	put_i64le(buf[9:17], i64(c.tax))
	put_i64le(buf[17:25], i64(c.ticks))
	buf[25] = 1 if c.outage else 0
	remap: [MAX_BUILDINGS + 1]u16
	n: u16
	i := SAVE_HEADER
	for id in 1 ..= MAX_BUILDINGS {
		b := c.buildings[id - 1]
		if !b.present {
			continue
		}
		n += 1
		remap[id] = n
		buf[i] = u8(b.kind)
		put_f32le(buf[i + 1:i + 5], b.health)
		buf[i + 5] = b.level
		buf[i + 6] = b.remaining
		i += BUILDING_BYTES
	}
	put_u16le(buf[26:28], n)
	for lot in c.lots {
		buf[i + 0] = u8(lot.kind)
		buf[i + 1] = u8(lot.zone)
		buf[i + 2] = u8(lot.terrain)
		put_u16le(buf[i + 3:i + 5], remap[lot.building_id])
		i += LOT_BYTES
	}
	for f in c.fire {
		put_f32le(buf[i:i + FIRE_BYTES], f)
		i += FIRE_BYTES
	}
	return os.write_entire_file(path, buf[:i]) == nil
}

city_load :: proc(path: string) -> (c: ^City, ok: bool) {
	data, err := os.read_entire_file(path, context.allocator)
	if err != nil {
		return nil, false
	}
	defer delete(data)
	if len(data) < SAVE_HEADER || data[0] != SAVE_VERSION {
		return nil, false
	}
	count := int(get_u16le(data[26:28]))
	if count > MAX_BUILDINGS {
		return nil, false
	}
	if len(data) !=
	   SAVE_HEADER + count * BUILDING_BYTES + MAP_SIZE * MAP_SIZE * (LOT_BYTES + FIRE_BYTES) {
		return nil, false
	}
	ticks := get_i64le(data[17:25])
	if ticks < 0 {
		return nil, false
	}
	if data[25] > 1 {
		return nil, false
	}
	p := new(City)
	defer if !ok {
		free(p)
	}
	p.money = int(get_i64le(data[1:9]))
	p.tax = int(get_i64le(data[9:17]))
	p.ticks = int(ticks)
	p.outage = data[25] == 1
	i := SAVE_HEADER
	for b in 0 ..< count {
		if data[i] >= u8(len(Building_Kind)) {
			return {}, false
		}
		h := get_f32le(data[i + 1:i + 5])
		if h != h || h < 0 || h > 1 {
			return {}, false
		}
		kind := Building_Kind(data[i])
		level := data[i + 5]
		remaining := data[i + 6]
		if remaining > MONTH_TICKS {
			return {}, false
		}
		if remaining > 0 {
			if !is_grown(kind) || level != 0 || h != 0 {
				return {}, false
			}
		} else if is_grown(kind) {
			if level < 1 || level > 3 {
				return {}, false
			}
		} else if level != 0 {
			return {}, false
		}
		p.buildings[b] = Building {
			kind      = kind,
			present   = true,
			health    = h,
			level     = level,
			remaining = remaining,
		}
		i += BUILDING_BYTES
	}
	refs: [MAX_BUILDINGS]int
	for &lot in p.lots {
		if data[i] > u8(Lot_Kind.Road) ||
		   data[i + 1] > u8(Zone.Industrial) ||
		   data[i + 2] > u8(Terrain.Rock) {
			return {}, false
		}
		id := get_u16le(data[i + 3:i + 5])
		if int(id) > count {
			return {}, false
		}
		lot.kind = Lot_Kind(data[i])
		lot.zone = Zone(data[i + 1])
		lot.terrain = Terrain(data[i + 2])
		lot.building_id = id
		if id != 0 {
			refs[id - 1] += 1
		}
		i += LOT_BYTES
	}
	for j in 0 ..< MAP_SIZE * MAP_SIZE {
		f := get_f32le(data[i:i + FIRE_BYTES])
		if f != f || f < 0 || f > 1 {
			return {}, false
		}
		p.fire[j] = f
		i += FIRE_BYTES
	}
	for b in 0 ..< count {
		if refs[b] == 0 {
			return {}, false
		}
	}
	recompute_derived(p)
	c = p
	ok = true
	return
}

@(private)
put_u16le :: proc(b: []u8, v: u16) {
	b[0] = u8(v)
	b[1] = u8(v >> 8)
}

@(private)
get_u16le :: proc(b: []u8) -> u16 {
	return u16(b[0]) | u16(b[1]) << 8
}

@(private)
put_i64le :: proc(b: []u8, v: i64) {
	u := transmute(u64)v
	for j in 0 ..< 8 {
		b[j] = u8(u >> uint(8 * j))
	}
}

@(private)
get_i64le :: proc(b: []u8) -> i64 {
	u: u64
	for j in 0 ..< 8 {
		u |= u64(b[j]) << uint(8 * j)
	}
	return transmute(i64)u
}

@(private)
put_f32le :: proc(b: []u8, v: f32) {
	u := transmute(u32)v
	for j in 0 ..< 4 {
		b[j] = u8(u >> uint(8 * j))
	}
}

@(private)
get_f32le :: proc(b: []u8) -> f32 {
	u: u32
	for j in 0 ..< 4 {
		u |= u32(b[j]) << uint(8 * j)
	}
	return transmute(f32)u
}
