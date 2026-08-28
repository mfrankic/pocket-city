package city

import "core:os"
import "core:testing"

@(test)
new_city_has_starting_stats :: proc(t: ^testing.T) {
	c := city_new()
	testing.expect_value(t, city_money(c), 2000)
	testing.expect_value(t, city_population(c), 0)
	testing.expect_value(t, city_jobs(c), 0)
	testing.expect_value(t, city_residential_demand(c), 8)
	testing.expect_value(t, city_commercial_demand(c), 0)
}

@(test)
new_city_lots_are_empty_plots :: proc(t: ^testing.T) {
	c := city_new()
	lot := city_lot(c, 0, 0)
	testing.expect_value(t, lot.kind, Lot_Kind.Plot)
	testing.expect_value(t, lot.zone, Zone.None)
	testing.expect_value(t, lot.building_id, u16(0))
	expect_no_building(t, c, 0, 0)
	testing.expect_value(t, lot.terrain, Terrain.Grass)
	corner := city_lot(c, 63, 63)
	testing.expect_value(t, corner.kind, Lot_Kind.Plot)
}

@(test)
far_corner_accepts_a_road :: proc(t: ^testing.T) {
	c := city_new()
	testing.expect(t, paint_road(&c, 63, 63))
	testing.expect_value(t, city_lot(c, 63, 63).kind, Lot_Kind.Road)
}

@(test)
new_city_has_generated_terrain :: proc(t: ^testing.T) {
	c := city_new()
	_, _, lake := find_terrain(c, .Lake)
	_, _, forest := find_terrain(c, .Forest)
	_, _, rock := find_terrain(c, .Rock)
	testing.expect(t, lake)
	testing.expect(t, forest)
	testing.expect(t, rock)
}

find_terrain :: proc(c: City, want: Terrain) -> (x, y: int, ok: bool) {
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			if city_lot(c, x, y).terrain == want {
				return x, y, true
			}
		}
	}
	return 0, 0, false
}

expect_building :: proc(t: ^testing.T, c: City, x, y: int, kind: Building_Kind) {
	got, ok := building_kind_at(c, x, y)
	testing.expect(t, ok)
	testing.expect_value(t, got, kind)
}

expect_no_building :: proc(t: ^testing.T, c: City, x, y: int) {
	_, ok := building_kind_at(c, x, y)
	testing.expect(t, !ok)
}

@(test)
cannot_paint_road_or_zone_on_lake :: proc(t: ^testing.T) {
	c := city_new()
	x, y, found := find_terrain(c, .Lake)
	testing.expect(t, found)
	money := city_money(c)
	testing.expect(t, !paint_road(&c, x, y))
	testing.expect(t, !paint_zone(&c, x, y, .Residential))
	testing.expect_value(t, city_money(c), money)
	lot := city_lot(c, x, y)
	testing.expect_value(t, lot.kind, Lot_Kind.Plot)
	testing.expect_value(t, lot.zone, Zone.None)
	testing.expect_value(t, lot.terrain, Terrain.Lake)
}

@(test)
cannot_paint_road_or_zone_on_rock :: proc(t: ^testing.T) {
	c := city_new()
	x, y, found := find_terrain(c, .Rock)
	testing.expect(t, found)
	money := city_money(c)
	testing.expect(t, !paint_road(&c, x, y))
	testing.expect(t, !paint_zone(&c, x, y, .Residential))
	testing.expect_value(t, city_money(c), money)
	lot := city_lot(c, x, y)
	testing.expect_value(t, lot.kind, Lot_Kind.Plot)
	testing.expect_value(t, lot.zone, Zone.None)
	testing.expect_value(t, lot.terrain, Terrain.Rock)
}

@(test)
cannot_paint_road_or_zone_on_forest :: proc(t: ^testing.T) {
	c := city_new()
	x, y, found := find_terrain(c, .Forest)
	testing.expect(t, found)
	money := city_money(c)
	testing.expect(t, !paint_road(&c, x, y))
	testing.expect(t, !paint_zone(&c, x, y, .Residential))
	testing.expect_value(t, city_money(c), money)
	lot := city_lot(c, x, y)
	testing.expect_value(t, lot.kind, Lot_Kind.Plot)
	testing.expect_value(t, lot.zone, Zone.None)
	testing.expect_value(t, lot.terrain, Terrain.Forest)
}

@(test)
bulldoze_forest_spends_and_turns_to_grass :: proc(t: ^testing.T) {
	c := city_new()
	x, y, found := find_terrain(c, .Forest)
	testing.expect(t, found)
	testing.expect(t, bulldoze(&c, x, y))
	testing.expect_value(t, city_money(c), 1980)
	lot := city_lot(c, x, y)
	testing.expect_value(t, lot.terrain, Terrain.Grass)
	testing.expect_value(t, lot.kind, Lot_Kind.Plot)
}

@(test)
painting_a_road_spends_ten_and_places_it :: proc(t: ^testing.T) {
	c := city_new()
	ok := paint_road(&c, 1, 0)
	testing.expect(t, ok)
	testing.expect_value(t, city_money(c), 1990)
	testing.expect_value(t, city_lot(c, 1, 0).kind, Lot_Kind.Road)
}

@(test)
painting_a_road_on_a_road_does_not_spend :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 1, 0)
	money := city_money(c)
	ok := paint_road(&c, 1, 0)
	testing.expect(t, ok)
	testing.expect_value(t, city_money(c), money)
}

@(test)
painting_a_zone_spends_five :: proc(t: ^testing.T) {
	c := city_new()
	ok := paint_zone(&c, 2, 0, .Residential)
	testing.expect(t, ok)
	testing.expect_value(t, city_money(c), 1995)
	lot := city_lot(c, 2, 0)
	testing.expect_value(t, lot.kind, Lot_Kind.Plot)
	testing.expect_value(t, lot.zone, Zone.Residential)
	expect_no_building(t, c, 2, 0)
}

@(test)
painting_the_same_zone_does_not_spend :: proc(t: ^testing.T) {
	c := city_new()
	paint_zone(&c, 2, 0, .Residential)
	money := city_money(c)
	ok := paint_zone(&c, 2, 0, .Residential)
	testing.expect(t, ok)
	testing.expect_value(t, city_money(c), money)
}

@(test)
cannot_zone_a_road :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 1, 0)
	money := city_money(c)
	ok := paint_zone(&c, 1, 0, .Residential)
	testing.expect(t, !ok)
	testing.expect_value(t, city_money(c), money)
	testing.expect_value(t, city_lot(c, 1, 0).kind, Lot_Kind.Road)
}

pick_first :: proc(n: int) -> int {
	return 0
}

@(test)
grown_house_has_a_building_identity :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Residential)
	tick(&c, pick_first)
	testing.expect(t, city_lot(c, 1, 0).building_id != 0)
	expect_building(t, c, 1, 0, .House)
	testing.expect_value(t, city_lot(c, 2, 0).building_id, u16(0))
	expect_no_building(t, c, 2, 0)
}

@(test)
house_grows_on_road_adjacent_residential :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Residential)
	tick(&c, pick_first)
	expect_building(t, c, 1, 0, .House)
	testing.expect_value(t, city_population(c), 4)
	testing.expect_value(t, city_residential_demand(c), 4)
	testing.expect_value(t, city_commercial_demand(c), 4)
}

@(test)
zoned_plot_without_road_does_not_grow :: proc(t: ^testing.T) {
	c := city_new()
	paint_zone(&c, 5, 5, .Residential)
	tick(&c, pick_first)
	expect_no_building(t, c, 5, 5)
	testing.expect_value(t, city_population(c), 0)
}

@(test)
tick_grows_one_house_and_one_shop :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Residential)
	paint_zone(&c, 0, 1, .Commercial)
	tick(&c, pick_first)
	expect_building(t, c, 1, 0, .House)
	expect_no_building(t, c, 0, 1)
	tick(&c, pick_first)
	expect_building(t, c, 0, 1, .Shop)
	testing.expect_value(t, city_population(c), 4)
	testing.expect_value(t, city_jobs(c), 4)
	testing.expect_value(t, city_residential_demand(c), 8)
	testing.expect_value(t, city_commercial_demand(c), 0)
}

@(test)
tick_grows_at_most_one_house :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 1, 0)
	paint_zone(&c, 0, 0, .Residential)
	paint_zone(&c, 2, 0, .Residential)
	tick(&c, pick_first)
	expect_building(t, c, 0, 0, .House)
	expect_no_building(t, c, 2, 0)
}

@(test)
two_houses_have_distinct_identities :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 1, 0)
	paint_zone(&c, 0, 0, .Residential)
	paint_zone(&c, 2, 0, .Residential)
	tick(&c, pick_first)
	tick(&c, pick_first)
	id_a := city_lot(c, 0, 0).building_id
	id_b := city_lot(c, 2, 0).building_id
	testing.expect(t, id_a != 0)
	testing.expect(t, id_b != 0)
	testing.expect(t, id_a != id_b)
	expect_building(t, c, 0, 0, .House)
	expect_building(t, c, 2, 0, .House)
}

pick_second :: proc(n: int) -> int {
	return 1
}

@(test)
tick_uses_pick_to_choose_house :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 1, 0)
	paint_zone(&c, 0, 0, .Residential)
	paint_zone(&c, 2, 0, .Residential)
	tick(&c, pick_second)
	expect_no_building(t, c, 0, 0)
	expect_building(t, c, 2, 0, .House)
}

@(test)
bulldoze_removes_building_and_keeps_zone :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Residential)
	tick(&c, pick_first)
	ok := bulldoze(&c, 1, 0)
	testing.expect(t, ok)
	lot := city_lot(c, 1, 0)
	testing.expect_value(t, lot.kind, Lot_Kind.Plot)
	testing.expect_value(t, lot.zone, Zone.Residential)
	expect_no_building(t, c, 1, 0)
	testing.expect_value(t, city_population(c), 0)
}

@(test)
tick_collects_tax_on_population :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Residential)
	tick(&c, pick_first)
	testing.expect_value(t, city_money(c), 1989)
}

@(test)
broke_city_cannot_spend :: proc(t: ^testing.T) {
	c := city_new()
	c.money = 9
	testing.expect(t, !paint_road(&c, 0, 0))
	testing.expect_value(t, city_lot(c, 0, 0).kind, Lot_Kind.Plot)
	c.money = 4
	testing.expect(t, !paint_zone(&c, 1, 0, .Commercial))
	testing.expect_value(t, city_lot(c, 1, 0).zone, Zone.None)
}

@(test)
broke_city_cannot_bulldoze_forest :: proc(t: ^testing.T) {
	c := city_new()
	x, y, found := find_terrain(c, .Forest)
	testing.expect(t, found)
	c.money = 19
	testing.expect(t, !bulldoze(&c, x, y))
	testing.expect_value(t, city_lot(c, x, y).terrain, Terrain.Forest)
	testing.expect_value(t, city_money(c), 19)
}

@(test)
house_stays_after_shop_is_bulldozed :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Residential)
	paint_zone(&c, 0, 1, .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	bulldoze(&c, 0, 1)
	expect_building(t, c, 1, 0, .House)
	testing.expect_value(t, city_population(c), 4)
}

@(test)
changing_zone_clears_the_building :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Residential)
	tick(&c, pick_first)
	ok := paint_zone(&c, 1, 0, .Commercial)
	testing.expect(t, ok)
	lot := city_lot(c, 1, 0)
	testing.expect_value(t, lot.zone, Zone.Commercial)
	expect_no_building(t, c, 1, 0)
	testing.expect_value(t, city_population(c), 0)
}

@(test)
save_then_load_restores_lots_and_money :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Residential)
	tick(&c, pick_first)
	path := "city_roundtrip.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, ok := city_load(path)
	testing.expect(t, ok)
	testing.expect_value(t, city_money(loaded), 1989)
	testing.expect_value(t, city_lot(loaded, 0, 0).kind, Lot_Kind.Road)
	expect_building(t, loaded, 1, 0, .House)
	testing.expect_value(t, city_population(loaded), 4)
}

@(test)
save_then_load_round_trips_building_identity :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 1, 0)
	paint_zone(&c, 0, 0, .Residential)
	paint_zone(&c, 2, 0, .Residential)
	tick(&c, pick_first)
	tick(&c, pick_first)
	path := "city_identity.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, ok := city_load(path)
	testing.expect(t, ok)
	id_a := city_lot(loaded, 0, 0).building_id
	id_b := city_lot(loaded, 2, 0).building_id
	testing.expect(t, id_a != 0)
	testing.expect(t, id_b != 0)
	testing.expect(t, id_a != id_b)
	expect_building(t, loaded, 0, 0, .House)
	expect_building(t, loaded, 2, 0, .House)
}

@(test)
save_then_load_restores_terrain :: proc(t: ^testing.T) {
	c := city_new()
	lx, ly, lake := find_terrain(c, .Lake)
	fx, fy, forest := find_terrain(c, .Forest)
	rx, ry, rock := find_terrain(c, .Rock)
	testing.expect(t, lake && forest && rock)
	path := "city_terrain.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, ok := city_load(path)
	testing.expect(t, ok)
	testing.expect_value(t, city_lot(loaded, lx, ly).terrain, Terrain.Lake)
	testing.expect_value(t, city_lot(loaded, fx, fy).terrain, Terrain.Forest)
	testing.expect_value(t, city_lot(loaded, rx, ry).terrain, Terrain.Rock)
}

@(test)
load_missing_file_fails :: proc(t: ^testing.T) {
	_, ok := city_load("city_no_such.save")
	testing.expect(t, !ok)
}

@(test)
load_junk_or_old_size_leaves_city_alone :: proc(t: ^testing.T) {
	c := city_new()
	testing.expect(t, paint_road(&c, 0, 0))
	path := "city_bad.save"
	defer os.remove(path)

	testing.expect(t, os.write_entire_file(path, []u8{9, 9, 9}) == nil)
	_, junk_ok := city_load(path)
	testing.expect(t, !junk_ok)

	old: [1 + 8 + 32 * 32 * 3]u8
	old[0] = 1
	testing.expect(t, os.write_entire_file(path, old[:]) == nil)
	_, old_ok := city_load(path)
	testing.expect(t, !old_ok)

	testing.expect_value(t, city_lot(c, 0, 0).kind, Lot_Kind.Road)
	testing.expect_value(t, city_money(c), 1990)
}
