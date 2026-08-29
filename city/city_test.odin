package city

import "core:os"
import "core:testing"

@(test)
new_city_has_starting_stats :: proc(t: ^testing.T) {
	c := city_new()
	testing.expect_value(t, city_money(c), 2000)
	testing.expect_value(t, city_tax(c), 1)
	testing.expect_value(t, city_population(c), 0)
	testing.expect_value(t, city_jobs(c), 0)
	testing.expect_value(t, city_residential_demand(c), 8)
	testing.expect_value(t, city_commercial_demand(c), 0)
	testing.expect_value(t, city_industrial_demand(c), 0)
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
painting_industrial_spends_five :: proc(t: ^testing.T) {
	c := city_new()
	ok := paint_zone(&c, 2, 0, .Industrial)
	testing.expect(t, ok)
	testing.expect_value(t, city_money(c), 1995)
	lot := city_lot(c, 2, 0)
	testing.expect_value(t, lot.kind, Lot_Kind.Plot)
	testing.expect_value(t, lot.zone, Zone.Industrial)
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
industrial_without_shops_does_not_grow :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Industrial)
	tick(&c, pick_first)
	expect_no_building(t, c, 1, 0)
	testing.expect_value(t, city_jobs(c), 0)
	testing.expect_value(t, city_industrial_demand(c), 0)
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
factory_grows_when_industrial_demand_is_positive :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 1, 0)
	paint_zone(&c, 0, 0, .Residential)
	paint_zone(&c, 2, 0, .Commercial)
	paint_zone(&c, 1, 1, .Industrial)
	tick(&c, pick_first)
	expect_building(t, c, 0, 0, .House)
	expect_no_building(t, c, 2, 0)
	expect_no_building(t, c, 1, 1)
	tick(&c, pick_first)
	expect_building(t, c, 2, 0, .Shop)
	expect_no_building(t, c, 1, 1)
	testing.expect_value(t, city_industrial_demand(c), 4)
	tick(&c, pick_first)
	expect_building(t, c, 1, 1, .Factory)
	testing.expect_value(t, city_population(c), 4)
	testing.expect_value(t, city_jobs(c), 8)
	testing.expect_value(t, city_residential_demand(c), 12)
	testing.expect_value(t, city_commercial_demand(c), 0)
	testing.expect_value(t, city_industrial_demand(c), 0)
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
tick_grows_at_most_one_factory :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 1, 1)
	paint_zone(&c, 1, 0, .Residential)
	paint_zone(&c, 0, 1, .Commercial)
	paint_zone(&c, 2, 1, .Industrial)
	paint_zone(&c, 1, 2, .Industrial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	tick(&c, pick_first)
	expect_building(t, c, 2, 1, .Factory)
	expect_no_building(t, c, 1, 2)
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
player_sets_tax_and_tick_income_uses_it :: proc(t: ^testing.T) {
	c := city_new()
	testing.expect_value(t, city_tax(c), 1)
	city_set_tax(&c, 3)
	testing.expect_value(t, city_tax(c), 3)
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Residential)
	tick(&c, pick_first)
	testing.expect_value(t, city_money(c), 1997)
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
save_then_load_keeps_tax :: proc(t: ^testing.T) {
	c := city_new()
	city_set_tax(&c, 5)
	paint_road(&c, 0, 0)
	path := "city_tax.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, ok := city_load(path)
	testing.expect(t, ok)
	testing.expect_value(t, city_tax(loaded), 5)
	testing.expect_value(t, city_money(loaded), 1990)
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
save_then_load_keeps_industrial_and_factory :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 1, 0)
	paint_zone(&c, 0, 0, .Residential)
	paint_zone(&c, 2, 0, .Commercial)
	paint_zone(&c, 1, 1, .Industrial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	tick(&c, pick_first)
	path := "city_industrial.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, ok := city_load(path)
	testing.expect(t, ok)
	testing.expect_value(t, city_lot(loaded, 1, 1).zone, Zone.Industrial)
	expect_building(t, loaded, 1, 1, .Factory)
	testing.expect_value(t, city_jobs(loaded), 8)
	testing.expect_value(t, city_industrial_demand(loaded), 0)
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

@(test)
stamp_park_on_empty_plot_with_road_spends_and_occupies :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	ok := stamp(&c, 1, 0, .Park)
	testing.expect(t, ok)
	testing.expect_value(t, city_money(c), 1890)
	expect_building(t, c, 1, 0, .Park)
	testing.expect_value(t, city_lot(c, 1, 0).zone, Zone.None)
}

@(test)
stamp_without_road_access_is_refused :: proc(t: ^testing.T) {
	c := city_new()
	money := city_money(c)
	testing.expect(t, !stamp(&c, 5, 5, .Park))
	testing.expect_value(t, city_money(c), money)
	expect_no_building(t, c, 5, 5)
}

@(test)
stamp_on_zoned_plot_clears_the_zone :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Residential)
	testing.expect(t, stamp(&c, 1, 0, .Park))
	testing.expect_value(t, city_lot(c, 1, 0).zone, Zone.None)
	expect_building(t, c, 1, 0, .Park)
}

@(test)
cannot_stamp_on_a_road :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_road(&c, 1, 0)
	money := city_money(c)
	testing.expect(t, !stamp(&c, 1, 0, .Park))
	testing.expect_value(t, city_money(c), money)
	testing.expect_value(t, city_lot(c, 1, 0).kind, Lot_Kind.Road)
	expect_no_building(t, c, 1, 0)
}

@(test)
cannot_stamp_on_lake :: proc(t: ^testing.T) {
	c := city_new()
	x, y, found := find_terrain(c, .Lake)
	testing.expect(t, found)
	testing.expect(t, paint_access_road(&c, x, y))
	money := city_money(c)
	testing.expect(t, !stamp(&c, x, y, .Park))
	testing.expect_value(t, city_money(c), money)
	testing.expect_value(t, city_lot(c, x, y).terrain, Terrain.Lake)
	expect_no_building(t, c, x, y)
}

@(test)
cannot_stamp_on_rock :: proc(t: ^testing.T) {
	c := city_new()
	x, y, found := find_terrain(c, .Rock)
	testing.expect(t, found)
	testing.expect(t, paint_access_road(&c, x, y))
	money := city_money(c)
	testing.expect(t, !stamp(&c, x, y, .Park))
	testing.expect_value(t, city_money(c), money)
	testing.expect_value(t, city_lot(c, x, y).terrain, Terrain.Rock)
	expect_no_building(t, c, x, y)
}

@(test)
cannot_stamp_on_forest :: proc(t: ^testing.T) {
	c := city_new()
	x, y, found := find_terrain(c, .Forest)
	testing.expect(t, found)
	testing.expect(t, paint_access_road(&c, x, y))
	money := city_money(c)
	testing.expect(t, !stamp(&c, x, y, .Park))
	testing.expect_value(t, city_money(c), money)
	testing.expect_value(t, city_lot(c, x, y).terrain, Terrain.Forest)
	expect_no_building(t, c, x, y)
}

@(test)
cannot_stamp_on_an_occupied_plot :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Residential)
	tick(&c, pick_first)
	money := city_money(c)
	testing.expect(t, !stamp(&c, 1, 0, .Park))
	testing.expect_value(t, city_money(c), money)
	expect_building(t, c, 1, 0, .House)
}

@(test)
tower_is_refused_without_a_cardinal_lake :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	money := city_money(c)
	testing.expect(t, !stamp(&c, 1, 0, .Tower))
	testing.expect_value(t, city_money(c), money)
	expect_no_building(t, c, 1, 0)
}

@(test)
tower_stamps_when_a_cardinal_neighbor_is_lake :: proc(t: ^testing.T) {
	c := city_new()
	lx, ly, found := find_terrain(c, .Lake)
	testing.expect(t, found)
	x, y, grass := find_cardinal_grass(c, lx, ly)
	testing.expect(t, grass)
	testing.expect(t, paint_access_road(&c, x, y))
	testing.expect(t, stamp(&c, x, y, .Tower))
	expect_building(t, c, x, y, .Tower)
}

find_cardinal_grass :: proc(c: City, x, y: int) -> (gx, gy: int, ok: bool) {
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for n in cardinal {
		nx, ny := x + n[0], y + n[1]
		if nx < 0 || ny < 0 || nx >= MAP_SIZE || ny >= MAP_SIZE {
			continue
		}
		lot := city_lot(c, nx, ny)
		if lot.kind == .Plot && lot.terrain == .Grass {
			return nx, ny, true
		}
	}
	return 0, 0, false
}

@(test)
all_seven_facilities_stamp_from_the_start :: proc(t: ^testing.T) {
	c := city_new()
	kinds := [6]Building_Kind{.Station, .Park, .School, .Police, .Firehouse, .Hospital}
	for i in 0 ..< 6 {
		testing.expect(t, paint_road(&c, i, 0))
		testing.expect(t, stamp(&c, i, 1, kinds[i]))
		expect_building(t, c, i, 1, kinds[i])
	}
	lx, ly, found := find_terrain(c, .Lake)
	testing.expect(t, found)
	x, y, grass := find_cardinal_grass(c, lx, ly)
	testing.expect(t, grass)
	testing.expect(t, paint_access_road(&c, x, y))
	testing.expect(t, stamp(&c, x, y, .Tower))
	expect_building(t, c, x, y, .Tower)
}

@(test)
station_may_occupy_a_2x2_and_shares_identity :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	testing.expect(t, stamp(&c, 1, 0, .Station, 2))
	expect_building(t, c, 1, 0, .Station)
	expect_building(t, c, 2, 0, .Station)
	expect_building(t, c, 1, 1, .Station)
	expect_building(t, c, 2, 1, .Station)
	id := city_lot(c, 1, 0).building_id
	testing.expect(t, id != 0)
	testing.expect_value(t, city_lot(c, 2, 0).building_id, id)
	testing.expect_value(t, city_lot(c, 1, 1).building_id, id)
	testing.expect_value(t, city_lot(c, 2, 1).building_id, id)
}

@(test)
bulldoze_any_lot_of_2x2_station_removes_the_facility :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	testing.expect(t, stamp(&c, 1, 0, .Station, 2))
	testing.expect(t, bulldoze(&c, 2, 1))
	expect_no_building(t, c, 1, 0)
	expect_no_building(t, c, 2, 0)
	expect_no_building(t, c, 1, 1)
	expect_no_building(t, c, 2, 1)
}

@(test)
growth_still_dribbles_onto_remaining_empty_zoned_plots :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 1, 0)
	paint_zone(&c, 0, 0, .Residential)
	paint_zone(&c, 2, 0, .Residential)
	testing.expect(t, stamp(&c, 0, 0, .Park))
	tick(&c, pick_first)
	expect_building(t, c, 0, 0, .Park)
	expect_building(t, c, 2, 0, .House)
	testing.expect_value(t, city_population(c), 4)
}

@(test)
save_then_load_keeps_facilities_and_footprints :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	testing.expect(t, stamp(&c, 1, 0, .Station, 2))
	testing.expect(t, stamp(&c, 0, 1, .Park))
	path := "city_facilities.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, ok := city_load(path)
	testing.expect(t, ok)
	expect_building(t, loaded, 1, 0, .Station)
	expect_building(t, loaded, 2, 0, .Station)
	expect_building(t, loaded, 1, 1, .Station)
	expect_building(t, loaded, 2, 1, .Station)
	id := city_lot(loaded, 1, 0).building_id
	testing.expect_value(t, city_lot(loaded, 2, 1).building_id, id)
	expect_building(t, loaded, 0, 1, .Park)
}

@(test)
broke_city_cannot_stamp :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	c.money = 99
	testing.expect(t, !stamp(&c, 1, 0, .Park))
	expect_no_building(t, c, 1, 0)
	testing.expect_value(t, city_money(c), 99)
}

@(test)
cannot_stamp_a_2x2_park :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	money := city_money(c)
	testing.expect(t, !stamp(&c, 1, 0, .Park, 2))
	testing.expect_value(t, city_money(c), money)
	expect_no_building(t, c, 1, 0)
}

@(test)
cannot_stamp_a_house :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	money := city_money(c)
	testing.expect(t, !stamp(&c, 1, 0, .House))
	testing.expect_value(t, city_money(c), money)
	expect_no_building(t, c, 1, 0)
}

@(test)
station_2x2_out_of_bounds_is_refused :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 62, 63)
	money := city_money(c)
	testing.expect(t, !stamp(&c, 63, 63, .Station, 2))
	testing.expect_value(t, city_money(c), money)
	expect_no_building(t, c, 63, 63)
}

paint_access_road :: proc(c: ^City, x, y: int) -> bool {
	nx, ny, ok := find_cardinal_grass(c^, x, y)
	if !ok {
		return false
	}
	return paint_road(c, nx, ny)
}
