# Pocket City

A top-down city builder on a 64×64 grid. The player paints lots and stamps facilities; aggregate numbers make the city grow, stall, or fail. There are no individual people or cars.

## Language

**Lot**:
One square on the 64×64 city grid. A lot has terrain. A lot is either a Road or a Plot.
_Avoid_: Tile, cell, block

**Terrain**:
Grass (buildable), Lake (not buildable; a Tower must touch it), Forest (becomes Grass when bulldozed), or Rock (not buildable).
_Avoid_: Biome, tile type, water (water is the utility)

**Road**:
A lot used for access. It cannot have a zone or a building. It cannot be painted on Lake or Rock.
_Avoid_: Street, path, highway

**Plot**:
A lot that is not a road. It may have a zone, a building, or both. Demolishing a building leaves the zone.
_Avoid_: Parcel, lot (lot is the grid square, including roads)

**Zone**:
A designation on a plot: Residential, Commercial, or Industrial. A zoned plot with no building is waiting to grow.
_Avoid_: District, land use

**Industrial**:
A zone. It grows a Factory, not population.
_Avoid_: Manufacturing, dirty commercial

**Building**:
The occupant of a rectangle of plots (1×1 or 2×2). Either a House, Shop, Factory, or Facility. Size is chosen at birth from land value and does not change. Those plots all belong to that building. The stamp may be irregular pixels inside the rectangle. It stays until the player demolishes it or it is Abandoned.
_Avoid_: Structure, agent, blob

**House**:
A residential building. Population is a base times level times the plots it occupies. It cannot go above level 1 without education, or above level 2 without Hospital coverage.
_Avoid_: Home, apartment, residence

**Shop**:
A commercial building. Jobs are a base times level times the plots it occupies.
_Avoid_: Store, office, factory

**Factory**:
An industrial building. Jobs and pollution scale with level and plots. It does not provide population.
_Avoid_: Plant, works, mill, warehouse

**Level**:
An integer 1–3 on a grown building. Facilities have no level.
_Avoid_: Upgrade, density, tier

**Facility**:
A building the player stamps onto empty plots. It does not grow from a zone. It needs road access. Stamping a zoned plot clears the zone. Kinds: Station, Tower, Park, School, Police, Firehouse, Hospital. All seven are stampable from the start.
_Avoid_: Service, utility, civic, amenity

**Station**:
The facility that supplies Power. It needs nothing. It may be 2×2.
_Avoid_: Plant, generator, power plant

**Tower**:
The facility that supplies Water. It must touch a Lake. It needs Power.
_Avoid_: Pump, water plant, reservoir

**Coverage**:
A square of lots around a Park, School, Police, Firehouse, or Hospital. It counts through roads. School, Police, Firehouse, and Hospital have none without Power. Park does not need Power.
_Avoid_: Radius, aura, catchment

**Education**:
Whether a plot has School coverage.
_Avoid_: Schooling, knowledge, students

**Crime**:
A per-plot number from local density, city unemployment, and Police coverage. It nibbles shop health and lowers land value. It does not nibble houses and does not read happiness.
_Avoid_: Safety, law, unrest

**Fire**:
A per-plot intensity from 0 to 1. It may spread to cardinal plots (not road, lake, or rock). Firehouse coverage decays it and blocks ignition. A finished building on a burning plot takes a health nibble.
_Avoid_: Blaze, wildfire, agent

**Construction**:
A grown building that occupies its plots but is not finished. It lasts one Month of ticks from birth, then becomes level 1 with health. It produces no population or jobs. Facilities are never in Construction.
_Avoid_: scaffolding, building site, Active

**Health**:
A per-building number from 0 to 1. Struggling and Abandoned are bands on it. Construction has no health yet.
_Avoid_: Condition, durability, HP, wellness

**Struggling**:
A building whose health is in the middle band. It still occupies its plots and still produces population or jobs.
_Avoid_: Decaying, failing, unhappy

**Abandoned**:
A building whose health has hit the bottom band. It still occupies its plots, produces no population or jobs, and shows as a husk. The zone stays. It may recover if health rises, or the player demolishes it.
_Avoid_: Rotting, vacant, ruined, demolished

**Happiness**:
The city-wide average of health on finished buildings. Construction is excluded. HUD and graphs only. It does not nibble health.
_Avoid_: Mood, approval

**Window**:
The map (lots, stamps, Overlay coloring) and the HUD on screen. It is not the city.
_Avoid_: GUI, renderer, view, screen

**HUD**:
The chrome around the map. It shows city numbers, graphs, the lot under the cursor, and the keys. It is not the map.
_Avoid_: overlay (overlays color lots), status bar, GUI

**Graph**:
A month-sampled history of Population, Jobs, Money, or Happiness. It is not the live HUD number.
_Avoid_: chart, sparkline, plot

**Inspect**:
The HUD region that shows the lot under the cursor. When the cursor is on other HUD chrome or off the map, it shows no lot.
_Avoid_: tooltip, popup, separate inspect window

**Overlay**:
A coloring of the map by one per-plot number or flag. It is not the HUD.
_Avoid_: filter, layer, vision, HUD overlay

**Tax**:
A city-wide rate the player sets. Income is tax times population. Maintenance is not tax.
_Avoid_: Tariff, three rates, slider (the rate is the thing)

**Maintenance**:
A running cost on each Road lot and each Facility, subtracted from Money every tick. Grown buildings are not billed this way.
_Avoid_: upkeep, expense, overhead

**Traffic**:
Per connected road component, grown buildings divided by road lots.
_Avoid_: Congestion, trips, cars

**Power**:
Whether a plot is supplied by a Station through connected roads.
_Avoid_: Electricity, energy, grid

**Water**:
Whether a plot is supplied by a Tower through connected roads.
_Avoid_: Piped, plumbing, irrigated

**Pollution**:
A per-plot number. Factories emit it; it spreads to cardinal lots and decays. Roads and lakes hold it. A house reads the worst plot in its footprint.
_Avoid_: Smog, dirt, contamination

**Land value**:
A per-plot number derived from road access, pollution, nearby facilities, and terrain. It is not money.
_Avoid_: Price, rent, desirability

**Population**:
The count of people living in houses. A number, not a set of people.
_Avoid_: Citizens, residents, agents

**Jobs**:
The count of workplaces on shops and factories. A number, not filled positions.
_Avoid_: Employment, workers, commuters

**Demand**:
Three city-wide numbers (Residential, Commercial, Industrial). They say whether that kind may grow a new building and whether a grown building of that kind may gain a level. Residential is jobs minus population, plus a base so a city with no jobs is not stuck at zero. Commercial is population minus shop jobs. Industrial is shop jobs minus factory jobs.
_Avoid_: Desire, need, market

**Month**:
A span of ticks. Fire spread and decay, outage rolls, ignition rolls, graphs, and Construction duration use it. Income, health, and Maintenance change every tick. The hour on the HUD is not a rule.
_Avoid_: Day/night cycle, hour as a mechanic

**Outage**:
A month when Stations supply no Power.
_Avoid_: Blackout, event, disaster (fire is the other one)

**Money**:
The city's treasury. Placing roads, zones, and facilities spends it. Maintenance also subtracts. Income is tax times population. Reaching zero does not end the game; it only blocks spending.
_Avoid_: Budget, cash, funds
