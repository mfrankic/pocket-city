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
TAX_PER_POP :: 1

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
}

Building_Kind :: enum u8 {
	House,
	Shop,
}

Building :: struct {
	kind:    Building_Kind,
	present: bool,
}

Lot :: struct {
	kind:        Lot_Kind,
	zone:        Zone,
	terrain:     Terrain,
	building_id: u16,
}

MAX_BUILDINGS :: MAP_SIZE * MAP_SIZE

City :: struct {
	lots:      [MAP_SIZE * MAP_SIZE]Lot,
	money:     int,
	buildings: [MAX_BUILDINGS]Building,
}

city_new :: proc() -> City {
	c := City {
		money = STARTING_MONEY,
	}
	generate_terrain(&c)
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

city_lot :: proc(c: City, x, y: int) -> Lot {
	return c.lots[y * MAP_SIZE + x]
}

building_kind_at :: proc(c: City, x, y: int) -> (kind: Building_Kind, ok: bool) {
	id := city_lot(c, x, y).building_id
	if id == 0 || id > MAX_BUILDINGS {
		return {}, false
	}
	b := c.buildings[id - 1]
	if !b.present {
		return {}, false
	}
	return b.kind, true
}

@(private)
alloc_building :: proc(c: ^City, kind: Building_Kind) -> u16 {
	for i in 0 ..< MAX_BUILDINGS {
		if !c.buildings[i].present {
			c.buildings[i] = Building {
				kind    = kind,
				present = true,
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
	lot^ = Lot {
		kind    = .Road,
		terrain = lot.terrain,
	}
	return true
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
	return true
}

bulldoze :: proc(c: ^City, x, y: int) -> bool {
	if !in_bounds(x, y) {
		return false
	}
	lot := &c.lots[y * MAP_SIZE + x]
	if lot.kind == .Road {
		lot^ = Lot {
			terrain = lot.terrain,
		}
		return true
	}
	if lot.building_id != 0 {
		remove_building(c, lot.building_id)
		return true
	}
	if lot.terrain == .Forest {
		if c.money < FOREST_COST {
			return false
		}
		c.money -= FOREST_COST
		lot.terrain = .Grass
		return true
	}
	return true
}

city_money :: proc(c: City) -> int {
	return c.money
}

// ponytail: per building, not plots; 09 multiplies by footprint when 2×2 births
city_population :: proc(c: City) -> int {
	n := 0
	for b in c.buildings {
		if b.present && b.kind == .House {
			n += HOUSE_POPULATION
		}
	}
	return n
}

city_jobs :: proc(c: City) -> int {
	n := 0
	for b in c.buildings {
		if b.present && b.kind == .Shop {
			n += SHOP_JOBS
		}
	}
	return n
}

city_residential_demand :: proc(c: City) -> int {
	return DEMAND_BASE + city_jobs(c) - city_population(c)
}

city_commercial_demand :: proc(c: City) -> int {
	return city_population(c) - city_jobs(c)
}

Pick :: proc(n: int) -> int

tick :: proc(c: ^City, pick: Pick) {
	grow_houses := city_residential_demand(c^) > 0
	grow_shops := city_commercial_demand(c^) > 0
	if grow_houses {
		grow(c, .Residential, .House, pick)
	}
	if grow_shops {
		grow(c, .Commercial, .Shop, pick)
	}
	c.money += TAX_PER_POP * city_population(c^)
}

@(private)
grow :: proc(c: ^City, zone: Zone, kind: Building_Kind, pick: Pick) {
	count := 0
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			if eligible(c^, x, y, zone) {
				count += 1
			}
		}
	}
	if count == 0 {
		return
	}
	chosen := pick(count)
	i := 0
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			if eligible(c^, x, y, zone) {
				if i == chosen {
					id := alloc_building(c, kind)
					if id != 0 {
						c.lots[y * MAP_SIZE + x].building_id = id
					}
					return
				}
				i += 1
			}
		}
	}
}

@(private)
eligible :: proc(c: City, x, y: int, zone: Zone) -> bool {
	lot := city_lot(c, x, y)
	return lot.kind == .Plot && lot.zone == zone && lot.building_id == 0 && has_road_access(c, x, y)
}

@(private)
has_road_access :: proc(c: City, x, y: int) -> bool {
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

SAVE_PATH :: "pocket-city.save"
SAVE_VERSION :: u8(3)
SAVE_HEADER :: 1 + 8 + 2
LOT_BYTES :: 5
SAVE_MAX :: SAVE_HEADER + MAX_BUILDINGS + MAP_SIZE * MAP_SIZE * LOT_BYTES

city_save :: proc(c: City, path: string) -> bool {
	buf: [SAVE_MAX]u8
	buf[0] = SAVE_VERSION
	put_i64le(buf[1:9], i64(c.money))
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
		i += 1
	}
	put_u16le(buf[9:11], n)
	for lot in c.lots {
		buf[i + 0] = u8(lot.kind)
		buf[i + 1] = u8(lot.zone)
		buf[i + 2] = u8(lot.terrain)
		put_u16le(buf[i + 3:i + 5], remap[lot.building_id])
		i += LOT_BYTES
	}
	return os.write_entire_file(path, buf[:i]) == nil
}

city_load :: proc(path: string) -> (c: City, ok: bool) {
	data, err := os.read_entire_file(path, context.allocator)
	if err != nil {
		return {}, false
	}
	defer delete(data)
	if len(data) < SAVE_HEADER || data[0] != SAVE_VERSION {
		return {}, false
	}
	count := int(get_u16le(data[9:11]))
	if count > MAX_BUILDINGS {
		return {}, false
	}
	if len(data) != SAVE_HEADER + count + MAP_SIZE * MAP_SIZE * LOT_BYTES {
		return {}, false
	}
	c.money = int(get_i64le(data[1:9]))
	i := SAVE_HEADER
	for b in 0 ..< count {
		if data[i] > u8(Building_Kind.Shop) {
			return {}, false
		}
		c.buildings[b] = Building {
			kind    = Building_Kind(data[i]),
			present = true,
		}
		i += 1
	}
	refs: [MAX_BUILDINGS]int
	for &lot in c.lots {
		if data[i] > u8(Lot_Kind.Road) ||
		   data[i + 1] > u8(Zone.Commercial) ||
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
	for b in 0 ..< count {
		if refs[b] == 0 {
			return {}, false
		}
	}
	return c, true
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
