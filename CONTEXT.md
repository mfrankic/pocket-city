# Pocket City

A tiny top-down city builder. The player paints lots; aggregate numbers make the city grow or stall. There are no individual people, cars, or utility networks.

## Language

**Lot**:
One square on the 32×32 city grid. A lot is either a Road or a Plot.
_Avoid_: Tile, cell, block

**Road**:
A lot used for access. It cannot have a zone or a building.
_Avoid_: Street, path, highway

**Plot**:
A lot that is not a road. It may have a zone, a building, or both. Demolishing a building leaves the zone.
_Avoid_: Parcel, lot (lot is the grid square, including roads)

**Zone**:
A designation on a plot: Residential or Commercial. A zoned plot with no building is waiting to grow. Industrial is not a zone.
_Avoid_: District, land use, industrial

**Building**:
The developed occupant of one plot. Either a House or a Shop. It stays until the player demolishes it.
_Avoid_: Structure, agent, construction, abandonment

**House**:
A residential building. Every house has the same population.
_Avoid_: Home, apartment, residence

**Shop**:
A commercial building. Every shop has the same jobs.
_Avoid_: Store, office, factory

**Population**:
The count of people living in houses. A number, not a set of people.
_Avoid_: Citizens, residents, agents

**Jobs**:
The count of workplaces on shops. A number, not filled positions.
_Avoid_: Employment, workers, commuters

**Demand**:
Two city-wide numbers (Residential and Commercial) that say whether zoned plots of that kind may grow. Residential includes a base so a city with no jobs is not stuck at zero.
_Avoid_: Desire, need, market

**Money**:
The city's treasury. Placing roads and zones spends it. Income is a constant tax times population. Reaching zero does not end the game; it only blocks spending.
_Avoid_: Budget, cash, funds, tax slider
