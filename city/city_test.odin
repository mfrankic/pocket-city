package city

import "core:os"
import "core:testing"

@(test)
new_city_has_starting_stats :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
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
	defer free(c)
	lot := city_lot(c, 0, 0)
	testing.expect_value(t, lot.kind, Lot_Kind.Plot)
	testing.expect_value(t, lot.zone, Zone.None)
	expect_no_building(t, c, 0, 0)
	testing.expect_value(t, lot.terrain, Terrain.Grass)
	corner := city_lot(c, 63, 63)
	testing.expect_value(t, corner.kind, Lot_Kind.Plot)
}

@(test)
city_lot_answers_occupant_for_inspect_and_stamps :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	empty := city_lot(c, 0, 0)
	testing.expect(t, !empty.occupant.present)

	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Station, 2))
	origin := city_lot(c, 1, 0)
	testing.expect(t, origin.occupant.present)
	testing.expect_value(t, origin.occupant.kind, Building_Kind.Station)
	testing.expect_value(t, origin.occupant.status, Occupant_Status.Finished)
	testing.expect_value(t, origin.occupant.band, Health_Band.None)
	testing.expect(t, origin.occupant.northwest)
	testing.expect_value(t, origin.occupant.size, 2)
	other := city_lot(c, 2, 0)
	testing.expect(t, other.occupant.present)
	testing.expect_value(t, other.occupant.status, Occupant_Status.Finished)
	testing.expect(t, !other.occupant.northwest)
	testing.expect_value(t, other.occupant.size, 2)

	p, plots_ok := supplied_plots(c, 1)
	testing.expect(t, plots_ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	tick(c, pick_first)
	house := city_lot(c, p[0][0], p[0][1])
	testing.expect(t, house.occupant.present)
	testing.expect_value(t, house.occupant.kind, Building_Kind.House)
	testing.expect_value(t, house.occupant.status, Occupant_Status.Construction)
	testing.expect_value(t, house.occupant.band, Health_Band.None)
	testing.expect(t, house.occupant.remaining > 0)
	testing.expect(t, house.occupant.northwest)
	testing.expect_value(t, house.occupant.size, 1)
	await_finished(c, p[0][0], p[0][1])
	house = city_lot(c, p[0][0], p[0][1])
	testing.expect_value(t, house.occupant.status, Occupant_Status.Finished)
	testing.expect_value(t, house.occupant.band, Health_Band.None)
	testing.expect_value(t, house.occupant.health, f32(1))
	testing.expect_value(t, house.occupant.level, u8(1))
}

@(test)
far_corner_accepts_a_road :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	testing.expect(t, paint_road(c, 63, 63))
	testing.expect_value(t, city_lot(c, 63, 63).kind, Lot_Kind.Road)
}

@(test)
new_city_has_generated_terrain :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	_, _, lake := find_terrain(c, .Lake)
	_, _, forest := find_terrain(c, .Forest)
	_, _, rock := find_terrain(c, .Rock)
	testing.expect(t, lake)
	testing.expect(t, forest)
	testing.expect(t, rock)
}

find_terrain :: proc(c: ^City, want: Terrain) -> (x, y: int, ok: bool) {
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			if city_lot(c, x, y).terrain == want {
				return x, y, true
			}
		}
	}
	return 0, 0, false
}

expect_building :: proc(t: ^testing.T, c: ^City, x, y: int, kind: Building_Kind) {
	occ := city_lot(c, x, y).occupant
	testing.expect(t, occ.present)
	testing.expect_value(t, occ.kind, kind)
}

expect_no_building :: proc(t: ^testing.T, c: ^City, x, y: int) {
	testing.expect(t, !city_lot(c, x, y).occupant.present)
}

expect_footprint :: proc(t: ^testing.T, c: ^City, x, y, size: int, kind: Building_Kind) {
	occ := city_lot(c, x, y).occupant
	testing.expect(t, occ.northwest)
	testing.expect_value(t, occ.size, size)
	for dy in 0 ..< size {
		for dx in 0 ..< size {
			expect_building(t, c, x + dx, y + dy, kind)
			if dx != 0 || dy != 0 {
				testing.expect(t, !city_lot(c, x + dx, y + dy).occupant.northwest)
			}
		}
	}
}

in_construction :: proc(c: ^City, x, y: int) -> bool {
	occ := city_lot(c, x, y).occupant
	return occ.present && occ.status == .Construction
}

@(test)
cannot_paint_road_or_zone_on_lake :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	x, y, found := find_terrain(c, .Lake)
	testing.expect(t, found)
	money := city_money(c)
	testing.expect(t, !paint_road(c, x, y))
	testing.expect(t, !paint_zone(c, x, y, .Residential))
	testing.expect_value(t, city_money(c), money)
	lot := city_lot(c, x, y)
	testing.expect_value(t, lot.kind, Lot_Kind.Plot)
	testing.expect_value(t, lot.zone, Zone.None)
	testing.expect_value(t, lot.terrain, Terrain.Lake)
}

@(test)
cannot_paint_road_or_zone_on_rock :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	x, y, found := find_terrain(c, .Rock)
	testing.expect(t, found)
	money := city_money(c)
	testing.expect(t, !paint_road(c, x, y))
	testing.expect(t, !paint_zone(c, x, y, .Residential))
	testing.expect_value(t, city_money(c), money)
	lot := city_lot(c, x, y)
	testing.expect_value(t, lot.kind, Lot_Kind.Plot)
	testing.expect_value(t, lot.zone, Zone.None)
	testing.expect_value(t, lot.terrain, Terrain.Rock)
}

@(test)
cannot_paint_road_or_zone_on_forest :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	x, y, found := find_terrain(c, .Forest)
	testing.expect(t, found)
	money := city_money(c)
	testing.expect(t, !paint_road(c, x, y))
	testing.expect(t, !paint_zone(c, x, y, .Residential))
	testing.expect_value(t, city_money(c), money)
	lot := city_lot(c, x, y)
	testing.expect_value(t, lot.kind, Lot_Kind.Plot)
	testing.expect_value(t, lot.zone, Zone.None)
	testing.expect_value(t, lot.terrain, Terrain.Forest)
}

@(test)
bulldoze_forest_spends_and_turns_to_grass :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	x, y, found := find_terrain(c, .Forest)
	testing.expect(t, found)
	testing.expect(t, bulldoze(c, x, y))
	testing.expect_value(t, city_money(c), 1980)
	lot := city_lot(c, x, y)
	testing.expect_value(t, lot.terrain, Terrain.Grass)
	testing.expect_value(t, lot.kind, Lot_Kind.Plot)
}

@(test)
bulldoze_forest_raises_land_value_without_tick :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	x, y, found := find_terrain(c, .Forest)
	testing.expect(t, found)
	before := city_lot(c, x, y).land_value
	testing.expect(t, bulldoze(c, x, y))
	testing.expect(t, city_lot(c, x, y).land_value > before)
}

@(test)
painting_a_road_spends_ten_and_places_it :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	ok := paint_road(c, 1, 0)
	testing.expect(t, ok)
	testing.expect_value(t, city_money(c), 1990)
	testing.expect_value(t, city_lot(c, 1, 0).kind, Lot_Kind.Road)
}

@(test)
painting_a_road_on_a_road_does_not_spend :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 1, 0)
	money := city_money(c)
	ok := paint_road(c, 1, 0)
	testing.expect(t, ok)
	testing.expect_value(t, city_money(c), money)
}

@(test)
painting_a_zone_spends_five :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	ok := paint_zone(c, 2, 0, .Residential)
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
	defer free(c)
	ok := paint_zone(c, 2, 0, .Industrial)
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
	defer free(c)
	paint_zone(c, 2, 0, .Residential)
	money := city_money(c)
	ok := paint_zone(c, 2, 0, .Residential)
	testing.expect(t, ok)
	testing.expect_value(t, city_money(c), money)
}

@(test)
cannot_zone_a_road :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 1, 0)
	money := city_money(c)
	ok := paint_zone(c, 1, 0, .Residential)
	testing.expect(t, !ok)
	testing.expect_value(t, city_money(c), money)
	testing.expect_value(t, city_lot(c, 1, 0).kind, Lot_Kind.Road)
}

pick_first :: proc(n: int) -> int {
	return 0
}

@(test)
grown_house_occupies_one_plot :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	tick(c, pick_first)
	expect_building(t, c, p[0][0], p[0][1], .House)
	size := city_lot(c, p[0][0], p[0][1]).occupant.size
	nw := city_lot(c, p[0][0], p[0][1]).occupant.northwest
	testing.expect(t, nw)
	testing.expect_value(t, size, 1)
	expect_no_building(t, c, p[1][0], p[1][1])
}

@(test)
house_grows_on_road_adjacent_residential :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	await_finished(c, p[0][0], p[0][1])
	expect_building(t, c, p[0][0], p[0][1], .House)
	testing.expect_value(t, city_population(c), 4)
	testing.expect_value(t, city_residential_demand(c), 4)
	testing.expect_value(t, city_commercial_demand(c), 4)
}

@(test)
zoned_plot_without_road_does_not_grow :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_zone(c, 5, 5, .Residential)
	tick(c, pick_first)
	expect_no_building(t, c, 5, 5)
	testing.expect_value(t, city_population(c), 0)
}

@(test)
industrial_without_shops_does_not_grow :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	paint_zone(c, 1, 0, .Industrial)
	tick(c, pick_first)
	expect_no_building(t, c, 1, 0)
	testing.expect_value(t, city_jobs(c), 0)
	testing.expect_value(t, city_industrial_demand(c), 0)
}

@(test)
tick_grows_one_house_and_one_shop :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	tick(c, pick_first)
	expect_building(t, c, p[0][0], p[0][1], .House)
	expect_no_building(t, c, p[1][0], p[1][1])
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	expect_building(t, c, p[1][0], p[1][1], .Shop)
	await_finished(c, p[1][0], p[1][1])
	testing.expect_value(t, city_population(c), 4)
	testing.expect_value(t, city_jobs(c), 4)
	testing.expect_value(t, city_residential_demand(c), 8)
	testing.expect_value(t, city_commercial_demand(c), 0)
}

@(test)
factory_grows_when_industrial_demand_is_positive :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 3)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	paint_zone(c, p[2][0], p[2][1], .Industrial)
	tick(c, pick_first)
	expect_building(t, c, p[0][0], p[0][1], .House)
	expect_no_building(t, c, p[1][0], p[1][1])
	expect_no_building(t, c, p[2][0], p[2][1])
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	expect_building(t, c, p[1][0], p[1][1], .Shop)
	expect_no_building(t, c, p[2][0], p[2][1])
	await_finished(c, p[1][0], p[1][1])
	testing.expect_value(t, city_industrial_demand(c), 4)
	tick(c, pick_first)
	expect_building(t, c, p[2][0], p[2][1], .Factory)
	await_finished(c, p[2][0], p[2][1])
	testing.expect_value(t, city_population(c), 4)
	testing.expect_value(t, city_jobs(c), 8)
	testing.expect_value(t, city_residential_demand(c), 12)
	testing.expect_value(t, city_commercial_demand(c), 0)
	testing.expect_value(t, city_industrial_demand(c), 0)
}

@(test)
tick_grows_at_most_one_house :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Residential)
	tick(c, pick_first)
	expect_building(t, c, p[0][0], p[0][1], .House)
	expect_no_building(t, c, p[1][0], p[1][1])
}

@(test)
tick_grows_at_most_one_factory :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 4)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	paint_zone(c, p[2][0], p[2][1], .Industrial)
	paint_zone(c, p[3][0], p[3][1], .Industrial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	tick(c, pick_first)
	expect_building(t, c, p[2][0], p[2][1], .Factory)
	expect_no_building(t, c, p[3][0], p[3][1])
}

@(test)
two_houses_each_occupy_one_plot :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Residential)
	tick(c, pick_first)
	tick(c, pick_first)
	size_a := city_lot(c, p[0][0], p[0][1]).occupant.size
	nw_a := city_lot(c, p[0][0], p[0][1]).occupant.northwest
	size_b := city_lot(c, p[1][0], p[1][1]).occupant.size
	nw_b := city_lot(c, p[1][0], p[1][1]).occupant.northwest
	testing.expect(t, nw_a && nw_b)
	testing.expect_value(t, size_a, 1)
	testing.expect_value(t, size_b, 1)
	expect_building(t, c, p[0][0], p[0][1], .House)
	expect_building(t, c, p[1][0], p[1][1], .House)
	ra_occ := city_lot(c, p[0][0], p[0][1]).occupant
	ra := ra_occ.remaining
	aok := ra_occ.present
	o5 := city_lot(c, p[1][0], p[1][1]).occupant
	rb := o5.remaining
	bok := o5.present
	testing.expect(t, aok && bok)
	testing.expect(t, ra > 0 && rb > 0)
}

pick_second :: proc(n: int) -> int {
	return 1
}

@(test)
tick_uses_pick_to_choose_house :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Residential)
	tick(c, pick_second)
	expect_no_building(t, c, p[0][0], p[0][1])
	expect_building(t, c, p[1][0], p[1][1], .House)
}

@(test)
bulldoze_removes_building_and_keeps_zone :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	tick(c, pick_first)
	ok = bulldoze(c, p[0][0], p[0][1])
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
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	await_finished(c, p[0][0], p[0][1])
	money := city_money(c)
	maintenance := maintenance_cost(c)
	tick(c, pick_first)
	testing.expect_value(t, city_population(c), 4)
	testing.expect_value(t, city_money(c), money + 4 - maintenance)
}

@(test)
city_set_money_sets_the_treasury :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	city_set_money(c, 9)
	testing.expect_value(t, city_money(c), 9)
	city_set_money(c, -1)
	testing.expect_value(t, city_money(c), 0)
}

@(test)
player_sets_tax_and_tick_income_uses_it :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	testing.expect_value(t, city_tax(c), 1)
	city_set_tax(c, 3)
	testing.expect_value(t, city_tax(c), 3)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	await_finished(c, p[0][0], p[0][1])
	money := city_money(c)
	maintenance := maintenance_cost(c)
	tick(c, pick_first)
	testing.expect_value(t, city_money(c), money + 12 - maintenance)
}

@(test)
broke_city_cannot_spend :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	city_set_money(c, 9)
	testing.expect(t, !paint_road(c, 0, 0))
	testing.expect_value(t, city_lot(c, 0, 0).kind, Lot_Kind.Plot)
	city_set_money(c, 4)
	testing.expect(t, !paint_zone(c, 1, 0, .Commercial))
	testing.expect_value(t, city_lot(c, 1, 0).zone, Zone.None)
}

@(test)
broke_city_cannot_bulldoze_forest :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	x, y, found := find_terrain(c, .Forest)
	testing.expect(t, found)
	city_set_money(c, 19)
	testing.expect(t, !bulldoze(c, x, y))
	testing.expect_value(t, city_lot(c, x, y).terrain, Terrain.Forest)
	testing.expect_value(t, city_money(c), 19)
}

@(test)
house_stays_after_shop_is_bulldozed :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	bulldoze(c, p[1][0], p[1][1])
	expect_building(t, c, p[0][0], p[0][1], .House)
	testing.expect_value(t, city_population(c), 4)
}

@(test)
changing_zone_clears_the_building :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	tick(c, pick_first)
	ok = paint_zone(c, p[0][0], p[0][1], .Commercial)
	testing.expect(t, ok)
	lot := city_lot(c, p[0][0], p[0][1])
	testing.expect_value(t, lot.zone, Zone.Commercial)
	expect_no_building(t, c, p[0][0], p[0][1])
	testing.expect_value(t, city_population(c), 0)
}

@(test)
save_then_load_keeps_tax :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	city_set_tax(c, 5)
	paint_road(c, 0, 0)
	path := "city_tax.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, ok := city_load(path)
	defer free(loaded)
	testing.expect(t, ok)
	testing.expect_value(t, city_tax(loaded), 5)
	testing.expect_value(t, city_money(loaded), 1990)
}

@(test)
save_then_load_restores_lots_and_money :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	await_finished(c, p[0][0], p[0][1])
	path := "city_roundtrip.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	defer free(loaded)
	testing.expect(t, load_ok)
	testing.expect_value(t, city_money(loaded), city_money(c))
	expect_building(t, loaded, p[0][0], p[0][1], .House)
	testing.expect_value(t, city_population(loaded), 4)
}

@(test)
save_then_load_keeps_two_house_footprints :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Residential)
	tick(c, pick_first)
	tick(c, pick_first)
	path := "city_identity.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	defer free(loaded)
	testing.expect(t, load_ok)
	size_a := city_lot(loaded, p[0][0], p[0][1]).occupant.size
	nw_a := city_lot(loaded, p[0][0], p[0][1]).occupant.northwest
	size_b := city_lot(loaded, p[1][0], p[1][1]).occupant.size
	nw_b := city_lot(loaded, p[1][0], p[1][1]).occupant.northwest
	testing.expect(t, nw_a && nw_b)
	testing.expect_value(t, size_a, 1)
	testing.expect_value(t, size_b, 1)
	expect_building(t, loaded, p[0][0], p[0][1], .House)
	expect_building(t, loaded, p[1][0], p[1][1], .House)
}

@(test)
save_then_load_keeps_industrial_and_factory :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 3)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	paint_zone(c, p[2][0], p[2][1], .Industrial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	tick(c, pick_first)
	await_finished(c, p[2][0], p[2][1])
	path := "city_industrial.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	defer free(loaded)
	testing.expect(t, load_ok)
	testing.expect_value(t, city_lot(loaded, p[2][0], p[2][1]).zone, Zone.Industrial)
	expect_building(t, loaded, p[2][0], p[2][1], .Factory)
	testing.expect_value(t, city_jobs(loaded), 8)
	testing.expect_value(t, city_industrial_demand(loaded), 0)
}

@(test)
save_then_load_restores_terrain :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	lx, ly, lake := find_terrain(c, .Lake)
	fx, fy, forest := find_terrain(c, .Forest)
	rx, ry, rock := find_terrain(c, .Rock)
	testing.expect(t, lake && forest && rock)
	path := "city_terrain.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, ok := city_load(path)
	defer free(loaded)
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
	defer free(c)
	testing.expect(t, paint_road(c, 0, 0))
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
	defer free(c)
	paint_road(c, 0, 0)
	ok := stamp(c, 1, 0, .Park)
	testing.expect(t, ok)
	testing.expect_value(t, city_money(c), 1890)
	expect_building(t, c, 1, 0, .Park)
	testing.expect_value(t, city_lot(c, 1, 0).zone, Zone.None)
}

@(test)
stamp_without_road_access_is_refused :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	money := city_money(c)
	testing.expect(t, !stamp(c, 5, 5, .Park))
	testing.expect_value(t, city_money(c), money)
	expect_no_building(t, c, 5, 5)
}

@(test)
stamp_on_zoned_plot_clears_the_zone :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	paint_zone(c, 1, 0, .Residential)
	testing.expect(t, stamp(c, 1, 0, .Park))
	testing.expect_value(t, city_lot(c, 1, 0).zone, Zone.None)
	expect_building(t, c, 1, 0, .Park)
}

@(test)
cannot_stamp_on_a_road :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	paint_road(c, 1, 0)
	money := city_money(c)
	testing.expect(t, !stamp(c, 1, 0, .Park))
	testing.expect_value(t, city_money(c), money)
	testing.expect_value(t, city_lot(c, 1, 0).kind, Lot_Kind.Road)
	expect_no_building(t, c, 1, 0)
}

@(test)
cannot_stamp_on_lake :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	x, y, found := find_terrain(c, .Lake)
	testing.expect(t, found)
	testing.expect(t, paint_access_road(c, x, y))
	money := city_money(c)
	testing.expect(t, !stamp(c, x, y, .Park))
	testing.expect_value(t, city_money(c), money)
	testing.expect_value(t, city_lot(c, x, y).terrain, Terrain.Lake)
	expect_no_building(t, c, x, y)
}

@(test)
cannot_stamp_on_rock :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	x, y, found := find_terrain(c, .Rock)
	testing.expect(t, found)
	testing.expect(t, paint_access_road(c, x, y))
	money := city_money(c)
	testing.expect(t, !stamp(c, x, y, .Park))
	testing.expect_value(t, city_money(c), money)
	testing.expect_value(t, city_lot(c, x, y).terrain, Terrain.Rock)
	expect_no_building(t, c, x, y)
}

@(test)
cannot_stamp_on_forest :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	x, y, found := find_terrain(c, .Forest)
	testing.expect(t, found)
	testing.expect(t, paint_access_road(c, x, y))
	money := city_money(c)
	testing.expect(t, !stamp(c, x, y, .Park))
	testing.expect_value(t, city_money(c), money)
	testing.expect_value(t, city_lot(c, x, y).terrain, Terrain.Forest)
	expect_no_building(t, c, x, y)
}

@(test)
cannot_stamp_on_an_occupied_plot :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	tick(c, pick_first)
	money := city_money(c)
	testing.expect(t, !stamp(c, p[0][0], p[0][1], .Park))
	testing.expect_value(t, city_money(c), money)
	expect_building(t, c, p[0][0], p[0][1], .House)
}

@(test)
tower_is_refused_without_a_cardinal_lake :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	money := city_money(c)
	testing.expect(t, !stamp(c, 1, 0, .Tower))
	testing.expect_value(t, city_money(c), money)
	expect_no_building(t, c, 1, 0)
}

@(test)
tower_stamps_when_a_cardinal_neighbor_is_lake :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	lx, ly, found := find_terrain(c, .Lake)
	testing.expect(t, found)
	x, y, grass := find_cardinal_grass(c, lx, ly)
	testing.expect(t, grass)
	testing.expect(t, paint_access_road(c, x, y))
	testing.expect(t, stamp(c, x, y, .Tower))
	expect_building(t, c, x, y, .Tower)
}

find_cardinal_grass :: proc(c: ^City, x, y: int) -> (gx, gy: int, ok: bool) {
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

find_cardinal_road :: proc(c: ^City, x, y: int) -> (rx, ry: int, ok: bool) {
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

find_empty_cardinal_plot :: proc(c: ^City, x, y: int) -> (px, py: int, ok: bool) {
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for n in cardinal {
		nx, ny := x + n[0], y + n[1]
		if nx < 0 || ny < 0 || nx >= MAP_SIZE || ny >= MAP_SIZE {
			continue
		}
		if is_empty_grass(c, nx, ny) {
			return nx, ny, true
		}
	}
	return 0, 0, false
}

plot_touches_road :: proc(c: ^City, x, y: int) -> bool {
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
	lx, ly, lake := find_terrain(c, .Lake)
	if !lake {
		return {}, false
	}
	tx, ty, grass := find_cardinal_grass(c, lx, ly)
	if !grass {
		return {}, false
	}
	if !paint_access_road(c, tx, ty) {
		return {}, false
	}
	if !stamp(c, tx, ty, .Tower) {
		return {}, false
	}
	rx, ry, road := find_cardinal_road(c, tx, ty)
	if !road {
		return {}, false
	}
	sx, sy, plot := find_empty_cardinal_plot(c, rx, ry)
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
		if is_empty_grass(c, rx, ny) {
			paint_road(c, rx, ny)
		}
	}
	count := 0
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			if count >= n {
				return out, true
			}
			if !is_empty_grass(c, x, y) {
				continue
			}
			if !city_lot(c, x, y).powered || !city_lot(c, x, y).watered {
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

@(test)
all_seven_facilities_stamp_from_the_start :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	kinds := [6]Building_Kind{.Station, .Park, .School, .Police, .Firehouse, .Hospital}
	for i in 0 ..< 6 {
		testing.expect(t, paint_road(c, i, 0))
		testing.expect(t, stamp(c, i, 1, kinds[i]))
		expect_building(t, c, i, 1, kinds[i])
	}
	lx, ly, found := find_terrain(c, .Lake)
	testing.expect(t, found)
	x, y, grass := find_cardinal_grass(c, lx, ly)
	testing.expect(t, grass)
	testing.expect(t, paint_access_road(c, x, y))
	testing.expect(t, stamp(c, x, y, .Tower))
	expect_building(t, c, x, y, .Tower)
}

@(test)
station_occupies_a_2x2 :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Station, 2))
	expect_footprint(t, c, 1, 0, 2, .Station)
}

@(test)
bulldoze_any_lot_of_2x2_station_removes_the_facility :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Station, 2))
	testing.expect(t, bulldoze(c, 2, 1))
	expect_no_building(t, c, 1, 0)
	expect_no_building(t, c, 2, 0)
	expect_no_building(t, c, 1, 1)
	expect_no_building(t, c, 2, 1)
}

@(test)
growth_still_dribbles_onto_remaining_empty_zoned_plots :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Residential)
	testing.expect(t, stamp(c, p[0][0], p[0][1], .Park))
	await_finished(c, p[1][0], p[1][1])
	expect_building(t, c, p[0][0], p[0][1], .Park)
	expect_building(t, c, p[1][0], p[1][1], .House)
	testing.expect_value(t, city_population(c), 4)
}

@(test)
save_then_load_keeps_facilities_and_footprints :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Station, 2))
	testing.expect(t, stamp(c, 0, 1, .Park))
	path := "city_facilities.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, ok := city_load(path)
	defer free(loaded)
	testing.expect(t, ok)
	expect_footprint(t, loaded, 1, 0, 2, .Station)
	expect_building(t, loaded, 0, 1, .Park)
}

@(test)
broke_city_cannot_stamp :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	city_set_money(c, 99)
	testing.expect(t, !stamp(c, 1, 0, .Park))
	expect_no_building(t, c, 1, 0)
	testing.expect_value(t, city_money(c), 99)
}

@(test)
cannot_stamp_a_2x2_park :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	money := city_money(c)
	testing.expect(t, !stamp(c, 1, 0, .Park, 2))
	testing.expect_value(t, city_money(c), money)
	expect_no_building(t, c, 1, 0)
}

@(test)
cannot_stamp_a_house :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	money := city_money(c)
	testing.expect(t, !stamp(c, 1, 0, .House))
	testing.expect_value(t, city_money(c), money)
	expect_no_building(t, c, 1, 0)
}

@(test)
station_2x2_out_of_bounds_is_refused :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 62, 63)
	money := city_money(c)
	testing.expect(t, !stamp(c, 63, 63, .Station, 2))
	testing.expect_value(t, city_money(c), money)
	expect_no_building(t, c, 63, 63)
}

paint_access_road :: proc(c: ^City, x, y: int) -> bool {
	nx, ny, ok := find_cardinal_grass(c, x, y)
	if !ok {
		return false
	}
	return paint_road(c, nx, ny)
}

@(test)
station_powers_plots_on_its_road :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Station))
	testing.expect(t, city_lot(c, 1, 0).powered)
	testing.expect(t, city_lot(c, 0, 1).powered)
}

@(test)
unconnected_road_stays_dark :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	paint_road(c, 15, 15)
	testing.expect(t, stamp(c, 1, 0, .Station))
	testing.expect(t, city_lot(c, 0, 1).powered)
	testing.expect(t, !city_lot(c, 15, 16).powered)
}

@(test)
station_powers_only_up_to_capacity :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	for x in 0 ..= 31 {
		paint_road(c, x, 0)
	}
	testing.expect(t, stamp(c, 0, 1, .Station))
	n := 0
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			if city_lot(c, x, y).powered {
				n += 1
			}
		}
	}
	testing.expect_value(t, n, SUPPLY_CAPACITY)
	testing.expect(t, city_lot(c, 32, 0).powered)
	testing.expect(t, !city_lot(c, 31, 1).powered)
}

@(test)
two_by_two_station_reaches_past_one_by_one_capacity :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	for x in 0 ..= 31 {
		paint_road(c, x, 0)
	}
	testing.expect(t, stamp(c, 0, 1, .Station, 2))
	testing.expect(t, city_lot(c, 31, 1).powered)
}

@(test)
powered_tower_waters_plots_on_its_road :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	lx, ly, found := find_terrain(c, .Lake)
	testing.expect(t, found)
	tx, ty, grass := find_cardinal_grass(c, lx, ly)
	testing.expect(t, grass)
	testing.expect(t, paint_access_road(c, tx, ty))
	testing.expect(t, stamp(c, tx, ty, .Tower))
	rx, ry, road := find_cardinal_road(c, tx, ty)
	testing.expect(t, road)
	sx, sy, plot := find_empty_cardinal_plot(c, rx, ry)
	testing.expect(t, plot)
	testing.expect(t, stamp(c, sx, sy, .Station))
	testing.expect(t, city_lot(c, tx, ty).powered)
	testing.expect(t, city_lot(c, tx, ty).watered)
	wx, wy, wet := find_empty_cardinal_plot(c, rx, ry)
	testing.expect(t, wet)
	testing.expect(t, city_lot(c, wx, wy).watered)
}

@(test)
unpowered_tower_supplies_no_water :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	lx, ly, found := find_terrain(c, .Lake)
	testing.expect(t, found)
	tx, ty, grass := find_cardinal_grass(c, lx, ly)
	testing.expect(t, grass)
	testing.expect(t, paint_access_road(c, tx, ty))
	testing.expect(t, stamp(c, tx, ty, .Tower))
	testing.expect(t, !city_lot(c, tx, ty).powered)
	rx, ry, road := find_cardinal_road(c, tx, ty)
	testing.expect(t, road)
	wx, wy, plot := find_empty_cardinal_plot(c, rx, ry)
	testing.expect(t, plot)
	testing.expect(t, !city_lot(c, tx, ty).watered)
	testing.expect(t, !city_lot(c, wx, wy).watered)
}

@(test)
unconnected_road_stays_dry :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	lx, ly, found := find_terrain(c, .Lake)
	testing.expect(t, found)
	tx, ty, grass := find_cardinal_grass(c, lx, ly)
	testing.expect(t, grass)
	testing.expect(t, paint_access_road(c, tx, ty))
	testing.expect(t, stamp(c, tx, ty, .Tower))
	rx, ry, road := find_cardinal_road(c, tx, ty)
	testing.expect(t, road)
	sx, sy, plot := find_empty_cardinal_plot(c, rx, ry)
	testing.expect(t, plot)
	testing.expect(t, stamp(c, sx, sy, .Station))
	paint_road(c, 15, 15)
	testing.expect(t, city_lot(c, tx, ty).watered)
	testing.expect(t, !city_lot(c, 15, 16).watered)
}

@(test)
save_then_load_recomputes_power_and_water :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	x, y := p[0][0], p[0][1]
	testing.expect(t, city_lot(c, x, y).powered)
	testing.expect(t, city_lot(c, x, y).watered)
	path := "city_supply.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	defer free(loaded)
	testing.expect(t, load_ok)
	testing.expect(t, city_lot(loaded, x, y).powered)
	testing.expect(t, city_lot(loaded, x, y).watered)
}

@(test)
painting_a_road_extends_power :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Station))
	testing.expect(t, !city_lot(c, 3, 1).powered)
	paint_road(c, 2, 0)
	paint_road(c, 3, 0)
	testing.expect(t, city_lot(c, 3, 1).powered)
}

@(test)
bulldozing_a_station_cuts_power :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Station))
	testing.expect(t, city_lot(c, 0, 1).powered)
	testing.expect(t, bulldoze(c, 1, 0))
	testing.expect(t, !city_lot(c, 0, 1).powered)
}

@(test)
house_does_not_grow_without_power :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	paint_zone(c, 1, 0, .Residential)
	tick(c, pick_first)
	expect_no_building(t, c, 1, 0)
}

@(test)
house_does_not_grow_without_water :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Station))
	paint_zone(c, 0, 1, .Residential)
	tick(c, pick_first)
	expect_no_building(t, c, 0, 1)
}

@(test)
new_house_has_full_health :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	await_finished(c, p[0][0], p[0][1])
	h_occ := city_lot(c, p[0][0], p[0][1]).occupant
	h := h_occ.health
	health_ok := h_occ.present
	testing.expect(t, health_ok)
	testing.expect_value(t, h, f32(1))
	testing.expect_value(t, city_happiness(c), f32(1))
}

find_building :: proc(c: ^City, kind: Building_Kind) -> (x, y: int, ok: bool) {
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			occ := city_lot(c, x, y).occupant
			if occ.present && occ.kind == kind {
				return x, y, true
			}
		}
	}
	return 0, 0, false
}

@(test)
missing_power_abandons_a_house_into_a_husk :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	await_full_health(c, p[0][0], p[0][1])
	sx, sy, found := find_building(c, .Station)
	testing.expect(t, found)
	testing.expect(t, bulldoze(c, sx, sy))
	abandoned := false
	for _ in 0 ..< 80 {
		tick(c, pick_first)
		o8 := city_lot(c, p[0][0], p[0][1]).occupant
		testing.expect(t, o8.present)
		if o8.band == .Abandoned {
			testing.expect_value(t, city_population(c), 0)
			testing.expect_value(t, city_lot(c, p[0][0], p[0][1]).zone, Zone.Residential)
			expect_building(t, c, p[0][0], p[0][1], .House)
			testing.expect_value(t, o8.band, Health_Band.Abandoned)
			testing.expect(t, o8.band != .Struggling)
			abandoned = true
			break
		}
	}
	testing.expect(t, abandoned)
}

@(test)
struggling_house_still_counts_population :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	await_full_health(c, p[0][0], p[0][1])
	sx, sy, found := find_building(c, .Station)
	testing.expect(t, found)
	testing.expect(t, bulldoze(c, sx, sy))
	struggling := false
	for _ in 0 ..< 80 {
		tick(c, pick_first)
		o9 := city_lot(c, p[0][0], p[0][1]).occupant
		testing.expect(t, o9.present)
		if o9.band == .Struggling {
			testing.expect_value(t, city_population(c), 4)
			testing.expect_value(t, city_jobs(c), 4)
			testing.expect_value(t, o9.band, Health_Band.Struggling)
			testing.expect(t, o9.band != .Abandoned)
			struggling = true
			break
		}
	}
	testing.expect(t, struggling)
}

@(test)
unemployment_nibbles_houses_not_shops :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 3)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[2][0], p[2][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[2][0], p[2][1])
	paint_zone(c, p[1][0], p[1][1], .Residential)
	await_finished(c, p[1][0], p[1][1])
	testing.expect_value(t, city_population(c), 8)
	testing.expect_value(t, city_jobs(c), 4)
	testing.expect(t, stamp_near(c, p[2][0], p[2][1], .Police))
	for _ in 0 ..< 5 {
		tick(c, pick_first)
	}
	hh_occ := city_lot(c, p[0][0], p[0][1]).occupant
	hh := hh_occ.health
	hok := hh_occ.present
	o11 := city_lot(c, p[2][0], p[2][1]).occupant
	sh := o11.health
	sok := o11.present
	testing.expect(t, hok && sok)
	testing.expect(t, hh < 1)
	testing.expect_value(t, sh, f32(1))
}

@(test)
unemployment_does_not_nibble_houses_while_a_shop_is_in_construction :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	shop := city_lot(c, p[1][0], p[1][1]).occupant
	testing.expect(t, shop.present)
	testing.expect_value(t, shop.status, Occupant_Status.Construction)
	for _ in 0 ..< 5 {
		tick(c, pick_first)
		testing.expect_value(t, city_lot(c, p[1][0], p[1][1]).occupant.status, Occupant_Status.Construction)
	}
	testing.expect_value(t, city_lot(c, p[0][0], p[0][1]).occupant.health, f32(1))
}

@(test)
unemployment_does_not_nibble_houses_while_a_shop_is_abandoned :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 3)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Residential)
	paint_zone(c, p[2][0], p[2][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[2][0], p[2][1])
	await_finished(c, p[1][0], p[1][1])
	testing.expect_value(t, city_population(c), 8)
	testing.expect_value(t, city_jobs(c), 4)
	sx, sy, found := find_building(c, .Station)
	testing.expect(t, found)
	testing.expect(t, bulldoze(c, sx, sy))
	for _ in 0 ..< 80 {
		tick(c, pick_first)
		if city_lot(c, p[2][0], p[2][1]).occupant.band == .Abandoned {
			break
		}
	}
	testing.expect_value(t, city_lot(c, p[2][0], p[2][1]).occupant.band, Health_Band.Abandoned)
	testing.expect(t, stamp(c, sx, sy, .Station))
	before := city_lot(c, p[0][0], p[0][1]).occupant.health
	for _ in 0 ..< 5 {
		tick(c, pick_first)
		testing.expect_value(t, city_lot(c, p[2][0], p[2][1]).occupant.band, Health_Band.Abandoned)
	}
	testing.expect(t, city_lot(c, p[0][0], p[0][1]).occupant.health > before)
}

@(test)
high_tax_nibbles_health :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	await_full_health(c, p[0][0], p[0][1])
	h_occ := city_lot(c, p[0][0], p[0][1]).occupant
	h := h_occ.health
	health_ok := h_occ.present
	testing.expect(t, health_ok)
	testing.expect_value(t, h, f32(1))
	city_set_tax(c, TAX_HIGH)
	for _ in 0 ..< 5 {
		tick(c, pick_first)
	}
	o13 := city_lot(c, p[0][0], p[0][1]).occupant
	h = o13.health
	health_ok = o13.present
	testing.expect(t, health_ok)
	testing.expect(t, h < 1)
}

@(test)
unemployment_does_not_nibble_a_park :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	testing.expect(t, stamp(c, p[1][0], p[1][1], .Park))
	await_finished(c, p[0][0], p[0][1])
	for _ in 0 ..< 5 {
		tick(c, pick_first)
	}
	hh_occ := city_lot(c, p[0][0], p[0][1]).occupant
	hh := hh_occ.health
	hok := hh_occ.present
	o15 := city_lot(c, p[1][0], p[1][1]).occupant
	ph := o15.health
	pok := o15.present
	testing.expect(t, hok && pok)
	testing.expect(t, hh < 1)
	testing.expect_value(t, ph, f32(1))
}

@(test)
husk_recovers_when_power_returns :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	sx, sy, found := find_building(c, .Station)
	testing.expect(t, found)
	testing.expect(t, bulldoze(c, sx, sy))
	for _ in 0 ..< 80 {
		tick(c, pick_first)
		o16 := city_lot(c, p[0][0], p[0][1]).occupant
		testing.expect(t, o16.present)
		if o16.band == .Abandoned {
			break
		}
	}
	testing.expect(t, stamp(c, sx, sy, .Station))
	recovered := false
	for _ in 0 ..< 80 {
		tick(c, pick_first)
		o17 := city_lot(c, p[0][0], p[0][1]).occupant
		testing.expect(t, o17.present)
		if o17.band != .Abandoned {
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
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Residential)
	tick(c, pick_first)
	sx, sy, found := find_building(c, .Station)
	testing.expect(t, found)
	testing.expect(t, bulldoze(c, sx, sy))
	for _ in 0 ..< 80 {
		tick(c, pick_first)
		o18 := city_lot(c, p[0][0], p[0][1]).occupant
		testing.expect(t, o18.present)
		if o18.remaining > 0 {
			continue
		}
		if o18.band == .Abandoned {
			break
		}
	}
	testing.expect(t, city_lot(c, p[0][0], p[0][1]).occupant.band == .Abandoned)
	testing.expect(t, !in_construction(c, p[0][0], p[0][1]))
	expect_no_building(t, c, p[1][0], p[1][1])
	testing.expect(t, stamp(c, sx, sy, .Station))
	tick(c, pick_first)
	testing.expect(t, city_lot(c, p[0][0], p[0][1]).occupant.band == .Abandoned)
	testing.expect(t, !in_construction(c, p[0][0], p[0][1]))
	expect_building(t, c, p[0][0], p[0][1], .House)
	expect_building(t, c, p[1][0], p[1][1], .House)
}

@(test)
missing_water_nibbles_grown_buildings :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	await_full_health(c, p[0][0], p[0][1])
	tx, ty, found := find_building(c, .Tower)
	testing.expect(t, found)
	testing.expect(t, bulldoze(c, tx, ty))
	for _ in 0 ..< 5 {
		tick(c, pick_first)
	}
	h_occ := city_lot(c, p[0][0], p[0][1]).occupant
	h := h_occ.health
	health_ok := h_occ.present
	testing.expect(t, health_ok)
	testing.expect(t, h < 1)
}

@(test)
happiness_falls_when_buildings_lose_health :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 3)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Residential)
	paint_zone(c, p[2][0], p[2][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	tick(c, pick_first)
	await_finished(c, p[2][0], p[2][1])
	for _ in 0 ..< 5 {
		tick(c, pick_first)
	}
	h_occ := city_lot(c, p[0][0], p[0][1]).occupant
	h := h_occ.health
	health_ok := h_occ.present
	testing.expect(t, health_ok)
	hap := city_happiness(c)
	testing.expect(t, hap < 1)
	testing.expect(t, hap > h)
}

@(test)
save_then_load_keeps_health :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 3)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Residential)
	paint_zone(c, p[2][0], p[2][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	tick(c, pick_first)
	await_finished(c, p[2][0], p[2][1])
	for _ in 0 ..< 5 {
		tick(c, pick_first)
	}
	h_occ := city_lot(c, p[0][0], p[0][1]).occupant
	h := h_occ.health
	health_ok := h_occ.present
	testing.expect(t, health_ok)
	testing.expect(t, h < 1)
	path := "city_health.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	defer free(loaded)
	testing.expect(t, load_ok)
	o22 := city_lot(loaded, p[0][0], p[0][1]).occupant
	lh := o22.health
	lok := o22.present
	testing.expect(t, lok)
	testing.expect_value(t, lh, h)
	testing.expect_value(t, city_happiness(loaded), city_happiness(c))
}

grow_house_shop_factory :: proc(c: ^City, house, shop, factory: [2]int) {
	paint_zone(c, house[0], house[1], .Residential)
	paint_zone(c, shop[0], shop[1], .Commercial)
	paint_zone(c, factory[0], factory[1], .Industrial)
	await_finished(c, house[0], house[1])
	tick(c, pick_first)
	await_finished(c, shop[0], shop[1])
	tick(c, pick_first)
	await_finished(c, factory[0], factory[1])
}

@(test)
factory_plot_emits_pollution :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 3)
	testing.expect(t, ok)
	grow_house_shop_factory(c, p[0], p[1], p[2])
	tick(c, pick_first)
	fx, fy := p[2][0], p[2][1]
	expect_building(t, c, fx, fy, .Factory)
	testing.expect(t, city_lot(c, fx, fy).pollution > 0)
}

@(test)
bulldoze_factory_clears_pollution_without_tick :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 3)
	testing.expect(t, ok)
	grow_house_shop_factory(c, p[0], p[1], p[2])
	tick(c, pick_first)
	fx, fy := p[2][0], p[2][1]
	expect_building(t, c, fx, fy, .Factory)
	testing.expect(t, city_lot(c, fx, fy).pollution > 0)
	testing.expect(t, bulldoze(c, fx, fy))
	testing.expect_value(t, city_lot(c, fx, fy).pollution, f32(0))
}

@(test)
bulldoze_factory_raises_land_value_without_tick :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 3)
	testing.expect(t, ok)
	grow_house_shop_factory(c, p[0], p[1], p[2])
	tick(c, pick_first)
	fx, fy := p[2][0], p[2][1]
	expect_building(t, c, fx, fy, .Factory)
	testing.expect(t, city_lot(c, fx, fy).pollution > 0)
	before := city_lot(c, fx, fy).land_value
	testing.expect(t, bulldoze(c, fx, fy))
	testing.expect(t, city_lot(c, fx, fy).land_value > before)
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
	defer free(c)
	p, ok := supplied_plots(c, 3)
	testing.expect(t, ok)
	grow_house_shop_factory(c, p[0], p[1], p[2])
	tick(c, pick_first)
	fx, fy := p[2][0], p[2][1]
	src := city_lot(c, fx, fy).pollution
	found := false
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for n in cardinal {
		nx, ny := fx + n[0], fy + n[1]
		if nx < 0 || ny < 0 || nx >= MAP_SIZE || ny >= MAP_SIZE {
			continue
		}
		mid := city_lot(c, nx, ny).pollution
		testing.expect(t, mid > 0)
		testing.expect(t, mid < src)
		n2x, n2y := fx + 2 * n[0], fy + 2 * n[1]
		if n2x < 0 || n2y < 0 || n2x >= MAP_SIZE || n2y >= MAP_SIZE {
			continue
		}
		testing.expect(t, city_lot(c, n2x, n2y).pollution < mid)
		found = true
		break
	}
	testing.expect(t, found)
}

supplied_plot_touching_lake :: proc(c: ^City) -> (x, y, lx, ly: int, ok: bool) {
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			if !is_empty_grass(c, x, y) {
				continue
			}
			if !city_lot(c, x, y).powered || !city_lot(c, x, y).watered || !plot_touches_road(c, x, y) {
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
	defer free(c)
	p, ok := supplied_plots(c, 8)
	testing.expect(t, ok)
	fx, fy, lx, ly, lake_plot := supplied_plot_touching_lake(c)
	testing.expect(t, lake_plot)
	house, shop, picked := two_plots_besides(p[:8], {fx, fy})
	testing.expect(t, picked)
	grow_house_shop_factory(c, house, shop, {fx, fy})
	tick(c, pick_first)
	expect_building(t, c, fx, fy, .Factory)
	testing.expect(t, city_lot(c, lx, ly).pollution > 0)
	rx, ry, road := find_cardinal_road(c, fx, fy)
	testing.expect(t, road)
	testing.expect(t, city_lot(c, rx, ry).pollution > 0)
	ox, oy := fx + (lx - fx) * 2, fy + (ly - fy) * 2
	if ox >= 0 && oy >= 0 && ox < MAP_SIZE && oy < MAP_SIZE {
		testing.expect(t, city_lot(c, ox, oy).pollution > 0)
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
	defer free(c)
	p, ok := supplied_plots(c, 8)
	testing.expect(t, ok)
	house, factory, pair := cardinal_pair(p[:8])
	testing.expect(t, pair)
	shop, shop_ok := other_plot(p[:8], house, factory)
	testing.expect(t, shop_ok)
	grow_house_shop_factory(c, house, shop, factory)
	tick(c, pick_first)
	for _ in 0 ..< 5 {
		tick(c, pick_first)
	}
	hh_occ := city_lot(c, house[0], house[1]).occupant
	hh := hh_occ.health
	hok := hh_occ.present
	o24 := city_lot(c, shop[0], shop[1]).occupant
	sh := o24.health
	sok := o24.present
	o25 := city_lot(c, factory[0], factory[1]).occupant
	fh := o25.health
	fok := o25.present
	testing.expect(t, hok && sok && fok)
	testing.expect(t, hh < 1)
	testing.expect_value(t, sh, f32(1))
	testing.expect_value(t, fh, f32(1))
}

@(test)
pollution_does_not_nibble_a_park :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 8)
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
	testing.expect(t, stamp(c, park[0], park[1], .Park))
	grow_house_shop_factory(c, house, shop, factory)
	tick(c, pick_first)
	for _ in 0 ..< 5 {
		tick(c, pick_first)
	}
	ph_occ := city_lot(c, park[0], park[1]).occupant
	ph := ph_occ.health
	pok := ph_occ.present
	testing.expect(t, pok)
	testing.expect_value(t, ph, f32(1))
}

@(test)
save_then_load_keeps_pollution_belt :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 3)
	testing.expect(t, ok)
	grow_house_shop_factory(c, p[0], p[1], p[2])
	tick(c, pick_first)
	fx, fy := p[2][0], p[2][1]
	want := city_lot(c, fx, fy).pollution
	testing.expect(t, want > 0)
	path := "city_pollution.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	defer free(loaded)
	testing.expect(t, load_ok)
	testing.expect_value(t, city_lot(loaded, fx, fy).pollution, want)
	rx, ry, road := find_cardinal_road(loaded, fx, fy)
	testing.expect(t, road)
	testing.expect_value(t, city_lot(loaded, rx, ry).pollution, city_lot(c, rx, ry).pollution)
}

@(test)
park_covers_without_power :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Park))
	testing.expect(t, !city_lot(c, 1, 0).powered)
	testing.expect(t, city_lot(c, 1, 0).park_coverage)
	testing.expect(t, city_lot(c, 2, 0).park_coverage)
}

@(test)
school_has_no_coverage_without_power :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .School))
	testing.expect(t, !city_lot(c, 1, 0).powered)
	testing.expect(t, !city_lot(c, 1, 0).education)
	testing.expect(t, !city_lot(c, 2, 0).education)
}

@(test)
powered_school_covers_a_square_through_roads :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Station))
	testing.expect(t, stamp(c, 0, 1, .School))
	testing.expect(t, city_lot(c, 0, 1).powered)
	testing.expect(t, city_lot(c, 0, 1).education)
	testing.expect(t, city_lot(c, 0, 0).education)
	testing.expect(t, !city_lot(c, 20, 20).education)
}

@(test)
park_raises_land_value_without_power :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Park))
	testing.expect(t, !city_lot(c, 2, 0).powered)
	testing.expect(t, city_lot(c, 2, 0).land_value > city_lot(c, 20, 20).land_value)
}

is_empty_grass :: proc(c: ^City, x, y: int) -> bool {
	if x < 0 || y < 0 || x >= MAP_SIZE || y >= MAP_SIZE {
		return false
	}
	lot := city_lot(c, x, y)
	return lot.kind == .Plot && lot.terrain == .Grass && !lot.occupant.present
}

in_rect :: proc(x, y, x0, y0, w, h: int) -> bool {
	return x >= x0 && y >= y0 && x < x0 + w && y < y0 + h
}

connect_plot_to_network :: proc(c: ^City, x, y, fx, fy: int) -> bool {
	if plot_touches_road(c, x, y) {
		return true
	}
	visited: [MAP_SIZE * MAP_SIZE]bool
	prev: [MAP_SIZE * MAP_SIZE]int
	queue: [MAP_SIZE * MAP_SIZE]int
	head, tail := 0, 0
	for i in 0 ..< MAP_SIZE * MAP_SIZE {
		prev[i] = -1
		if city_lot(c, i % MAP_SIZE, i / MAP_SIZE).kind == .Road {
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
			if !is_empty_grass(c, nx, ny) || in_rect(nx, ny, fx, fy, 2, 2) {
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
	for goal >= 0 && city_lot(c, goal % MAP_SIZE, goal / MAP_SIZE).kind != .Road {
		gx, gy := goal % MAP_SIZE, goal / MAP_SIZE
		if !paint_road(c, gx, gy) {
			return false
		}
		goal = prev[goal]
	}
	return plot_touches_road(c, x, y)
}

rect_supplied :: proc(c: ^City, x, y: int) -> bool {
	for dy in 0 ..< 2 {
		for dx in 0 ..< 2 {
			if !city_lot(c, x + dx, y + dy).powered || !city_lot(c, x + dx, y + dy).watered {
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
	city_set_money(c, 99999)
	for y in 0 ..< MAP_SIZE - 1 {
		for x in 0 ..< MAP_SIZE - 1 {
			if !is_empty_grass(c, x, y) ||
			   !is_empty_grass(c, x + 1, y) ||
			   !is_empty_grass(c, x, y + 1) ||
			   !is_empty_grass(c, x + 1, y + 1) {
				continue
			}
			near := false
			for dy in 0 ..< 2 {
				for dx in 0 ..< 2 {
					if city_lot(c, x + dx, y + dy).powered && city_lot(c, x + dx, y + dy).watered {
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
			if rect_supplied(c, x, y) {
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
	defer free(c)
	x, y, ok := supplied_2x2(c)
	testing.expect(t, ok)
	testing.expect(t, stamp_park_near(c, x, y))
	for dy in 0 ..< 2 {
		for dx in 0 ..< 2 {
			testing.expect(t, paint_zone(c, x + dx, y + dy, .Residential))
		}
	}
	tick(c, pick_first)
	expect_footprint(t, c, x, y, 2, .House)
}

@(test)
low_land_value_births_a_1x1_even_with_four_plots :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	x, y, ok := supplied_2x2(c)
	testing.expect(t, ok)
	for dy in 0 ..< 2 {
		for dx in 0 ..< 2 {
			testing.expect(t, paint_zone(c, x + dx, y + dy, .Residential))
		}
	}
	tick(c, pick_first)
	n := 0
	for dy in 0 ..< 2 {
		for dx in 0 ..< 2 {
			occupied := city_lot(c, x + dx, y + dy).occupant.present
			if occupied {
				n += 1
			}
		}
	}
	testing.expect_value(t, n, 1)
	size := city_lot(c, x, y).occupant.size
	nw := city_lot(c, x, y).occupant.northwest
	testing.expect(t, nw)
	testing.expect_value(t, size, 1)
	expect_building(t, c, x, y, .House)
}

@(test)
two_by_two_house_population_is_base_times_plots :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	x, y, ok := supplied_2x2(c)
	testing.expect(t, ok)
	testing.expect(t, stamp_park_near(c, x, y))
	for dy in 0 ..< 2 {
		for dx in 0 ..< 2 {
			testing.expect(t, paint_zone(c, x + dx, y + dy, .Residential))
		}
	}
	tick(c, pick_first)
	await_finished(c, x, y)
	testing.expect_value(t, city_population(c), 16)
}

@(test)
new_house_is_level_1 :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	await_finished(c, p[0][0], p[0][1])
	lv_occ := city_lot(c, p[0][0], p[0][1]).occupant
	lv := lv_occ.level
	lok := lv_occ.present
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(1))
}

ensure_stamp_money :: proc(c: ^City) {
	city_set_money(c, max(city_money(c), STAMP_COST))
}

stamp_near :: proc(c: ^City, x, y: int, kind: Building_Kind) -> bool {
	ensure_stamp_money(c)
	for py in y - COVERAGE_RANGE ..= y + COVERAGE_RANGE {
		for px in x - COVERAGE_RANGE ..= x + COVERAGE_RANGE {
			if px == x && py == y {
				continue
			}
			if kind != .Park && !city_lot(c, px, py).powered {
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
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	testing.expect(t, stamp_near(c, hx, hy, .Park))
	paint_zone(c, hx, hy, .Residential)
	await_finished(c, hx, hy)
	lv_occ := city_lot(c, hx, hy).occupant
	lv := lv_occ.level
	lok := lv_occ.present
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(1))
	testing.expect(t, stamp_near(c, hx, hy, .School))
	tick(c, pick_first)
	o29 := city_lot(c, hx, hy).occupant
	lv = o29.level
	lok = o29.present
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(2))
	testing.expect_value(t, city_population(c), 8)
}

@(test)
house_needs_hospital_to_reach_level_3 :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	sx, sy := p[1][0], p[1][1]
	paint_zone(c, hx, hy, .Residential)
	paint_zone(c, sx, sy, .Commercial)
	await_finished(c, hx, hy)
	tick(c, pick_first)
	await_finished(c, sx, sy)
	testing.expect(t, stamp_near(c, hx, hy, .Park))
	testing.expect(t, stamp_near(c, hx, hy, .School))
	tick(c, pick_first)
	lv_occ := city_lot(c, hx, hy).occupant
	lv := lv_occ.level
	lok := lv_occ.present
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(2))
	tick(c, pick_first)
	o31 := city_lot(c, hx, hy).occupant
	lv = o31.level
	lok = o31.present
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(2))
	testing.expect(t, stamp_near(c, hx, hy, .Hospital))
	tick(c, pick_first)
	o32 := city_lot(c, hx, hy).occupant
	lv = o32.level
	lok = o32.present
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(3))
	testing.expect_value(t, city_population(c), 12)
}

@(test)
at_most_one_house_levels_per_tick :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 3)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Residential)
	paint_zone(c, p[2][0], p[2][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	tick(c, pick_first)
	await_finished(c, p[2][0], p[2][1])
	tick(c, pick_first)
	testing.expect(t, stamp_near(c, p[0][0], p[0][1], .Park))
	testing.expect(t, stamp_near(c, p[0][0], p[0][1], .School))
	testing.expect(t, city_lot(c, p[1][0], p[1][1]).park_coverage)
	testing.expect(t, city_lot(c, p[1][0], p[1][1]).education)
	tick(c, pick_first)
	a_occ := city_lot(c, p[0][0], p[0][1]).occupant
	a := a_occ.level
	aok := a_occ.present
	o34 := city_lot(c, p[1][0], p[1][1]).occupant
	b := o34.level
	bok := o34.present
	testing.expect(t, aok && bok)
	testing.expect(t, a == 2 && b == 1 || a == 1 && b == 2)
}

@(test)
level_up_does_not_grow_the_footprint :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	testing.expect(t, stamp_near(c, hx, hy, .Park))
	paint_zone(c, hx, hy, .Residential)
	await_finished(c, hx, hy)
	testing.expect(t, stamp_near(c, hx, hy, .School))
	tick(c, pick_first)
	lv_occ := city_lot(c, hx, hy).occupant
	lv := lv_occ.level
	lok := lv_occ.present
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(2))
	size := city_lot(c, hx, hy).occupant.size
	nw := city_lot(c, hx, hy).occupant.northwest
	testing.expect(t, nw)
	testing.expect_value(t, size, 1)
}

@(test)
abandoned_house_never_levels :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	testing.expect(t, stamp_near(c, hx, hy, .Park))
	paint_zone(c, hx, hy, .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, hx, hy)
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	testing.expect(t, stamp_near(c, hx, hy, .School))
	tx, ty, found := find_building(c, .Tower)
	testing.expect(t, found)
	testing.expect(t, bulldoze(c, tx, ty))
	for _ in 0 ..< 80 {
		tick(c, pick_first)
		o36 := city_lot(c, hx, hy).occupant
		testing.expect(t, o36.present)
		if o36.band == .Abandoned {
			break
		}
	}
	o37 := city_lot(c, hx, hy).occupant
	testing.expect(t, o37.present)
	testing.expect_value(t, o37.band, Health_Band.Abandoned)
	tick(c, pick_first)
	o38 := city_lot(c, hx, hy).occupant
	lv := o38.level
	lok := o38.present
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(1))
}

@(test)
save_then_load_keeps_level_and_footprint :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	x, y, ok := supplied_2x2(c)
	testing.expect(t, ok)
	testing.expect(t, stamp_park_near(c, x, y))
	for dy in 0 ..< 2 {
		for dx in 0 ..< 2 {
			testing.expect(t, paint_zone(c, x + dx, y + dy, .Residential))
		}
	}
	await_finished(c, x, y)
	lv_occ := city_lot(c, x, y).occupant
	lv := lv_occ.level
	lok := lv_occ.present
	testing.expect(t, lok)
	path := "city_level.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	defer free(loaded)
	testing.expect(t, load_ok)
	o40 := city_lot(loaded, x, y).occupant
	llv := o40.level
	llok := o40.present
	testing.expect(t, llok)
	testing.expect_value(t, llv, lv)
	expect_footprint(t, loaded, x, y, 2, .House)
	testing.expect_value(t, city_population(loaded), city_population(c))
}

@(test)
unpowered_hospital_police_firehouse_have_no_coverage :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	paint_road(c, 1, 0)
	paint_road(c, 2, 0)
	testing.expect(t, stamp(c, 0, 1, .Hospital))
	testing.expect(t, stamp(c, 1, 1, .Police))
	testing.expect(t, stamp(c, 2, 1, .Firehouse))
	testing.expect(t, !city_lot(c, 0, 1).powered)
	testing.expect(t, !city_lot(c, 0, 1).hospital_coverage)
	testing.expect(t, !city_lot(c, 1, 1).police_coverage)
	testing.expect(t, !city_lot(c, 2, 1).firehouse_coverage)
}

@(test)
high_land_value_births_a_2x2_shop :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	x, y, ok := supplied_2x2(c)
	testing.expect(t, ok)
	rx, ry := -1, -1
	found := false
	for py in 0 ..< MAP_SIZE {
		for px in 0 ..< MAP_SIZE {
			if in_rect(px, py, x, y, 2, 2) {
				continue
			}
			if is_empty_grass(c, px, py) &&
			   city_lot(c, px, py).powered &&
			   city_lot(c, px, py).watered &&
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
	paint_zone(c, rx, ry, .Residential)
	await_finished(c, rx, ry)
	testing.expect(t, stamp_park_near(c, x, y))
	for dy in 0 ..< 2 {
		for dx in 0 ..< 2 {
			testing.expect(t, paint_zone(c, x + dx, y + dy, .Commercial))
		}
	}
	await_finished(c, x, y)
	expect_footprint(t, c, x, y, 2, .Shop)
	testing.expect_value(t, city_jobs(c), 16)
}

jammed_house_and_shop :: proc(c: ^City) -> (house, shop: [2]int, rx, ry: int, ok: bool) {
	lx, ly, lake := find_terrain(c, .Lake)
	if !lake {
		return {}, {}, 0, 0, false
	}
	tx, ty, grass := find_cardinal_grass(c, lx, ly)
	if !grass {
		return {}, {}, 0, 0, false
	}
	if !paint_access_road(c, tx, ty) {
		return {}, {}, 0, 0, false
	}
	if !stamp(c, tx, ty, .Tower) {
		return {}, {}, 0, 0, false
	}
	road_x, road_y, road := find_cardinal_road(c, tx, ty)
	if !road {
		return {}, {}, 0, 0, false
	}
	rx, ry = road_x, road_y
	sx, sy, station_plot := find_empty_cardinal_plot(c, rx, ry)
	if !station_plot {
		return {}, {}, 0, 0, false
	}
	if !stamp(c, sx, sy, .Station) {
		return {}, {}, 0, 0, false
	}
	r2x, r2y, extra := find_empty_cardinal_plot(c, rx, ry)
	if !extra {
		return {}, {}, 0, 0, false
	}
	if !paint_road(c, r2x, r2y) {
		return {}, {}, 0, 0, false
	}
	hx, hy, house_plot := find_empty_cardinal_plot(c, rx, ry)
	if !house_plot {
		return {}, {}, 0, 0, false
	}
	cx, cy, shop_plot := find_empty_cardinal_plot(c, r2x, r2y)
	if !shop_plot {
		return {}, {}, 0, 0, false
	}
	paint_zone(c, hx, hy, .Residential)
	paint_zone(c, cx, cy, .Commercial)
	await_finished(c, hx, hy)
	tick(c, pick_first)
	await_finished(c, cx, cy)
	tick(c, pick_first)
	return {hx, hy}, {cx, cy}, rx, ry, true
}

@(test)
traffic_is_grown_buildings_over_road_lots :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	house, shop, rx, ry, ok := jammed_house_and_shop(c)
	testing.expect(t, ok)
	expect_building(t, c, house[0], house[1], .House)
	expect_building(t, c, shop[0], shop[1], .Shop)
	testing.expect_value(t, city_lot(c, rx, ry).traffic, f32(1))
	testing.expect(t, paint_road(c, 0, 0))
	testing.expect_value(t, city_lot(c, 0, 0).traffic, f32(0))
	testing.expect_value(t, city_lot(c, rx, ry).traffic, f32(1))
}

@(test)
jammed_component_nibbles_grown_buildings_not_facilities :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	house, shop, rx, ry, ok := jammed_house_and_shop(c)
	testing.expect(t, ok)
	testing.expect_value(t, city_lot(c, rx, ry).traffic, f32(1))
	for _ in 0 ..< 5 {
		tick(c, pick_first)
	}
	sh_occ := city_lot(c, shop[0], shop[1]).occupant
	sh := sh_occ.health
	sok := sh_occ.present
	o42 := city_lot(c, house[0], house[1]).occupant
	hh := o42.health
	hok := o42.present
	testing.expect(t, sok && hok)
	testing.expect(t, sh < 1)
	testing.expect(t, hh < 1)
	sx, sy, station := find_building(c, .Station)
	tx, ty, tower := find_building(c, .Tower)
	testing.expect(t, station && tower)
	o43 := city_lot(c, sx, sy).occupant
	sth := o43.health
	stok := o43.present
	o44 := city_lot(c, tx, ty).occupant
	th := o44.health
	tok := o44.present
	testing.expect(t, stok && tok)
	testing.expect_value(t, sth, f32(1))
	testing.expect_value(t, th, f32(1))
}

@(test)
painting_roads_on_the_component_relieves_the_nibble :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	_, shop, rx, ry, ok := jammed_house_and_shop(c)
	testing.expect(t, ok)
	for _ in 0 ..< 5 {
		tick(c, pick_first)
	}
	sh_occ := city_lot(c, shop[0], shop[1]).occupant
	sh := sh_occ.health
	sok := sh_occ.present
	testing.expect(t, sok)
	testing.expect(t, sh < 1)
	testing.expect(t, paint_extra_road_on_component(c, rx, ry))
	testing.expect_value(t, city_lot(c, rx, ry).traffic, f32(2) / f32(3))
	for _ in 0 ..< 20 {
		tick(c, pick_first)
	}
	o46 := city_lot(c, shop[0], shop[1]).occupant
	recovered := o46.health
	rok := o46.present
	testing.expect(t, rok)
	testing.expect(t, recovered > sh)
}

paint_extra_road_on_component :: proc(c: ^City, rx, ry: int) -> bool {
	load := city_lot(c, rx, ry).traffic
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			if city_lot(c, x, y).kind != .Road || city_lot(c, x, y).traffic != load {
				continue
			}
			px, py, ok := find_empty_cardinal_plot(c, x, y)
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
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	tick(c, pick_first)
	near := city_lot(c, p[0][0], p[0][1]).crime
	far := city_lot(c, 20, 20).crime
	testing.expect(t, near > far)
}

@(test)
unemployment_raises_crime :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 8)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	tick(c, pick_first)
	await_full_health(c, p[0][0], p[0][1])
	shop := p[1]
	before := city_lot(c, shop[0], shop[1]).crime
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
	paint_zone(c, far[0], far[1], .Residential)
	await_finished(c, far[0], far[1])
	tick(c, pick_first)
	testing.expect(t, city_lot(c, shop[0], shop[1]).crime > before)
}

@(test)
police_coverage_lowers_crime :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	tick(c, pick_first)
	sx, sy := p[1][0], p[1][1]
	before := city_lot(c, sx, sy).crime
	testing.expect(t, before > 0)
	testing.expect(t, stamp_near(c, sx, sy, .Police))
	testing.expect(t, city_lot(c, sx, sy).police_coverage)
	testing.expect(t, city_lot(c, sx, sy).crime < before)
}

@(test)
unpowered_police_does_not_lower_crime :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	tick(c, pick_first)
	sx, sy := p[1][0], p[1][1]
	stx, sty, found := find_building(c, .Station)
	testing.expect(t, found)
	testing.expect(t, bulldoze(c, stx, sty))
	before := city_lot(c, sx, sy).crime
	testing.expect(t, before > 0)
	ensure_stamp_money(c)
	stamped := false
	for py in sy - COVERAGE_RANGE ..= sy + COVERAGE_RANGE {
		for px in sx - COVERAGE_RANGE ..= sx + COVERAGE_RANGE {
			if stamp(c, px, py, .Police) {
				stamped = true
				break
			}
		}
		if stamped {
			break
		}
	}
	testing.expect(t, stamped)
	testing.expect(t, !city_lot(c, sx, sy).police_coverage)
	testing.expect_value(t, city_lot(c, sx, sy).crime, before)
}

@(test)
crime_nibbles_shops_not_houses :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 8)
	testing.expect(t, ok)
	house, shop, pair := cardinal_pair(p[:8])
	testing.expect(t, pair)
	paint_zone(c, house[0], house[1], .Residential)
	paint_zone(c, shop[0], shop[1], .Commercial)
	await_finished(c, house[0], house[1])
	tick(c, pick_first)
	await_finished(c, shop[0], shop[1])
	testing.expect(t, city_lot(c, shop[0], shop[1]).crime >= CRIME_HIGH)
	house_before_occ := city_lot(c, house[0], house[1]).occupant
	house_before := house_before_occ.health
	house_ok := house_before_occ.present
	o48 := city_lot(c, shop[0], shop[1]).occupant
	shop_before := o48.health
	shop_ok := o48.present
	testing.expect(t, house_ok && shop_ok)
	for _ in 0 ..< 5 {
		tick(c, pick_first)
	}
	o49 := city_lot(c, house[0], house[1]).occupant
	house_after := o49.health
	house_after_ok := o49.present
	o50 := city_lot(c, shop[0], shop[1]).occupant
	shop_after := o50.health
	shop_after_ok := o50.present
	testing.expect(t, house_after_ok && shop_after_ok)
	testing.expect(t, house_after >= house_before)
	testing.expect(t, shop_after < shop_before)
}

@(test)
crime_lowers_land_value :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 8)
	testing.expect(t, ok)
	house, shop, pair := cardinal_pair(p[:8])
	testing.expect(t, pair)
	paint_zone(c, house[0], house[1], .Residential)
	paint_zone(c, shop[0], shop[1], .Commercial)
	before := city_lot(c, shop[0], shop[1]).land_value
	await_finished(c, house[0], house[1])
	tick(c, pick_first)
	await_finished(c, shop[0], shop[1])
	testing.expect(t, city_lot(c, shop[0], shop[1]).crime > 0)
	testing.expect(t, city_lot(c, shop[0], shop[1]).land_value < before)
}

@(test)
happiness_is_not_an_input_to_crime :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 8)
	testing.expect(t, ok)
	house, shop, pair := cardinal_pair(p[:8])
	testing.expect(t, pair)
	paint_zone(c, house[0], house[1], .Residential)
	paint_zone(c, shop[0], shop[1], .Commercial)
	tick(c, pick_first)
	tick(c, pick_first)
	tick(c, pick_first)
	crime := city_lot(c, shop[0], shop[1]).crime
	hap := city_happiness(c)
	city_set_tax(c, TAX_HIGH)
	for _ in 0 ..< 5 {
		tick(c, pick_first)
	}
	testing.expect(t, city_happiness(c) < hap)
	testing.expect_value(t, city_lot(c, shop[0], shop[1]).crime, crime)
}

@(test)
new_city_clock_is_year_one_month_one_day_one :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	testing.expect_value(t, city_year(c), 1)
	testing.expect_value(t, city_month(c), 1)
	testing.expect_value(t, city_day(c), 1)
}

@(test)
clock_month_advances_after_a_month_of_ticks :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	for _ in 0 ..< MONTH_TICKS {
		tick(c, pick_first)
	}
	testing.expect_value(t, city_year(c), 1)
	testing.expect_value(t, city_month(c), 2)
	testing.expect_value(t, city_day(c), 1)
}

@(test)
hour_advances_inside_a_month_and_is_not_a_rule :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	testing.expect_value(t, city_hour(c), 0)
	tick(c, pick_first)
	testing.expect_value(t, city_month(c), 1)
	testing.expect_value(t, city_day(c), 2)
	testing.expect_value(t, city_hour(c), 1)
}

@(test)
income_arrives_every_tick_inside_a_month :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	await_finished(c, p[0][0], p[0][1])
	testing.expect_value(t, city_population(c), 4)
	money := city_money(c)
	maintenance := maintenance_cost(c)
	tick(c, pick_first)
	testing.expect_value(t, city_money(c), money + 4 - maintenance)
}

@(test)
graph_samples_once_per_month :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	testing.expect_value(t, city_graph_len(c), 0)
	tick(c, pick_first)
	testing.expect_value(t, city_graph_len(c), 1)
	for _ in 1 ..< MONTH_TICKS {
		tick(c, pick_first)
	}
	testing.expect_value(t, city_graph_len(c), 1)
	tick(c, pick_first)
	testing.expect_value(t, city_graph_len(c), 2)
}

@(test)
graph_records_population_jobs_money_and_happiness :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	tick(c, pick_first)
	s0 := city_graph_at(c, 0)
	testing.expect_value(t, s0.population, 0)
	testing.expect_value(t, s0.jobs, 0)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	await_full_health(c, p[0][0], p[0][1])
	expect_building(t, c, p[0][0], p[0][1], .House)
	expect_building(t, c, p[1][0], p[1][1], .Shop)
	for city_day(c) != 1 {
		tick(c, pick_first)
	}
	tick(c, pick_first)
	s1 := city_graph_at(c, city_graph_len(c) - 1)
	testing.expect_value(t, s1.population, 4)
	testing.expect_value(t, s1.jobs, 4)
	testing.expect_value(t, s1.happiness, f32(1))
}

pick_outage :: proc(n: int) -> int {
	if n == OUTAGE_CHANCE {
		return n - 1
	}
	return 0
}

@(test)
outage_month_stations_supply_no_power :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Station))
	testing.expect(t, city_lot(c, 0, 1).powered)
	tick(c, pick_outage)
	testing.expect(t, city_outage(c))
	testing.expect(t, !city_lot(c, 0, 1).powered)
	testing.expect(t, !city_lot(c, 1, 0).powered)
}

@(test)
outage_dries_taps_when_towers_lose_power :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	x, y := p[0][0], p[0][1]
	testing.expect(t, city_lot(c, x, y).powered)
	testing.expect(t, city_lot(c, x, y).watered)
	tick(c, pick_outage)
	testing.expect(t, city_outage(c))
	testing.expect(t, !city_lot(c, x, y).powered)
	testing.expect(t, !city_lot(c, x, y).watered)
}

@(test)
outage_month_does_not_abandon_a_house :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	await_full_health(c, p[0][0], p[0][1])
	for city_day(c) != 1 {
		tick(c, pick_first)
	}
	tick(c, pick_outage)
	testing.expect(t, city_outage(c))
	testing.expect(t, !city_lot(c, p[0][0], p[0][1]).powered)
	for _ in 1 ..< MONTH_TICKS {
		tick(c, pick_first)
		testing.expect(t, city_outage(c))
	}
	occ := city_lot(c, p[0][0], p[0][1]).occupant
	testing.expect(t, occ.present)
	testing.expect(t, occ.band != .Abandoned)
	testing.expect_value(t, city_population(c), 4)
}

@(test)
stations_supply_again_after_outage_month_without_restamp :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Station))
	tick(c, pick_outage)
	testing.expect(t, !city_lot(c, 0, 1).powered)
	for _ in 1 ..< MONTH_TICKS {
		tick(c, pick_first)
		testing.expect(t, city_outage(c))
		testing.expect(t, !city_lot(c, 0, 1).powered)
	}
	tick(c, pick_first)
	testing.expect(t, !city_outage(c))
	testing.expect(t, city_lot(c, 0, 1).powered)
	expect_building(t, c, 1, 0, .Station)
}

@(test)
save_then_load_keeps_ticks_and_outage :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Station))
	tick(c, pick_outage)
	testing.expect(t, city_outage(c))
	testing.expect_value(t, city_day(c), 2)
	testing.expect(t, !city_lot(c, 0, 1).powered)
	path := "city_month.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, ok := city_load(path)
	defer free(loaded)
	testing.expect(t, ok)
	testing.expect(t, city_outage(loaded))
	testing.expect_value(t, city_year(loaded), city_year(c))
	testing.expect_value(t, city_month(loaded), city_month(c))
	testing.expect_value(t, city_day(loaded), city_day(c))
	testing.expect(t, !city_lot(loaded, 0, 1).powered)
	expect_building(t, loaded, 1, 0, .Station)
}

pick_ignite :: proc(n: int) -> int {
	if n == FIRE_IGNITE_CHANCE {
		return n - 1
	}
	return 0
}

advance_month :: proc(c: ^City, pick: Pick) {
	for city_day(c) != 1 {
		tick(c, pick_first)
	}
	tick(c, pick)
}

@(test)
month_may_ignite_a_grown_building_without_firehouse :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	await_full_health(c, p[0][0], p[0][1])
	hx, hy := p[0][0], p[0][1]
	expect_building(t, c, hx, hy, .House)
	testing.expect_value(t, city_lot(c, hx, hy).fire, f32(0))
	advance_month(c, pick_ignite)
	testing.expect(t, city_lot(c, hx, hy).fire > 0)
	testing.expect(t, city_lot(c, hx, hy).fire <= 1)
}

@(test)
firehouse_coverage_blocks_ignition :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 3)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	await_full_health(c, p[0][0], p[0][1])
	hx, hy := p[0][0], p[0][1]
	expect_building(t, c, hx, hy, .House)
	testing.expect(t, stamp(c, p[2][0], p[2][1], .Firehouse))
	testing.expect(t, city_lot(c, hx, hy).firehouse_coverage)
	advance_month(c, pick_ignite)
	testing.expect_value(t, city_lot(c, hx, hy).fire, f32(0))
}

@(test)
fire_lingers_through_a_month_without_firehouse :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	await_full_health(c, p[0][0], p[0][1])
	hx, hy := p[0][0], p[0][1]
	advance_month(c, pick_ignite)
	got := city_lot(c, hx, hy).fire
	testing.expect(t, got > 0)
	advance_month(c, pick_first)
	testing.expect(t, city_lot(c, hx, hy).fire > 0)
}

@(test)
fire_decays_slowly_without_a_firehouse :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	await_full_health(c, p[0][0], p[0][1])
	hx, hy := p[0][0], p[0][1]
	advance_month(c, pick_ignite)
	got := city_lot(c, hx, hy).fire
	testing.expect(t, got > 0)
	advance_month(c, pick_first)
	after := city_lot(c, hx, hy).fire
	testing.expect(t, after < got)
	testing.expect(t, after > 0)
}

pick_spread :: proc(n: int) -> int {
	if n == FIRE_SPREAD_CHANCE {
		return n - 1
	}
	return 0
}

@(test)
fire_spreads_to_a_cardinal_plot_except_road_lake_or_rock :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	await_full_health(c, p[0][0], p[0][1])
	hx, hy := p[0][0], p[0][1]
	advance_month(c, pick_ignite)
	testing.expect(t, city_lot(c, hx, hy).fire > 0)
	advance_month(c, pick_spread)
	testing.expect(t, city_lot(c, hx, hy).fire > 0)
	spread := false
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	for n in cardinal {
		nx, ny := hx + n[0], hy + n[1]
		if nx < 0 || ny < 0 || nx >= MAP_SIZE || ny >= MAP_SIZE {
			continue
		}
		lot := city_lot(c, nx, ny)
		if lot.kind == .Road || lot.terrain == .Lake || lot.terrain == .Rock {
			testing.expect_value(t, city_lot(c, nx, ny).fire, f32(0))
			continue
		}
		if city_lot(c, nx, ny).fire > 0 {
			spread = true
		}
	}
	testing.expect(t, spread)
}

@(test)
building_on_fire_takes_a_health_nibble :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	await_full_health(c, p[0][0], p[0][1])
	hx, hy := p[0][0], p[0][1]
	advance_month(c, pick_ignite)
	testing.expect(t, city_lot(c, hx, hy).fire > 0)
	h0_occ := city_lot(c, hx, hy).occupant
	h0 := h0_occ.health
	okh := h0_occ.present
	testing.expect(t, okh)
	testing.expect(t, h0 < 1)
	testing.expect(t, city_lot(c, hx, hy).occupant.band != .Abandoned)
	tick(c, pick_first)
	o52 := city_lot(c, hx, hy).occupant
	h1 := o52.health
	ok1 := o52.present
	testing.expect(t, ok1)
	testing.expect_value(t, h1, h0 - HEALTH_NIBBLE)
	testing.expect(t, h1 > 0)
}

@(test)
firehouse_coverage_decays_intensity :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 3)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	await_full_health(c, p[0][0], p[0][1])
	hx, hy := p[0][0], p[0][1]
	advance_month(c, pick_ignite)
	before := city_lot(c, hx, hy).fire
	testing.expect(t, before > 0)
	testing.expect(t, stamp(c, p[2][0], p[2][1], .Firehouse))
	testing.expect(t, city_lot(c, hx, hy).firehouse_coverage)
	advance_month(c, pick_first)
	after := city_lot(c, hx, hy).fire
	testing.expect(t, after < before)
	testing.expect(t, after > 0)
	for _ in 0 ..< 8 {
		if city_lot(c, hx, hy).fire == 0 {
			break
		}
		advance_month(c, pick_first)
	}
	testing.expect_value(t, city_lot(c, hx, hy).fire, f32(0))
}

pick_ignite_and_outage :: proc(n: int) -> int {
	if n == FIRE_IGNITE_CHANCE || n == OUTAGE_CHANCE {
		return n - 1
	}
	return 0
}

@(test)
fire_and_outage_may_happen_in_the_same_month :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	await_full_health(c, p[0][0], p[0][1])
	hx, hy := p[0][0], p[0][1]
	advance_month(c, pick_ignite_and_outage)
	testing.expect(t, city_outage(c))
	testing.expect(t, city_lot(c, hx, hy).fire > 0)
}

@(test)
save_then_load_keeps_fire_intensity :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Commercial)
	await_finished(c, p[0][0], p[0][1])
	tick(c, pick_first)
	await_finished(c, p[1][0], p[1][1])
	await_full_health(c, p[0][0], p[0][1])
	hx, hy := p[0][0], p[0][1]
	advance_month(c, pick_ignite)
	want := city_lot(c, hx, hy).fire
	testing.expect(t, want > 0)
	path := "city_fire.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	defer free(loaded)
	testing.expect(t, load_ok)
	testing.expect_value(t, city_lot(loaded, hx, hy).fire, want)
	expect_building(t, loaded, hx, hy, .House)
}

@(test)
new_house_enters_construction_and_occupies_its_plot :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	paint_zone(c, hx, hy, .Residential)
	tick(c, pick_first)
	expect_building(t, c, hx, hy, .House)
	testing.expect(t, in_construction(c, hx, hy))
	rem_occ := city_lot(c, hx, hy).occupant
	rem := rem_occ.remaining
	rok := rem_occ.present
	testing.expect(t, rok)
	testing.expect(t, rem > 0)
	testing.expect_value(t, city_population(c), 0)
	o54 := city_lot(c, hx, hy).occupant
	lv := o54.level
	lok := o54.present
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(0))
}

@(test)
construction_finishes_after_a_month_of_ticks_from_birth :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	paint_zone(c, hx, hy, .Residential)
	for _ in 0 ..< MONTH_TICKS - 1 {
		tick(c, pick_first)
		rem_occ := city_lot(c, hx, hy).occupant
		rem := rem_occ.remaining
		rok := rem_occ.present
		testing.expect(t, rok)
		testing.expect(t, rem > 0)
		testing.expect_value(t, city_population(c), 0)
	}
	tick(c, pick_first)
	o56 := city_lot(c, hx, hy).occupant
	rem := o56.remaining
	rok := o56.present
	testing.expect(t, rok)
	testing.expect_value(t, rem, u8(0))
	o57 := city_lot(c, hx, hy).occupant
	lv := o57.level
	lok := o57.present
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(1))
	o58 := city_lot(c, hx, hy).occupant
	h := o58.health
	hok := o58.present
	testing.expect(t, hok)
	testing.expect_value(t, h, f32(1))
	testing.expect_value(t, city_population(c), 4)
}

await_finished :: proc(c: ^City, x, y: int) {
	for _ in 0 ..< MONTH_TICKS {
		occ := city_lot(c, x, y).occupant
		if occ.present && occ.remaining == 0 {
			return
		}
		tick(c, pick_first)
	}
}

await_full_health :: proc(c: ^City, x, y: int) {
	for _ in 0 ..< 80 {
		occ := city_lot(c, x, y).occupant
		if occ.present && occ.remaining == 0 && occ.health == 1 {
			return
		}
		tick(c, pick_first)
	}
}

@(test)
construction_timer_runs_from_birth_not_the_calendar_month :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	for _ in 0 ..< 5 {
		tick(c, pick_first)
	}
	paint_zone(c, hx, hy, .Residential)
	for _ in 0 ..< MONTH_TICKS - 1 {
		tick(c, pick_first)
		rem_occ := city_lot(c, hx, hy).occupant
		rem := rem_occ.remaining
		rok := rem_occ.present
		testing.expect(t, rok)
		testing.expect(t, rem > 0)
	}
	testing.expect(t, city_month(c) != 1 || city_day(c) != MONTH_TICKS)
	tick(c, pick_first)
	o62 := city_lot(c, hx, hy).occupant
	rem := o62.remaining
	rok := o62.present
	testing.expect(t, rok)
	testing.expect_value(t, rem, u8(0))
	testing.expect_value(t, city_population(c), 4)
}

@(test)
two_houses_born_on_different_ticks_finish_at_different_times :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	paint_zone(c, p[1][0], p[1][1], .Residential)
	tick(c, pick_first)
	tick(c, pick_first)
	ra_occ := city_lot(c, p[0][0], p[0][1]).occupant
	ra := ra_occ.remaining
	aok := ra_occ.present
	o64 := city_lot(c, p[1][0], p[1][1]).occupant
	rb := o64.remaining
	bok := o64.present
	testing.expect(t, aok && bok)
	testing.expect(t, ra != rb)
	await_finished(c, p[0][0], p[0][1])
	o65 := city_lot(c, p[0][0], p[0][1]).occupant
	ra = o65.remaining
	aok = o65.present
	o66 := city_lot(c, p[1][0], p[1][1]).occupant
	rb = o66.remaining
	bok = o66.present
	testing.expect(t, aok && bok)
	testing.expect_value(t, ra, u8(0))
	testing.expect(t, rb > 0)
}

@(test)
finishing_into_fire_nibbles_health :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	for _ in 0 ..< 5 {
		tick(c, pick_first)
	}
	paint_zone(c, hx, hy, .Residential)
	tick(c, pick_first)
	advance_month(c, pick_ignite)
	rem_occ := city_lot(c, hx, hy).occupant
	rem := rem_occ.remaining
	rok := rem_occ.present
	testing.expect(t, rok)
	testing.expect(t, rem > 0)
	testing.expect(t, city_lot(c, hx, hy).fire > 0)
	await_finished(c, hx, hy)
	o68 := city_lot(c, hx, hy).occupant
	h0 := o68.health
	hok := o68.present
	testing.expect(t, hok)
	testing.expect_value(t, h0, f32(1))
	tick(c, pick_first)
	o69 := city_lot(c, hx, hy).occupant
	h1 := o69.health
	h1ok := o69.present
	testing.expect(t, h1ok)
	testing.expect(t, h1 < 1)
}

@(test)
new_shop_and_factory_enter_construction :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 3)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	sx, sy := p[1][0], p[1][1]
	fx, fy := p[2][0], p[2][1]
	paint_zone(c, hx, hy, .Residential)
	paint_zone(c, sx, sy, .Commercial)
	paint_zone(c, fx, fy, .Industrial)
	await_finished(c, hx, hy)
	testing.expect_value(t, city_population(c), 4)
	tick(c, pick_first)
	expect_building(t, c, sx, sy, .Shop)
	srem_occ := city_lot(c, sx, sy).occupant
	srem := srem_occ.remaining
	sok := srem_occ.present
	testing.expect(t, sok)
	testing.expect(t, srem > 0)
	testing.expect_value(t, city_jobs(c), 0)
	await_finished(c, sx, sy)
	testing.expect_value(t, city_jobs(c), 4)
	tick(c, pick_first)
	expect_building(t, c, fx, fy, .Factory)
	o71 := city_lot(c, fx, fy).occupant
	frem := o71.remaining
	fok := o71.present
	testing.expect(t, fok)
	testing.expect(t, frem > 0)
	testing.expect_value(t, city_jobs(c), 4)
}

@(test)
facilities_stamp_finished_without_construction :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Park))
	rem_occ := city_lot(c, 1, 0).occupant
	rem := rem_occ.remaining
	rok := rem_occ.present
	testing.expect(t, rok)
	testing.expect_value(t, rem, u8(0))
	o73 := city_lot(c, 1, 0).occupant
	h := o73.health
	hok := o73.present
	testing.expect(t, hok)
	testing.expect_value(t, h, f32(1))
}

@(test)
happiness_ignores_construction_so_an_unfinished_city_is_not_collapsing :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	paint_zone(c, hx, hy, .Residential)
	tick(c, pick_first)
	sx, sy, station := find_building(c, .Station)
	tx, ty, tower := find_building(c, .Tower)
	testing.expect(t, station && tower)
	testing.expect(t, bulldoze(c, sx, sy))
	testing.expect(t, bulldoze(c, tx, ty))
	rem_occ := city_lot(c, hx, hy).occupant
	rem := rem_occ.remaining
	rok := rem_occ.present
	testing.expect(t, rok)
	testing.expect(t, rem > 0)
	testing.expect_value(t, city_happiness(c), f32(1))
}

@(test)
level_up_skips_construction_and_stays_instant_after_finish :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	testing.expect(t, stamp_near(c, hx, hy, .Park))
	testing.expect(t, stamp_near(c, hx, hy, .School))
	paint_zone(c, hx, hy, .Residential)
	tick(c, pick_first)
	lv_occ := city_lot(c, hx, hy).occupant
	lv := lv_occ.level
	lok := lv_occ.present
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(0))
	await_finished(c, hx, hy)
	o76 := city_lot(c, hx, hy).occupant
	lv = o76.level
	lok = o76.present
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(1))
	tick(c, pick_first)
	o77 := city_lot(c, hx, hy).occupant
	lv = o77.level
	lok = o77.present
	testing.expect(t, lok)
	testing.expect_value(t, lv, u8(2))
}

@(test)
outage_does_not_freeze_construction_remaining :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	for _ in 0 ..< MONTH_TICKS / 2 {
		tick(c, pick_first)
	}
	paint_zone(c, hx, hy, .Residential)
	tick(c, pick_first)
	testing.expect(t, in_construction(c, hx, hy))
	advance_month(c, pick_outage)
	testing.expect(t, city_outage(c))
	testing.expect(t, in_construction(c, hx, hy))
	before_occ := city_lot(c, hx, hy).occupant
	before := before_occ.remaining
	bok := before_occ.present
	testing.expect(t, bok)
	testing.expect(t, before > 0)
	tick(c, pick_first)
	testing.expect(t, city_outage(c))
	o79 := city_lot(c, hx, hy).occupant
	after := o79.remaining
	aok := o79.present
	testing.expect(t, aok)
	testing.expect_value(t, after, before - 1)
}

@(test)
fire_may_sit_on_construction_without_a_health_nibble :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	for _ in 0 ..< 5 {
		tick(c, pick_first)
	}
	paint_zone(c, hx, hy, .Residential)
	tick(c, pick_first)
	advance_month(c, pick_ignite)
	lot := city_lot(c, hx, hy)
	testing.expect(t, lot.occupant.present && lot.occupant.status == .Construction)
	testing.expect(t, lot.occupant.remaining > 0)
	testing.expect(t, lot.fire > 0)
	testing.expect_value(t, lot.occupant.band, Health_Band.None)
}

@(test)
construction_counts_for_traffic :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	paint_zone(c, hx, hy, .Residential)
	tick(c, pick_first)
	tick(c, pick_first)
	rem_occ := city_lot(c, hx, hy).occupant
	rem := rem_occ.remaining
	rok := rem_occ.present
	testing.expect(t, rok)
	testing.expect(t, rem > 0)
	cardinal := [4][2]int{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
	load: f32
	found := false
	for n in cardinal {
		nx, ny := hx + n[0], hy + n[1]
		if nx < 0 || ny < 0 || nx >= MAP_SIZE || ny >= MAP_SIZE {
			continue
		}
		if city_lot(c, nx, ny).kind == .Road {
			load = city_lot(c, nx, ny).traffic
			found = true
			break
		}
	}
	testing.expect(t, found)
	testing.expect(t, load > 0)
}

@(test)
save_then_load_keeps_construction_remaining :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	paint_zone(c, hx, hy, .Residential)
	tick(c, pick_first)
	want_occ := city_lot(c, hx, hy).occupant
	want := want_occ.remaining
	rok := want_occ.present
	testing.expect(t, rok)
	testing.expect(t, want > 0)
	path := "city_construction.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, load_ok := city_load(path)
	defer free(loaded)
	testing.expect(t, load_ok)
	o82 := city_lot(loaded, hx, hy).occupant
	got := o82.remaining
	lok := o82.present
	testing.expect(t, lok)
	testing.expect_value(t, got, want)
	testing.expect_value(t, city_population(loaded), 0)
}

@(test)
load_old_version_leaves_city_alone :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	testing.expect(t, paint_road(c, 0, 0))
	path := "city_old_version.save"
	defer os.remove(path)
	old: [SAVE_HEADER]u8
	old[0] = 8
	testing.expect(t, os.write_entire_file(path, old[:]) == nil)
	_, ok := city_load(path)
	testing.expect(t, !ok)
	testing.expect_value(t, city_lot(c, 0, 0).kind, Lot_Kind.Road)
}

maintenance_cost :: proc(c: ^City) -> int {
	roads := 0
	facilities := 0
	for y in 0 ..< MAP_SIZE {
		for x in 0 ..< MAP_SIZE {
			lot := city_lot(c, x, y)
			if lot.kind == .Road {
				roads += 1
			}
			occ := lot.occupant
			if !occ.northwest || !occ.present {
				continue
			}
			if is_facility(occ.kind) {
				facilities += 1
			}
		}
	}
	return roads * ROAD_MAINTENANCE + facilities * FACILITY_MAINTENANCE
}

@(test)
tick_charges_maintenance_on_each_road_lot :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	testing.expect(t, paint_road(c, 1, 0))
	testing.expect_value(t, city_money(c), 1990)
	tick(c, pick_first)
	testing.expect_value(t, city_money(c), 1989)
}

@(test)
tick_charges_maintenance_on_each_facility :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	testing.expect(t, paint_road(c, 0, 0))
	testing.expect(t, stamp(c, 1, 0, .Park))
	testing.expect_value(t, city_money(c), 1890)
	tick(c, pick_first)
	testing.expect_value(t, city_money(c), 1888)
}

@(test)
two_by_two_station_pays_one_facility_maintenance :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	testing.expect(t, paint_road(c, 0, 0))
	testing.expect(t, stamp(c, 1, 0, .Station, 2))
	testing.expect_value(t, city_money(c), 1890)
	tick(c, pick_first)
	testing.expect_value(t, city_money(c), 1888)
}

@(test)
grown_buildings_are_not_billed :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	await_finished(c, p[0][0], p[0][1])
	testing.expect_value(t, city_population(c), 4)
	maintenance := maintenance_cost(c)
	money := city_money(c)
	tick(c, pick_first)
	testing.expect_value(t, city_money(c), money + 4 - maintenance)
}

@(test)
income_then_maintenance_then_money_floors_at_zero :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	await_finished(c, p[0][0], p[0][1])
	testing.expect_value(t, city_population(c), 4)
	testing.expect(t, maintenance_cost(c) > 4)
	city_set_money(c, 0)
	tick(c, pick_first)
	testing.expect_value(t, city_money(c), 0)
	testing.expect(t, !paint_road(c, 63, 63))
	testing.expect_value(t, city_lot(c, 63, 63).kind, Lot_Kind.Plot)
	tick(c, pick_first)
	testing.expect_value(t, city_population(c), 4)
	testing.expect_value(t, city_money(c), 0)
}

@(test)
starting_money_and_rates_let_a_first_neighborhood_be_painted :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 2)
	testing.expect(t, ok)
	testing.expect(t, paint_zone(c, p[0][0], p[0][1], .Residential))
	for _ in 0 ..< MONTH_TICKS {
		tick(c, pick_first)
	}
	testing.expect(t, city_money(c) > 0)
	testing.expect(t, paint_zone(c, p[1][0], p[1][1], .Commercial))
}

@(test)
tiny_opener_keeps_population_and_money_for_two_years :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 4)
	testing.expect(t, ok)
	testing.expect(t, paint_zone(c, p[0][0], p[0][1], .Residential))
	testing.expect(t, paint_zone(c, p[1][0], p[1][1], .Residential))
	testing.expect(t, paint_zone(c, p[2][0], p[2][1], .Commercial))
	testing.expect(t, paint_zone(c, p[3][0], p[3][1], .Commercial))
	for _ in 0 ..< 24 * MONTH_TICKS {
		tick(c, pick_first)
	}
	testing.expect(t, city_population(c) > 0)
	testing.expect(t, city_money(c) > 0)
}

@(test)
save_then_load_keeps_money_after_maintenance :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	testing.expect(t, paint_road(c, 0, 0))
	tick(c, pick_first)
	testing.expect_value(t, city_money(c), 1989)
	path := "city_maintenance.save"
	defer os.remove(path)
	testing.expect(t, city_save(c, path))
	loaded, ok := city_load(path)
	defer free(loaded)
	testing.expect(t, ok)
	testing.expect_value(t, city_money(loaded), 1989)
	testing.expect_value(t, city_lot(loaded, 0, 0).kind, Lot_Kind.Road)
}

@(test)
empty_city_supply_percents_are_full :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	testing.expect_value(t, city_power_percent(c), f32(1))
	testing.expect_value(t, city_water_percent(c), f32(1))
}

@(test)
occupied_unpowered_lots_pull_power_percent_down :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Park))
	testing.expect(t, !city_lot(c, 1, 0).powered)
	testing.expect_value(t, city_power_percent(c), f32(0))
	testing.expect_value(t, city_water_percent(c), f32(0))
}

@(test)
power_percent_is_occupied_plots_with_power_over_occupied_plots :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Station))
	paint_road(c, 15, 15)
	testing.expect(t, stamp(c, 15, 16, .Park))
	testing.expect(t, city_lot(c, 1, 0).powered)
	testing.expect(t, !city_lot(c, 15, 16).powered)
	testing.expect_value(t, city_power_percent(c), f32(0.5))
	testing.expect_value(t, city_water_percent(c), f32(0))
}

@(test)
outage_drops_the_power_percent :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Station))
	testing.expect_value(t, city_power_percent(c), f32(1))
	tick(c, pick_outage)
	testing.expect(t, city_outage(c))
	testing.expect_value(t, city_power_percent(c), f32(0))
}

@(test)
empty_lot_is_not_northwest :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	ok := city_lot(c, 0, 0).occupant.northwest
	testing.expect(t, !ok)
	testing.expect(t, city_lot(c, 0, 0).occupant.band != .Abandoned)
	testing.expect(t, city_lot(c, 0, 0).occupant.band != .Struggling)
}

@(test)
park_northwest_is_1x1_at_its_plot :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Park))
	size := city_lot(c, 1, 0).occupant.size
	ok := city_lot(c, 1, 0).occupant.northwest
	testing.expect(t, ok)
	testing.expect_value(t, size, 1)
	neighbor := city_lot(c, 2, 0).occupant.northwest
	testing.expect(t, !neighbor)
	testing.expect(t, city_lot(c, 1, 0).occupant.band != .Abandoned)
	testing.expect(t, city_lot(c, 1, 0).occupant.band != .Struggling)
}

@(test)
station_2x2_northwest_is_only_that_plot :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Station, 2))
	size := city_lot(c, 1, 0).occupant.size
	ok := city_lot(c, 1, 0).occupant.northwest
	testing.expect(t, ok)
	testing.expect_value(t, size, 2)
	east := city_lot(c, 2, 0).occupant.northwest
	testing.expect(t, !east)
	south := city_lot(c, 1, 1).occupant.northwest
	testing.expect(t, !south)
	southeast := city_lot(c, 2, 1).occupant.northwest
	testing.expect(t, !southeast)
}

@(test)
construction_is_not_abandoned :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	paint_zone(c, p[0][0], p[0][1], .Residential)
	tick(c, pick_first)
	rem_occ := city_lot(c, p[0][0], p[0][1]).occupant
	rem := rem_occ.remaining
	rok := rem_occ.present
	testing.expect(t, rok)
	testing.expect(t, rem > 0)
	testing.expect(t, in_construction(c, p[0][0], p[0][1]))
	size := city_lot(c, p[0][0], p[0][1]).occupant.size
	nw := city_lot(c, p[0][0], p[0][1]).occupant.northwest
	testing.expect(t, nw)
	testing.expect_value(t, size, 1)
	testing.expect(t, city_lot(c, p[0][0], p[0][1]).occupant.band != .Abandoned)
	testing.expect(t, city_lot(c, p[0][0], p[0][1]).occupant.band != .Struggling)
}

@(test)
empty_lot_is_not_construction :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	testing.expect(t, !in_construction(c, 0, 0))
}

@(test)
park_is_not_construction :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	paint_road(c, 0, 0)
	testing.expect(t, stamp(c, 1, 0, .Park))
	testing.expect(t, !in_construction(c, 1, 0))
	rem_occ := city_lot(c, 1, 0).occupant
	rem := rem_occ.remaining
	rok := rem_occ.present
	testing.expect(t, rok)
	testing.expect_value(t, rem, u8(0))
}

@(test)
construction_ends_when_the_house_finishes :: proc(t: ^testing.T) {
	c := city_new()
	defer free(c)
	p, ok := supplied_plots(c, 1)
	testing.expect(t, ok)
	hx, hy := p[0][0], p[0][1]
	paint_zone(c, hx, hy, .Residential)
	tick(c, pick_first)
	testing.expect(t, in_construction(c, hx, hy))
	await_finished(c, hx, hy)
	testing.expect(t, !in_construction(c, hx, hy))
	rem_occ := city_lot(c, hx, hy).occupant
	rem := rem_occ.remaining
	rok := rem_occ.present
	testing.expect(t, rok)
	testing.expect_value(t, rem, u8(0))
}
