# 05: Stamp seven facilities

**What to build:** The player stamps Station, Tower, Park, School, Police, Firehouse, and Hospital onto empty plots. Stamps need road access, cost money, and clear any zone. A Tower must touch a lake. A Station may be 2×2. They occupy space and show as stamps; they do not yet supply power, water, or coverage effects.

**Blocked by:** 02: Buildings are records; 03: Industrial, factories, three demands

**Status:** claimed

- [x] Tools exist for all seven facilities; all are stampable from the start (money is the gate)
- [x] Stamp requires an empty plot (or a 2×2 of empty plots for a 2×2 Station), in bounds, with cardinal road access
- [x] Stamp on a zoned plot clears the zone; cannot stamp a road, lake, or rock; forest must be grass first
- [x] A Tower is refused unless a cardinal neighbor is lake
- [x] A Station may occupy a 2×2 rectangle; bulldozing any lot of it removes the whole facility
- [x] Grown buildings still dribble onto remaining empty zoned plots
- [x] Save/load keeps facilities and footprints
