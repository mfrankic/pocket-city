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
	testing.expect_value(t, city_happiness(c), f32(1))
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
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	tick(&c, pick_first)
	testing.expect(t, city_lot(c, p[0][0], p[0][1]).building_id != 0)
	expect_building(t, c, p[0][0], p[0][1], .House)
	testing.expect_value(t, city_lot(c, p[1][0], p[1][1]).building_id, u16(0))
	expect_no_building(t, c, p[1][0], p[1][1])
}

@(test)
house_grows_on_road_adjacent_residential :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 1)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	tick(&c, pick_first)
	expect_building(t, c, p[0][0], p[0][1], .House)
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
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Commercial)
	tick(&c, pick_first)
	expect_building(t, c, p[0][0], p[0][1], .House)
	expect_no_building(t, c, p[1][0], p[1][1])
	tick(&c, pick_first)
	expect_building(t, c, p[1][0], p[1][1], .Shop)
	testing.expect_value(t, city_population(c), 4)
	testing.expect_value(t, city_jobs(c), 4)
	testing.expect_value(t, city_residential_demand(c), 8)
	testing.expect_value(t, city_commercial_demand(c), 0)
}

@(test)
factory_grows_when_industrial_demand_is_positive :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 3)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Commercial)
	paint_zone(&c, p[2][0], p[2][1], .Industrial)
	tick(&c, pick_first)
	expect_building(t, c, p[0][0], p[0][1], .House)
	expect_no_building(t, c, p[1][0], p[1][1])
	expect_no_building(t, c, p[2][0], p[2][1])
	tick(&c, pick_first)
	expect_building(t, c, p[1][0], p[1][1], .Shop)
	expect_no_building(t, c, p[2][0], p[2][1])
	testing.expect_value(t, city_industrial_demand(c), 4)
	tick(&c, pick_first)
	expect_building(t, c, p[2][0], p[2][1], .Factory)
	testing.expect_value(t, city_population(c), 4)
	testing.expect_value(t, city_jobs(c), 8)
	testing.expect_value(t, city_residential_demand(c), 12)
	testing.expect_value(t, city_commercial_demand(c), 0)
	testing.expect_value(t, city_industrial_demand(c), 0)
}

@(test)
tick_grows_at_most_one_house :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Residential)
	tick(&c, pick_first)
	expect_building(t, c, p[0][0], p[0][1], .House)
	expect_no_building(t, c, p[1][0], p[1][1])
}

@(test)
tick_grows_at_most_one_factory :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 4)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Commercial)
	paint_zone(&c, p[2][0], p[2][1], .Industrial)
	paint_zone(&c, p[3][0], p[3][1], .Industrial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	tick(&c, pick_first)
	expect_building(t, c, p[2][0], p[2][1], .Factory)
	expect_no_building(t, c, p[3][0], p[3][1])
}

@(test)
two_houses_have_distinct_identities :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Residential)
	tick(&c, pick_first)
	tick(&c, pick_first)
	id_a := city_lot(c, p[0][0], p[0][1]).building_id
	id_b := city_lot(c, p[1][0], p[1][1]).building_id
	testing.expect(t, id_a != 0)
	testing.expect(t, id_b != 0)
	testing.expect(t, id_a != id_b)
	expect_building(t, c, p[0][0], p[0][1], .House)
	expect_building(t, c, p[1][0], p[1][1], .House)
}

pick_second :: proc(n: int) -> int {
	return 1
}

@(test)
tick_uses_pick_to_choose_house :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Residential)
	tick(&c, pick_second)
	expect_no_building(t, c, p[0][0], p[0][1])
	expect_building(t, c, p[1][0], p[1][1], .House)
}

@(test)
bulldoze_removes_building_and_keeps_zone :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 1)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	tick(&c, pick_first)
	ok = bulldoze(&c, p[0][0], p[0][1])
	testing.expect(t, ok)
	lot := city_lot(c, p[0][0], p[0][1])
	testing.expect_value(t, lot.kind, Lot_Kind.Plot)
	testing.expect_value(t, lot.zone, Zone.Residential)
	expect_no_building(t, c, p[0][0], p[0][1])
	testing.expect_value(t, city_population(c), 0)
}

@(test)
tick_collects_tax_on_population :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 1)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	money := city_money(c)
	tick(&c, pick_first)
	testing.expect_value(t, city_population(c), 4)
	testing.expect_value(t, city_money(c), money + 4)
}

@(test)
player_sets_tax_and_tick_income_uses_it :: proc(t: ^testing.T) {
	c := city_new()
	testing.expect_value(t, city_tax(c), 1)
	city_set_tax(&c, 3)
	testing.expect_value(t, city_tax(c), 3)
	p, ok := supplied_plots(&c, 1)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	money := city_money(c)
	tick(&c, pick_first)
	testing.expect_value(t, city_money(c), money + 12)
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
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	bulldoze(&c, p[1][0], p[1][1])
	expect_building(t, c, p[0][0], p[0][1], .House)
	testing.expect_value(t, city_population(c), 4)
}

@(test)
changing_zone_clears_the_building :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 1)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	tick(&c, pick_first)
	ok = paint_zone(&c, p[0][0], p[0][1], .Commercial)
	testing.expect(t, ok)
	lot := city_lot(c, p[0][0], p[0][1])
	testing.expect_value(t, lot.zone, Zone.Commercial)
	expect_no_building(t, c, p[0][0], p[0][1])
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
	p, ok := supplied_plots(&c, 1)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	tick(&c, pick_first)
	path := "city_roundtrip.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	testing.expect(t, load_ok)
	testing.expect_value(t, city_money(loaded), city_money(c))
	expect_building(t, loaded, p[0][0], p[0][1], .House)
	testing.expect_value(t, city_population(loaded), 4)
}

@(test)
save_then_load_round_trips_building_identity :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Residential)
	tick(&c, pick_first)
	tick(&c, pick_first)
	path := "city_identity.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	testing.expect(t, load_ok)
	id_a := city_lot(loaded, p[0][0], p[0][1]).building_id
	id_b := city_lot(loaded, p[1][0], p[1][1]).building_id
	testing.expect(t, id_a != 0)
	testing.expect(t, id_b != 0)
	testing.expect(t, id_a != id_b)
	expect_building(t, loaded, p[0][0], p[0][1], .House)
	expect_building(t, loaded, p[1][0], p[1][1], .House)
}

@(test)
save_then_load_keeps_industrial_and_factory :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 3)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Commercial)
	paint_zone(&c, p[2][0], p[2][1], .Industrial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	tick(&c, pick_first)
	path := "city_industrial.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	testing.expect(t, load_ok)
	testing.expect_value(t, city_lot(loaded, p[2][0], p[2][1]).zone, Zone.Industrial)
	expect_building(t, loaded, p[2][0], p[2][1], .Factory)
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
	p, ok := supplied_plots(&c, 1)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	tick(&c, pick_first)
	money := city_money(c)
	testing.expect(t, !stamp(&c, p[0][0], p[0][1], .Park))
	testing.expect_value(t, city_money(c), money)
	expect_building(t, c, p[0][0], p[0][1], .House)
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

find_cardinal_road :: proc(c: City, x, y: int) -> (rx, ry: int, ok: bool) {
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for n in cardinal {
		nx, ny := x + n[0], y + n[1]
		if nx < 0 || ny < 0 || nx >= MAP_SIZE || ny >= MAP_SIZE {
			continue
		}
		if city_lot(c, nx, ny).kind == .Road {
			return nx, ny, true
		}
	}
	return 0, 0, false
}

find_empty_cardinal_plot :: proc(c: City, x, y: int) -> (px, py: int, ok: bool) {
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for n in cardinal {
		nx, ny := x + n[0], y + n[1]
		if nx < 0 || ny < 0 || nx >= MAP_SIZE || ny >= MAP_SIZE {
			continue
		}
		lot := city_lot(c, nx, ny)
		if lot.kind == .Plot && lot.terrain == .Grass && lot.building_id == 0 {
			return nx, ny, true
		}
	}
	return 0, 0, false
}

plot_touches_road :: proc(c: City, x, y: int) -> bool {
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for n in cardinal {
		nx, ny := x + n[0], y + n[1]
		if nx < 0 || ny < 0 || nx >= MAP_SIZE || ny >= MAP_SIZE {
			continue
		}
		if city_lot(c, nx, ny).kind == .Road {
			return true
		}
	}
	return false
}

supplied_plots :: proc(c: ^City, n: int) -> (out: [8][2]int, ok: bool) {
	lx, ly, lake := find_terrain(c^, .Lake)
	if !lake {
		return {}, false
	}
	tx, ty, grass := find_cardinal_grass(c^, lx, ly)
	if !grass {
		return {}, false
	}
	if !paint_access_road(c, tx, ty) {
		return {}, false
	}
	if !stamp(c, tx, ty, .Tower) {
		return {}, false
	}
	rx, ry, road := find_cardinal_road(c^, tx, ty)
	if !road {
		return {}, false
	}
	sx, sy, plot := find_empty_cardinal_plot(c^, rx, ry)
	if !plot {
		return {}, false
	}
	if !stamp(c, sx, sy, .Station) {
		return {}, false
	}
	for dy in 1 ..= n + 2 {
		ny := ry + dy
		if ny >= MAP_SIZE {
			break
		}
		lot := city_lot(c^, rx, ny)
		if lot.kind == .Plot && lot.terrain == .Grass && lot.building_id == 0 {
			paint_road(c, rx, ny)
		}
	}
	count := 0
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			if count >= n {
				return out, true
			}
			lot := city_lot(c^, x, y)
			if lot.kind != .Plot || lot.terrain != .Grass || lot.building_id != 0 {
				continue
			}
			if !lot_powered(c^, x, y) || !lot_watered(c^, x, y) {
				continue
			}
			if !plot_touches_road(c^, x, y) {
				continue
			}
			out[count] = {x, y}
			count += 1
		}
	}
	return out, count >= n
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
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Residential)
	testing.expect(t, stamp(&c, p[0][0], p[0][1], .Park))
	tick(&c, pick_first)
	expect_building(t, c, p[0][0], p[0][1], .Park)
	expect_building(t, c, p[1][0], p[1][1], .House)
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

@(test)
station_powers_plots_on_its_road :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	testing.expect(t, stamp(&c, 1, 0, .Station))
	testing.expect(t, lot_powered(c, 1, 0))
	testing.expect(t, lot_powered(c, 0, 1))
}

@(test)
unconnected_road_stays_dark :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_road(&c, 15, 15)
	testing.expect(t, stamp(&c, 1, 0, .Station))
	testing.expect(t, lot_powered(c, 0, 1))
	testing.expect(t, !lot_powered(c, 15, 16))
}

@(test)
station_powers_only_up_to_capacity :: proc(t: ^testing.T) {
	c := city_new()
	for x in 0 ..= 31 {
		paint_road(&c, x, 0)
	}
	testing.expect(t, stamp(&c, 0, 1, .Station))
	n := 0
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			if lot_powered(c, x, y) {
				n += 1
			}
		}
	}
	testing.expect_value(t, n, SUPPLY_CAPACITY)
	testing.expect(t, lot_powered(c, 32, 0))
	testing.expect(t, !lot_powered(c, 31, 1))
}

@(test)
two_by_two_station_reaches_past_one_by_one_capacity :: proc(t: ^testing.T) {
	c := city_new()
	for x in 0 ..= 31 {
		paint_road(&c, x, 0)
	}
	testing.expect(t, stamp(&c, 0, 1, .Station, 2))
	testing.expect(t, lot_powered(c, 31, 1))
}

@(test)
powered_tower_waters_plots_on_its_road :: proc(t: ^testing.T) {
	c := city_new()
	lx, ly, found := find_terrain(c, .Lake)
	testing.expect(t, found)
	tx, ty, grass := find_cardinal_grass(c, lx, ly)
	testing.expect(t, grass)
	testing.expect(t, paint_access_road(&c, tx, ty))
	testing.expect(t, stamp(&c, tx, ty, .Tower))
	rx, ry, road := find_cardinal_road(c, tx, ty)
	testing.expect(t, road)
	sx, sy, plot := find_empty_cardinal_plot(c, rx, ry)
	testing.expect(t, plot)
	testing.expect(t, stamp(&c, sx, sy, .Station))
	testing.expect(t, lot_powered(c, tx, ty))
	testing.expect(t, lot_watered(c, tx, ty))
	wx, wy, wet := find_empty_cardinal_plot(c, rx, ry)
	testing.expect(t, wet)
	testing.expect(t, lot_watered(c, wx, wy))
}

@(test)
unpowered_tower_supplies_no_water :: proc(t: ^testing.T) {
	c := city_new()
	lx, ly, found := find_terrain(c, .Lake)
	testing.expect(t, found)
	tx, ty, grass := find_cardinal_grass(c, lx, ly)
	testing.expect(t, grass)
	testing.expect(t, paint_access_road(&c, tx, ty))
	testing.expect(t, stamp(&c, tx, ty, .Tower))
	testing.expect(t, !lot_powered(c, tx, ty))
	rx, ry, road := find_cardinal_road(c, tx, ty)
	testing.expect(t, road)
	wx, wy, plot := find_empty_cardinal_plot(c, rx, ry)
	testing.expect(t, plot)
	testing.expect(t, !lot_watered(c, tx, ty))
	testing.expect(t, !lot_watered(c, wx, wy))
}

@(test)
unconnected_road_stays_dry :: proc(t: ^testing.T) {
	c := city_new()
	lx, ly, found := find_terrain(c, .Lake)
	testing.expect(t, found)
	tx, ty, grass := find_cardinal_grass(c, lx, ly)
	testing.expect(t, grass)
	testing.expect(t, paint_access_road(&c, tx, ty))
	testing.expect(t, stamp(&c, tx, ty, .Tower))
	rx, ry, road := find_cardinal_road(c, tx, ty)
	testing.expect(t, road)
	sx, sy, plot := find_empty_cardinal_plot(c, rx, ry)
	testing.expect(t, plot)
	testing.expect(t, stamp(&c, sx, sy, .Station))
	paint_road(&c, 15, 15)
	testing.expect(t, lot_watered(c, tx, ty))
	testing.expect(t, !lot_watered(c, 15, 16))
}

@(test)
save_then_load_recomputes_power_and_water :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 1)
	testing.expect(t, ok)
	x, y := p[0][0], p[0][1]
	testing.expect(t, lot_powered(c, x, y))
	testing.expect(t, lot_watered(c, x, y))
	path := "city_supply.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	testing.expect(t, load_ok)
	testing.expect(t, lot_powered(loaded, x, y))
	testing.expect(t, lot_watered(loaded, x, y))
}

@(test)
painting_a_road_extends_power :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	testing.expect(t, stamp(&c, 1, 0, .Station))
	testing.expect(t, !lot_powered(c, 3, 1))
	paint_road(&c, 2, 0)
	paint_road(&c, 3, 0)
	testing.expect(t, lot_powered(c, 3, 1))
}

@(test)
bulldozing_a_station_cuts_power :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	testing.expect(t, stamp(&c, 1, 0, .Station))
	testing.expect(t, lot_powered(c, 0, 1))
	testing.expect(t, bulldoze(&c, 1, 0))
	testing.expect(t, !lot_powered(c, 0, 1))
}

@(test)
house_does_not_grow_without_power :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Residential)
	tick(&c, pick_first)
	expect_no_building(t, c, 1, 0)
}

@(test)
house_does_not_grow_without_water :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	testing.expect(t, stamp(&c, 1, 0, .Station))
	paint_zone(&c, 0, 1, .Residential)
	tick(&c, pick_first)
	expect_no_building(t, c, 0, 1)
}

@(test)
new_house_has_full_health :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 1)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	tick(&c, pick_first)
	h, health_ok := building_health_at(c, p[0][0], p[0][1])
	testing.expect(t, health_ok)
	testing.expect_value(t, h, f32(1))
	testing.expect_value(t, city_happiness(c), f32(1))
}

find_building :: proc(c: City, kind: Building_Kind) -> (x, y: int, ok: bool) {
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			got, found := building_kind_at(c, x, y)
			if found && got == kind {
				return x, y, true
			}
		}
	}
	return 0, 0, false
}

@(test)
missing_power_abandons_a_house_into_a_husk :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	sx, sy, found := find_building(c, .Station)
	testing.expect(t, found)
	testing.expect(t, bulldoze(&c, sx, sy))
	abandoned := false
	for _ in 0 ..< 80 {
		tick(&c, pick_first)
		h, health_ok := building_health_at(c, p[0][0], p[0][1])
		testing.expect(t, health_ok)
		if h <= HEALTH_ABANDONED {
			testing.expect(t, h > 0)
			testing.expect_value(t, city_population(c), 0)
			lot := city_lot(c, p[0][0], p[0][1])
			testing.expect_value(t, lot.zone, Zone.Residential)
			testing.expect(t, lot.building_id != 0)
			expect_building(t, c, p[0][0], p[0][1], .House)
			abandoned = true
			break
		}
	}
	testing.expect(t, abandoned)
}

@(test)
struggling_house_still_counts_population :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	sx, sy, found := find_building(c, .Station)
	testing.expect(t, found)
	testing.expect(t, bulldoze(&c, sx, sy))
	struggling := false
	for _ in 0 ..< 80 {
		tick(&c, pick_first)
		h, health_ok := building_health_at(c, p[0][0], p[0][1])
		testing.expect(t, health_ok)
		if h < HEALTH_STRUGGLING && h > HEALTH_ABANDONED {
			testing.expect_value(t, city_population(c), 4)
			testing.expect_value(t, city_jobs(c), 4)
			struggling = true
			break
		}
	}
	testing.expect(t, struggling)
}

@(test)
unemployment_nibbles_houses_not_shops :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 3)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Residential)
	paint_zone(&c, p[2][0], p[2][1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	testing.expect_value(t, city_population(c), 8)
	testing.expect_value(t, city_jobs(c), 4)
	for _ in 0 ..< 5 {
		tick(&c, pick_first)
	}
	hh, hok := building_health_at(c, p[0][0], p[0][1])
	sh, sok := building_health_at(c, p[2][0], p[2][1])
	testing.expect(t, hok && sok)
	testing.expect(t, hh < 1)
	testing.expect_value(t, sh, f32(1))
}

@(test)
high_tax_nibbles_health :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	for _ in 0 ..< 5 {
		tick(&c, pick_first)
	}
	h, health_ok := building_health_at(c, p[0][0], p[0][1])
	testing.expect(t, health_ok)
	testing.expect_value(t, h, f32(1))
	city_set_tax(&c, TAX_HIGH)
	for _ in 0 ..< 5 {
		tick(&c, pick_first)
	}
	h, health_ok = building_health_at(c, p[0][0], p[0][1])
	testing.expect(t, health_ok)
	testing.expect(t, h < 1)
}

@(test)
unemployment_does_not_nibble_a_park :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	testing.expect(t, stamp(&c, p[1][0], p[1][1], .Park))
	tick(&c, pick_first)
	for _ in 0 ..< 5 {
		tick(&c, pick_first)
	}
	hh, hok := building_health_at(c, p[0][0], p[0][1])
	ph, pok := building_health_at(c, p[1][0], p[1][1])
	testing.expect(t, hok && pok)
	testing.expect(t, hh < 1)
	testing.expect_value(t, ph, f32(1))
}

@(test)
husk_recovers_when_power_returns :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	sx, sy, found := find_building(c, .Station)
	testing.expect(t, found)
	testing.expect(t, bulldoze(&c, sx, sy))
	for _ in 0 ..< 80 {
		tick(&c, pick_first)
		h, health_ok := building_health_at(c, p[0][0], p[0][1])
		testing.expect(t, health_ok)
		if h <= HEALTH_ABANDONED {
			break
		}
	}
	testing.expect(t, stamp(&c, sx, sy, .Station))
	recovered := false
	for _ in 0 ..< 80 {
		tick(&c, pick_first)
		h, health_ok := building_health_at(c, p[0][0], p[0][1])
		testing.expect(t, health_ok)
		if h > HEALTH_ABANDONED {
			testing.expect_value(t, city_population(c), 4)
			recovered = true
			break
		}
	}
	testing.expect(t, recovered)
}

@(test)
new_growth_skips_husk_plots :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Residential)
	tick(&c, pick_first)
	sx, sy, found := find_building(c, .Station)
	testing.expect(t, found)
	testing.expect(t, bulldoze(&c, sx, sy))
	for _ in 0 ..< 80 {
		tick(&c, pick_first)
		h, health_ok := building_health_at(c, p[0][0], p[0][1])
		testing.expect(t, health_ok)
		if h <= HEALTH_ABANDONED {
			break
		}
	}
	husk_id := city_lot(c, p[0][0], p[0][1]).building_id
	testing.expect(t, husk_id != 0)
	expect_no_building(t, c, p[1][0], p[1][1])
	testing.expect(t, stamp(&c, sx, sy, .Station))
	tick(&c, pick_first)
	testing.expect_value(t, city_lot(c, p[0][0], p[0][1]).building_id, husk_id)
	expect_building(t, c, p[0][0], p[0][1], .House)
	expect_building(t, c, p[1][0], p[1][1], .House)
}

@(test)
missing_water_nibbles_grown_buildings :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	tx, ty, found := find_building(c, .Tower)
	testing.expect(t, found)
	testing.expect(t, bulldoze(&c, tx, ty))
	for _ in 0 ..< 5 {
		tick(&c, pick_first)
	}
	h, health_ok := building_health_at(c, p[0][0], p[0][1])
	testing.expect(t, health_ok)
	testing.expect(t, h < 1)
}

@(test)
happiness_falls_when_buildings_lose_health :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 3)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Residential)
	paint_zone(&c, p[2][0], p[2][1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	for _ in 0 ..< 5 {
		tick(&c, pick_first)
	}
	h, health_ok := building_health_at(c, p[0][0], p[0][1])
	testing.expect(t, health_ok)
	hap := city_happiness(c)
	testing.expect(t, hap < 1)
	testing.expect(t, hap > h)
}

@(test)
save_then_load_keeps_health :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 3)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Residential)
	paint_zone(&c, p[2][0], p[2][1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	for _ in 0 ..< 5 {
		tick(&c, pick_first)
	}
	h, health_ok := building_health_at(c, p[0][0], p[0][1])
	testing.expect(t, health_ok)
	testing.expect(t, h < 1)
	path := "city_health.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	testing.expect(t, load_ok)
	lh, lok := building_health_at(loaded, p[0][0], p[0][1])
	testing.expect(t, lok)
	testing.expect_value(t, lh, h)
	testing.expect_value(t, city_happiness(loaded), city_happiness(c))
}
