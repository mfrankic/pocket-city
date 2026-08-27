package city

MAP_SIZE :: 32
STARTING_MONEY :: 2000
DEMAND_BASE :: 8
ROAD_COST :: 10
ZONE_COST :: 5
HOUSE_POPULATION :: 4
SHOP_JOBS :: 4
TAX_PER_POP :: 1

Lot_Kind :: enum {
	Plot,
	Road,
}

Zone :: enum {
	None,
	Residential,
	Commercial,
}

Building :: enum {
	None,
	House,
	Shop,
}

Lot :: struct {
	kind:     Lot_Kind,
	zone:     Zone,
	building: Building,
}

City :: struct {
	lots:  [MAP_SIZE * MAP_SIZE]Lot,
	money: int,
}

city_new :: proc() -> City {
	return City{money = STARTING_MONEY}
}

city_lot :: proc(c: City, x, y: int) -> Lot {
	return c.lots[y * MAP_SIZE + x]
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
	if c.money < ROAD_COST {
		return false
	}
	c.money -= ROAD_COST
	lot^ = Lot {
		kind = .Road,
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
	if lot.zone == zone {
		return true
	}
	if c.money < ZONE_COST {
		return false
	}
	c.money -= ZONE_COST
	lot.zone = zone
	lot.building = .None
	return true
}

bulldoze :: proc(c: ^City, x, y: int) -> bool {
	if !in_bounds(x, y) {
		return false
	}
	lot := &c.lots[y * MAP_SIZE + x]
	if lot.kind == .Road {
		lot^ = Lot{}
		return true
	}
	lot.building = .None
	return true
}

city_money :: proc(c: City) -> int {
	return c.money
}

city_population :: proc(c: City) -> int {
	n := 0
	for lot in c.lots {
		if lot.building == .House {
			n += HOUSE_POPULATION
		}
	}
	return n
}

city_jobs :: proc(c: City) -> int {
	n := 0
	for lot in c.lots {
		if lot.building == .Shop {
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
grow :: proc(c: ^City, zone: Zone, building: Building, pick: Pick) {
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
					c.lots[y * MAP_SIZE + x].building = building
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
	return lot.kind == .Plot && lot.zone == zone && lot.building == .None && has_road_access(c, x, y)
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
