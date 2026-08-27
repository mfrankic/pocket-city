package city

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
	testing.expect_value(t, lot.building, Building.None)
	corner := city_lot(c, 31, 31)
	testing.expect_value(t, corner.kind, Lot_Kind.Plot)
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
	testing.expect_value(t, lot.building, Building.None)
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
house_grows_on_road_adjacent_residential :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Residential)
	tick(&c, pick_first)
	testing.expect_value(t, city_lot(c, 1, 0).building, Building.House)
	testing.expect_value(t, city_population(c), 4)
	testing.expect_value(t, city_residential_demand(c), 4)
	testing.expect_value(t, city_commercial_demand(c), 4)
}

@(test)
zoned_plot_without_road_does_not_grow :: proc(t: ^testing.T) {
	c := city_new()
	paint_zone(&c, 5, 5, .Residential)
	tick(&c, pick_first)
	testing.expect_value(t, city_lot(c, 5, 5).building, Building.None)
	testing.expect_value(t, city_population(c), 0)
}

@(test)
tick_grows_one_house_and_one_shop :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Residential)
	paint_zone(&c, 0, 1, .Commercial)
	tick(&c, pick_first)
	testing.expect_value(t, city_lot(c, 1, 0).building, Building.House)
	testing.expect_value(t, city_lot(c, 0, 1).building, Building.None)
	tick(&c, pick_first)
	testing.expect_value(t, city_lot(c, 0, 1).building, Building.Shop)
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
	testing.expect_value(t, city_lot(c, 0, 0).building, Building.House)
	testing.expect_value(t, city_lot(c, 2, 0).building, Building.None)
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
	testing.expect_value(t, city_lot(c, 0, 0).building, Building.None)
	testing.expect_value(t, city_lot(c, 2, 0).building, Building.House)
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
	testing.expect_value(t, lot.building, Building.None)
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
house_stays_after_shop_is_bulldozed :: proc(t: ^testing.T) {
	c := city_new()
	paint_road(&c, 0, 0)
	paint_zone(&c, 1, 0, .Residential)
	paint_zone(&c, 0, 1, .Commercial)
	tick(&c, pick_first)
	tick(&c, pick_first)
	bulldoze(&c, 0, 1)
	testing.expect_value(t, city_lot(c, 1, 0).building, Building.House)
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
	testing.expect_value(t, lot.building, Building.None)
	testing.expect_value(t, city_population(c), 0)
}
