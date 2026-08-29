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
	testing.expect(t, stamp_near(&c, p[2][0], p[2][1], .Police))
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

grow_house_shop_factory :: proc(c: ^City, house, shop, factory: [2]int) {
	paint_zone(c, house[0], house[1], .Residential)
	paint_zone(c, shop[0], shop[1], .Commercial)
	paint_zone(c, factory[0], factory[1], .Industrial)
	tick(c, pick_first)
	tick(c, pick_first)
	tick(c, pick_first)
}

@(test)
factory_plot_emits_pollution :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 3)
	testing.expect(t, ok)
	grow_house_shop_factory(&c, p[0], p[1], p[2])
	tick(&c, pick_first)
	fx, fy := p[2][0], p[2][1]
	expect_building(t, c, fx, fy, .Factory)
	testing.expect(t, lot_pollution(c, fx, fy) > 0)
}

cardinal_pair :: proc(plots: [][2]int) -> (a, b: [2]int, ok: bool) {
	for i in 0 ..< len(plots) {
		for j in i + 1 ..< len(plots) {
			if abs(plots[i][0] - plots[j][0]) + abs(plots[i][1] - plots[j][1]) == 1 {
				return plots[i], plots[j], true
			}
		}
	}
	return {}, {}, false
}

other_plot :: proc(plots: [][2]int, a, b: [2]int) -> (p: [2]int, ok: bool) {
	for q in plots {
		if q != a && q != b {
			return q, true
		}
	}
	return {}, false
}

@(test)
pollution_spreads_to_cardinal_lots_and_decays :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 3)
	testing.expect(t, ok)
	grow_house_shop_factory(&c, p[0], p[1], p[2])
	tick(&c, pick_first)
	fx, fy := p[2][0], p[2][1]
	src := lot_pollution(c, fx, fy)
	found := false
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for n in cardinal {
		nx, ny := fx + n[0], fy + n[1]
		if nx < 0 || ny < 0 || nx >= MAP_SIZE || ny >= MAP_SIZE {
			continue
		}
		mid := lot_pollution(c, nx, ny)
		testing.expect(t, mid > 0)
		testing.expect(t, mid < src)
		n2x, n2y := fx + 2 * n[0], fy + 2 * n[1]
		if n2x < 0 || n2y < 0 || n2x >= MAP_SIZE || n2y >= MAP_SIZE {
			continue
		}
		testing.expect(t, lot_pollution(c, n2x, n2y) < mid)
		found = true
		break
	}
	testing.expect(t, found)
}

supplied_plot_touching_lake :: proc(c: City) -> (x, y, lx, ly: int, ok: bool) {
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			lot := city_lot(c, x, y)
			if lot.kind != .Plot || lot.terrain != .Grass || lot.building_id != 0 {
				continue
			}
			if !lot_powered(c, x, y) || !lot_watered(c, x, y) || !plot_touches_road(c, x, y) {
				continue
			}
			for n in cardinal {
				nx, ny := x + n[0], y + n[1]
				if nx < 0 || ny < 0 || nx >= MAP_SIZE || ny >= MAP_SIZE {
					continue
				}
				if city_lot(c, nx, ny).terrain == .Lake {
					return x, y, nx, ny, true
				}
			}
		}
	}
	return 0, 0, 0, 0, false
}

@(test)
roads_and_lakes_hold_pollution :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 8)
	testing.expect(t, ok)
	fx, fy, lx, ly, lake_plot := supplied_plot_touching_lake(c)
	testing.expect(t, lake_plot)
	house, shop, picked := two_plots_besides(p[:8], {fx, fy})
	testing.expect(t, picked)
	grow_house_shop_factory(&c, house, shop, {fx, fy})
	tick(&c, pick_first)
	expect_building(t, c, fx, fy, .Factory)
	testing.expect(t, lot_pollution(c, lx, ly) > 0)
	rx, ry, road := find_cardinal_road(c, fx, fy)
	testing.expect(t, road)
	testing.expect(t, lot_pollution(c, rx, ry) > 0)
	ox, oy := fx + (lx - fx) * 2, fy + (ly - fy) * 2
	if ox >= 0 && oy >= 0 && ox < MAP_SIZE && oy < MAP_SIZE {
		testing.expect(t, lot_pollution(c, ox, oy) > 0)
	}
}

two_plots_besides :: proc(plots: [][2]int, skip: [2]int) -> (a, b: [2]int, ok: bool) {
	n := 0
	for q in plots {
		if q == skip {
			continue
		}
		if n == 0 {
			a = q
			n = 1
		} else {
			return a, q, true
		}
	}
	return {}, {}, false
}

@(test)
local_pollution_nibbles_houses_not_shops_or_factories :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 8)
	testing.expect(t, ok)
	house, factory, pair := cardinal_pair(p[:8])
	testing.expect(t, pair)
	shop, shop_ok := other_plot(p[:8], house, factory)
	testing.expect(t, shop_ok)
	grow_house_shop_factory(&c, house, shop, factory)
	tick(&c, pick_first)
	for _ in 0 ..< 5 {
		tick(&c, pick_first)
	}
	hh, hok := building_health_at(c, house[0], house[1])
	sh, sok := building_health_at(c, shop[0], shop[1])
	fh, fok := building_health_at(c, factory[0], factory[1])
	testing.expect(t, hok && sok && fok)
	testing.expect(t, hh < 1)
	testing.expect_value(t, sh, f32(1))
	testing.expect_value(t, fh, f32(1))
}

@(test)
pollution_does_not_nibble_a_park :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 8)
	testing.expect(t, ok)
	house, factory, pair := cardinal_pair(p[:8])
	testing.expect(t, pair)
	shop, shop_ok := other_plot(p[:8], house, factory)
	testing.expect(t, shop_ok)
	park: [2]int
	park_ok := false
	for q in p[:8] {
		if q != house && q != shop && q != factory {
			park = q
			park_ok = true
			break
		}
	}
	testing.expect(t, park_ok)
	testing.expect(t, stamp(&c, park[0], park[1], .Park))
	grow_house_shop_factory(&c, house, shop, factory)
	tick(&c, pick_first)
	for _ in 0 ..< 5 {
		tick(&c, pick_first)
	}
	ph, pok := building_health_at(c, park[0], park[1])
	testing.expect(t, pok)
	testing.expect_value(t, ph, f32(1))
}

@(test)
save_then_load_keeps_pollution_belt :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 3)
	testing.expect(t, ok)
	grow_house_shop_factory(&c, p[0], p[1], p[2])
	tick(&c, pick_first)
	fx, fy := p[2][0], p[2][1]
	want := lot_pollution(c, fx, fy)
	testing.expect(t, want > 0)
	path := "city_pollution.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	testing.expect(t, load_ok)
	testing.expect_value(t, lot_pollution(loaded, fx, fy), want)
	rx, ry, road := find_cardinal_road(loaded, fx, fy)
	testing.expect(t, road)
	testing.expect_value(t, lot_pollution(loaded, rx, ry), lot_pollution(c, rx, ry))
}

@(test)
park_covers_without_power :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	testing.expect(t, stamp(&c, 1, 0, .Park))
	testing.expect(t, !lot_powered(c, 1, 0))
	testing.expect(t, lot_covered(c, 1, 0, .Park))
	testing.expect(t, lot_covered(c, 2, 0, .Park))
}

@(test)
school_has_no_coverage_without_power :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	testing.expect(t, stamp(&c, 1, 0, .School))
	testing.expect(t, !lot_powered(c, 1, 0))
	testing.expect(t, !lot_education(c, 1, 0))
	testing.expect(t, !lot_education(c, 2, 0))
}

@(test)
powered_school_covers_a_square_through_roads :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	testing.expect(t, stamp(&c, 1, 0, .Station))
	testing.expect(t, stamp(&c, 0, 1, .School))
	testing.expect(t, lot_powered(c, 0, 1))
	testing.expect(t, lot_education(c, 0, 1))
	testing.expect(t, lot_education(c, 0, 0))
	testing.expect(t, !lot_education(c, 20, 20))
}

@(test)
park_raises_land_value_without_power :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	testing.expect(t, stamp(&c, 1, 0, .Park))
	testing.expect(t, !lot_powered(c, 2, 0))
	testing.expect(t, lot_land_value(c, 2, 0) > lot_land_value(c, 20, 20))
}

is_empty_grass :: proc(c: City, x, y: int) -> bool {
	if x < 0 || y < 0 || x >= MAP_SIZE || y >= MAP_SIZE {
		return false
	}
	lot := city_lot(c, x, y)
	return lot.kind == .Plot && lot.terrain == .Grass && lot.building_id == 0
}

in_rect :: proc(x, y, x0, y0, w, h: int) -> bool {
	return x >= x0 && y >= y0 && x < x0 + w && y < y0 + h
}

connect_plot_to_network :: proc(c: ^City, x, y, fx, fy: int) -> bool {
	if plot_touches_road(c^, x, y) {
		return true
	}
	visited: [MAP_SIZE * MAP_SIZE]bool
	prev: [MAP_SIZE * MAP_SIZE]int
	queue: [MAP_SIZE * MAP_SIZE]int
	head, tail := 0, 0
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		prev[i] = -1
		if city_lot(c^, i % MAP_SIZE, i / MAP_SIZE).kind == .Road {
			visited[i] = true
			queue[tail] = i
			tail += 1
		}
	}
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	goal := -1
	for head < tail {
		i := queue[head]
		head += 1
		px, py := i % MAP_SIZE, i / MAP_SIZE
		for n in cardinal {
			nx, ny := px + n[0], py + n[1]
			if !is_empty_grass(c^, nx, ny) || in_rect(nx, ny, fx, fy, 2, 2) {
				continue
			}
			ni := ny * MAP_SIZE + nx
			if visited[ni] {
				continue
			}
			visited[ni] = true
			prev[ni] = i
			if abs(nx - x) + abs(ny - y) == 1 {
				goal = ni
				break
			}
			queue[tail] = ni
			tail += 1
		}
		if goal >= 0 {
			break
		}
	}
	if goal < 0 {
		return false
	}
	for goal >= 0 && city_lot(c^, goal % MAP_SIZE, goal / MAP_SIZE).kind != .Road {
		gx, gy := goal % MAP_SIZE, goal / MAP_SIZE
		if !paint_road(c, gx, gy) {
			return false
		}
		goal = prev[goal]
	}
	return plot_touches_road(c^, x, y)
}

rect_supplied :: proc(c: City, x, y: int) -> bool {
	for dy in 0 ..< 2 {
		for dx in 0 ..< 2 {
			if !lot_powered(c, x + dx, y + dy) || !lot_watered(c, x + dx, y + dy) {
				return false
			}
		}
	}
	return true
}

supplied_2x2 :: proc(c: ^City) -> (x, y: int, ok: bool) {
	_, found := supplied_plots(c, 1)
	if !found {
		return 0, 0, false
	}
	c.money = 99999
	for y in 0 ..< MAP_SIZE - 1 {
		for x in 0 ..< MAP_SIZE - 1 {
			if !is_empty_grass(c^, x, y) ||
			   !is_empty_grass(c^, x + 1, y) ||
			   !is_empty_grass(c^, x, y + 1) ||
			   !is_empty_grass(c^, x + 1, y + 1) {
				continue
			}
			near := false
			for dy in 0 ..< 2 {
				for dx in 0 ..< 2 {
					if lot_powered(c^, x + dx, y + dy) && lot_watered(c^, x + dx, y + dy) {
						near = true
					}
				}
			}
			if !near {
				continue
			}
			for dy in 0 ..< 2 {
				for dx in 0 ..< 2 {
					connect_plot_to_network(c, x + dx, y + dy, x, y)
				}
			}
			if rect_supplied(c^, x, y) {
				return x, y, true
			}
		}
	}
	return 0, 0, false
}

stamp_park_near :: proc(c: ^City, x, y: int) -> bool {
	for py in y - 2 ..= y + 3 {
		for px in x - 2 ..= x + 3 {
			if px >= x && px <= x + 1 && py >= y && py <= y + 1 {
				continue
			}
			if stamp(c, px, py, .Park) {
				return true
			}
		}
	}
	return false
}

@(test)
high_land_value_births_a_2x2_house :: proc(t: ^testing.T) {
	c := city_new()
	x, y, ok := supplied_2x2(&c)
	testing.expect(t, ok)
	testing.expect(t, stamp_park_near(&c, x, y))
	for dy in 0 ..< 2 {
		for dx in 0 ..< 2 {
			testing.expect(t, paint_zone(&c, x + dx, y + dy, .Residential))
		}
	}
	tick(&c, pick_first)
	id := city_lot(c, x, y).building_id
	testing.expect(t, id != 0)
	testing.expect_value(t, city_lot(c, x + 1, y).building_id, id)
	testing.expect_value(t, city_lot(c, x, y + 1).building_id, id)
	testing.expect_value(t, city_lot(c, x + 1, y + 1).building_id, id)
	expect_building(t, c, x, y, .House)
}

@(test)
low_land_value_births_a_1x1_even_with_four_plots :: proc(t: ^testing.T) {
	c := city_new()
	x, y, ok := supplied_2x2(&c)
	testing.expect(t, ok)
	for dy in 0 ..< 2 {
		for dx in 0 ..< 2 {
			testing.expect(t, paint_zone(&c, x + dx, y + dy, .Residential))
		}
	}
	tick(&c, pick_first)
	id := city_lot(c, x, y).building_id
	testing.expect(t, id != 0)
	n := 0
	for dy in 0 ..< 2 {
		for dx in 0 ..< 2 {
			if city_lot(c, x + dx, y + dy).building_id == id {
				n += 1
			}
		}
	}
	testing.expect_value(t, n, 1)
	expect_building(t, c, x, y, .House)
}

@(test)
two_by_two_house_population_is_base_times_plots :: proc(t: ^testing.T) {
	c := city_new()
	x, y, ok := supplied_2x2(&c)
	testing.expect(t, ok)
	testing.expect(t, stamp_park_near(&c, x, y))
	for dy in 0 ..< 2 {
		for dx in 0 ..< 2 {
			testing.expect(t, paint_zone(&c, x + dx, y + dy, .Residential))
		}
	}
	tick(&c, pick_first)
	testing.expect_value(t, city_population(c), 16)
}

@(test)
new_house_is_level_1 :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 1)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	tick(&c, pick_first)
	lv, lok := building_level_at(c, p[0][0], p[0][1])
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(1))
}

stamp_near :: proc(c: ^City, x, y: int, kind: Building_Kind) -> bool {
	c.money = max(c.money, STAMP_COST)
	for py in y - COVERAGE_RANGE ..= y + COVERAGE_RANGE {
		for px in x - COVERAGE_RANGE ..= x + COVERAGE_RANGE {
			if px == x && py == y {
				continue
			}
			if kind != .Park && !lot_powered(c^, px, py) {
				continue
			}
			if stamp(c, px, py, kind) {
				return true
			}
		}
	}
	return false
}

@(test)
house_needs_school_to_reach_level_2 :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 1)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	testing.expect(t, stamp_near(&c, hx, hy, .Park))
	paint_zone(&c, hx, hy, .Residential)
	tick(&c, pick_first)
	lv, lok := building_level_at(c, hx, hy)
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(1))
	testing.expect(t, stamp_near(&c, hx, hy, .School))
	tick(&c, pick_first)
	lv, lok = building_level_at(c, hx, hy)
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(2))
	testing.expect_value(t, city_population(c), 8)
}

@(test)
house_needs_hospital_to_reach_level_3 :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	sx, sy := p[1][0], p[1][1]
	paint_zone(&c, hx, hy, .Residential)
	paint_zone(&c, sx, sy, .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	testing.expect(t, stamp_near(&c, hx, hy, .Park))
	testing.expect(t, stamp_near(&c, hx, hy, .School))
	tick(&c, pick_first)
	lv, lok := building_level_at(c, hx, hy)
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(2))
	tick(&c, pick_first)
	lv, lok = building_level_at(c, hx, hy)
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(2))
	testing.expect(t, stamp_near(&c, hx, hy, .Hospital))
	tick(&c, pick_first)
	lv, lok = building_level_at(c, hx, hy)
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(3))
	testing.expect_value(t, city_population(c), 12)
}

@(test)
at_most_one_house_levels_per_tick :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 3)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Residential)
	paint_zone(&c, p[2][0], p[2][1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	tick(&c, pick_first)
	testing.expect(t, stamp_near(&c, p[0][0], p[0][1], .Park))
	testing.expect(t, stamp_near(&c, p[0][0], p[0][1], .School))
	testing.expect(t, lot_covered(c, p[1][0], p[1][1], .Park))
	testing.expect(t, lot_education(c, p[1][0], p[1][1]))
	tick(&c, pick_first)
	a, aok := building_level_at(c, p[0][0], p[0][1])
	b, bok := building_level_at(c, p[1][0], p[1][1])
	testing.expect(t, aok && bok)
	testing.expect(t, a == 2 && b == 1 || a == 1 && b == 2)
}

@(test)
level_up_does_not_grow_the_footprint :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	testing.expect(t, stamp_near(&c, hx, hy, .Park))
	paint_zone(&c, hx, hy, .Residential)
	tick(&c, pick_first)
	testing.expect(t, stamp_near(&c, hx, hy, .School))
	tick(&c, pick_first)
	lv, lok := building_level_at(c, hx, hy)
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(2))
	id := city_lot(c, hx, hy).building_id
	n := 0
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			if city_lot(c, x, y).building_id == id {
				n += 1
			}
		}
	}
	testing.expect_value(t, n, 1)
}

@(test)
abandoned_house_never_levels :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	testing.expect(t, stamp_near(&c, hx, hy, .Park))
	paint_zone(&c, hx, hy, .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	testing.expect(t, stamp_near(&c, hx, hy, .School))
	tx, ty, found := find_building(c, .Tower)
	testing.expect(t, found)
	testing.expect(t, bulldoze(&c, tx, ty))
	for _ in 0 ..< 80 {
		tick(&c, pick_first)
		h, health_ok := building_health_at(c, hx, hy)
		testing.expect(t, health_ok)
		if h <= HEALTH_ABANDONED {
			break
		}
	}
	h, health_ok := building_health_at(c, hx, hy)
	testing.expect(t, health_ok)
	testing.expect(t, h <= HEALTH_ABANDONED)
	tick(&c, pick_first)
	lv, lok := building_level_at(c, hx, hy)
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(1))
}

@(test)
save_then_load_keeps_level_and_footprint :: proc(t: ^testing.T) {
	c := city_new()
	x, y, ok := supplied_2x2(&c)
	testing.expect(t, ok)
	testing.expect(t, stamp_park_near(&c, x, y))
	for dy in 0 ..< 2 {
		for dx in 0 ..< 2 {
			testing.expect(t, paint_zone(&c, x + dx, y + dy, .Residential))
		}
	}
	tick(&c, pick_first)
	id := city_lot(c, x, y).building_id
	testing.expect(t, id != 0)
	lv, lok := building_level_at(c, x, y)
	testing.expect(t, lok)
	path := "city_level.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	testing.expect(t, load_ok)
	llv, llok := building_level_at(loaded, x, y)
	testing.expect(t, llok)
	testing.expect_value(t, llv, lv)
	lid := city_lot(loaded, x, y).building_id
	testing.expect_value(t, city_lot(loaded, x + 1, y).building_id, lid)
	testing.expect_value(t, city_lot(loaded, x, y + 1).building_id, lid)
	testing.expect_value(t, city_lot(loaded, x + 1, y + 1).building_id, lid)
	testing.expect_value(t, city_population(loaded), city_population(c))
}

@(test)
unpowered_hospital_police_firehouse_have_no_coverage :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_road(&c, 1, 0)
	paint_road(&c, 2, 0)
	testing.expect(t, stamp(&c, 0, 1, .Hospital))
	testing.expect(t, stamp(&c, 1, 1, .Police))
	testing.expect(t, stamp(&c, 2, 1, .Firehouse))
	testing.expect(t, !lot_powered(c, 0, 1))
	testing.expect(t, !lot_covered(c, 0, 1, .Hospital))
	testing.expect(t, !lot_covered(c, 1, 1, .Police))
	testing.expect(t, !lot_covered(c, 2, 1, .Firehouse))
}

@(test)
high_land_value_births_a_2x2_shop :: proc(t: ^testing.T) {
	c := city_new()
	x, y, ok := supplied_2x2(&c)
	testing.expect(t, ok)
	rx, ry := -1, -1
	found := false
	for py in 0 ..< MAP_SIZE {
		for px in 0 ..< MAP_SIZE {
			if in_rect(px, py, x, y, 2, 2) {
				continue
			}
			lot := city_lot(c, px, py)
			if lot.kind == .Plot &&
			   lot.terrain == .Grass &&
			   lot.building_id == 0 &&
			   lot_powered(c, px, py) &&
			   lot_watered(c, px, py) &&
			   plot_touches_road(c, px, py) {
				rx, ry = px, py
				found = true
				break
			}
		}
		if found {
			break
		}
	}
	testing.expect(t, found)
	paint_zone(&c, rx, ry, .Residential)
	tick(&c, pick_first)
	testing.expect(t, stamp_park_near(&c, x, y))
	for dy in 0 ..< 2 {
		for dx in 0 ..< 2 {
			testing.expect(t, paint_zone(&c, x + dx, y + dy, .Commercial))
		}
	}
	tick(&c, pick_first)
	id := city_lot(c, x, y).building_id
	testing.expect(t, id != 0)
	testing.expect_value(t, city_lot(c, x + 1, y).building_id, id)
	testing.expect_value(t, city_lot(c, x, y + 1).building_id, id)
	testing.expect_value(t, city_lot(c, x + 1, y + 1).building_id, id)
	expect_building(t, c, x, y, .Shop)
	testing.expect_value(t, city_jobs(c), 16)
}

jammed_house_and_shop :: proc(c: ^City) -> (house, shop: [2]int, rx, ry: int, ok: bool) {
	lx, ly, lake := find_terrain(c^, .Lake)
	if !lake {
		return {}, {}, 0, 0, false
	}
	tx, ty, grass := find_cardinal_grass(c^, lx, ly)
	if !grass {
		return {}, {}, 0, 0, false
	}
	if !paint_access_road(c, tx, ty) {
		return {}, {}, 0, 0, false
	}
	if !stamp(c, tx, ty, .Tower) {
		return {}, {}, 0, 0, false
	}
	road_x, road_y, road := find_cardinal_road(c^, tx, ty)
	if !road {
		return {}, {}, 0, 0, false
	}
	rx, ry = road_x, road_y
	sx, sy, station_plot := find_empty_cardinal_plot(c^, rx, ry)
	if !station_plot {
		return {}, {}, 0, 0, false
	}
	if !stamp(c, sx, sy, .Station) {
		return {}, {}, 0, 0, false
	}
	r2x, r2y, extra := find_empty_cardinal_plot(c^, rx, ry)
	if !extra {
		return {}, {}, 0, 0, false
	}
	if !paint_road(c, r2x, r2y) {
		return {}, {}, 0, 0, false
	}
	hx, hy, house_plot := find_empty_cardinal_plot(c^, rx, ry)
	if !house_plot {
		return {}, {}, 0, 0, false
	}
	cx, cy, shop_plot := find_empty_cardinal_plot(c^, r2x, r2y)
	if !shop_plot {
		return {}, {}, 0, 0, false
	}
	paint_zone(c, hx, hy, .Residential)
	paint_zone(c, cx, cy, .Commercial)
	tick(c, pick_first)
	tick(c, pick_first)
	tick(c, pick_first)
	return {hx, hy}, {cx, cy}, rx, ry, true
}

@(test)
traffic_is_grown_buildings_over_road_lots :: proc(t: ^testing.T) {
	c := city_new()
	house, shop, rx, ry, ok := jammed_house_and_shop(&c)
	testing.expect(t, ok)
	expect_building(t, c, house[0], house[1], .House)
	expect_building(t, c, shop[0], shop[1], .Shop)
	testing.expect_value(t, lot_traffic(c, rx, ry), f32(1))
	testing.expect(t, paint_road(&c, 0, 0))
	testing.expect_value(t, lot_traffic(c, 0, 0), f32(0))
	testing.expect_value(t, lot_traffic(c, rx, ry), f32(1))
}

@(test)
jammed_component_nibbles_grown_buildings_not_facilities :: proc(t: ^testing.T) {
	c := city_new()
	house, shop, rx, ry, ok := jammed_house_and_shop(&c)
	testing.expect(t, ok)
	testing.expect_value(t, lot_traffic(c, rx, ry), f32(1))
	for _ in 0 ..< 5 {
		tick(&c, pick_first)
	}
	sh, sok := building_health_at(c, shop[0], shop[1])
	hh, hok := building_health_at(c, house[0], house[1])
	testing.expect(t, sok && hok)
	testing.expect(t, sh < 1)
	testing.expect(t, hh < 1)
	sx, sy, station := find_building(c, .Station)
	tx, ty, tower := find_building(c, .Tower)
	testing.expect(t, station && tower)
	sth, stok := building_health_at(c, sx, sy)
	th, tok := building_health_at(c, tx, ty)
	testing.expect(t, stok && tok)
	testing.expect_value(t, sth, f32(1))
	testing.expect_value(t, th, f32(1))
}

@(test)
painting_roads_on_the_component_relieves_the_nibble :: proc(t: ^testing.T) {
	c := city_new()
	_, shop, rx, ry, ok := jammed_house_and_shop(&c)
	testing.expect(t, ok)
	for _ in 0 ..< 5 {
		tick(&c, pick_first)
	}
	sh, sok := building_health_at(c, shop[0], shop[1])
	testing.expect(t, sok)
	testing.expect(t, sh < 1)
	testing.expect(t, paint_extra_road_on_component(&c, rx, ry))
	testing.expect_value(t, lot_traffic(c, rx, ry), f32(2) / f32(3))
	for _ in 0 ..< 20 {
		tick(&c, pick_first)
	}
	recovered, rok := building_health_at(c, shop[0], shop[1])
	testing.expect(t, rok)
	testing.expect(t, recovered > sh)
}

paint_extra_road_on_component :: proc(c: ^City, rx, ry: int) -> bool {
	load := lot_traffic(c^, rx, ry)
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			if city_lot(c^, x, y).kind != .Road || lot_traffic(c^, x, y) != load {
				continue
			}
			px, py, ok := find_empty_cardinal_plot(c^, x, y)
			if ok {
				return paint_road(c, px, py)
			}
		}
	}
	return false
}

@(test)
crime_is_higher_next_to_grown_buildings_than_far_away :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	tick(&c, pick_first)
	near := lot_crime(c, p[0][0], p[0][1])
	far := lot_crime(c, 20, 20)
	testing.expect(t, near > far)
}

@(test)
unemployment_raises_crime :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 8)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	tick(&c, pick_first)
	shop := p[1]
	before := lot_crime(c, shop[0], shop[1])
	far: [2]int
	found := false
	for q in p[2:] {
		if max(abs(q[0] - shop[0]), abs(q[1] - shop[1])) > 1 &&
		   max(abs(q[0] - p[0][0]), abs(q[1] - p[0][1])) > 1 {
			far = q
			found = true
			break
		}
	}
	testing.expect(t, found)
	paint_zone(&c, far[0], far[1], .Residential)
	tick(&c, pick_first)
	tick(&c, pick_first)
	testing.expect(t, lot_crime(c, shop[0], shop[1]) > before)
}

@(test)
police_coverage_lowers_crime :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	tick(&c, pick_first)
	sx, sy := p[1][0], p[1][1]
	before := lot_crime(c, sx, sy)
	testing.expect(t, before > 0)
	testing.expect(t, stamp_near(&c, sx, sy, .Police))
	testing.expect(t, lot_covered(c, sx, sy, .Police))
	testing.expect(t, lot_crime(c, sx, sy) < before)
}

@(test)
unpowered_police_does_not_lower_crime :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 2)
	testing.expect(t, ok)
	paint_zone(&c, p[0][0], p[0][1], .Residential)
	paint_zone(&c, p[1][0], p[1][1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	tick(&c, pick_first)
	sx, sy := p[1][0], p[1][1]
	stx, sty, found := find_building(c, .Station)
	testing.expect(t, found)
	testing.expect(t, bulldoze(&c, stx, sty))
	before := lot_crime(c, sx, sy)
	testing.expect(t, before > 0)
	c.money = max(c.money, STAMP_COST)
	stamped := false
	for py in sy - COVERAGE_RANGE ..= sy + COVERAGE_RANGE {
		for px in sx - COVERAGE_RANGE ..= sx + COVERAGE_RANGE {
			if stamp(&c, px, py, .Police) {
				stamped = true
				break
			}
		}
		if stamped {
			break
		}
	}
	testing.expect(t, stamped)
	testing.expect(t, !lot_covered(c, sx, sy, .Police))
	testing.expect_value(t, lot_crime(c, sx, sy), before)
}

@(test)
crime_nibbles_shops_not_houses :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 8)
	testing.expect(t, ok)
	house, shop, pair := cardinal_pair(p[:8])
	testing.expect(t, pair)
	paint_zone(&c, house[0], house[1], .Residential)
	paint_zone(&c, shop[0], shop[1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	tick(&c, pick_first)
	testing.expect(t, lot_crime(c, shop[0], shop[1]) >= CRIME_HIGH)
	for _ in 0 ..< 5 {
		tick(&c, pick_first)
	}
	hh, hok := building_health_at(c, house[0], house[1])
	sh, sok := building_health_at(c, shop[0], shop[1])
	testing.expect(t, hok && sok)
	testing.expect_value(t, hh, f32(1))
	testing.expect(t, sh < 1)
}

@(test)
crime_lowers_land_value :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 8)
	testing.expect(t, ok)
	house, shop, pair := cardinal_pair(p[:8])
	testing.expect(t, pair)
	paint_zone(&c, house[0], house[1], .Residential)
	paint_zone(&c, shop[0], shop[1], .Commercial)
	before := lot_land_value(c, shop[0], shop[1])
	tick(&c, pick_first)
	tick(&c, pick_first)
	tick(&c, pick_first)
	testing.expect(t, lot_crime(c, shop[0], shop[1]) > 0)
	testing.expect(t, lot_land_value(c, shop[0], shop[1]) < before)
}

@(test)
happiness_is_not_an_input_to_crime :: proc(t: ^testing.T) {
	c := city_new()
	p, ok := supplied_plots(&c, 8)
	testing.expect(t, ok)
	house, shop, pair := cardinal_pair(p[:8])
	testing.expect(t, pair)
	paint_zone(&c, house[0], house[1], .Residential)
	paint_zone(&c, shop[0], shop[1], .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	tick(&c, pick_first)
	crime := lot_crime(c, shop[0], shop[1])
	hap := city_happiness(c)
	city_set_tax(&c, TAX_HIGH)
	for _ in 0 ..< 5 {
		tick(&c, pick_first)
	}
	testing.expect(t, city_happiness(c) < hap)
	testing.expect_value(t, lot_crime(c, shop[0], shop[1]), crime)
}
