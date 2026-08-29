# 09: Land value, 2×2, levels, school and hospital

**What to build:** Land value (from road access, pollution, nearby facilities, terrain) decides whether a new house, shop, or factory is 1×1 or 2×2 at birth; size never changes. Each tick, at most one level-up per grown kind (1–3) when demand, land value, and health allow. A house cannot exceed level 1 without education (School coverage) or level 2 without Hospital coverage. Coverage is a square of lots through roads; School and Hospital need power for coverage; Park raises land value and does not need power. Population and jobs are base × level × plots.

**Blocked by:** 05: Stamp seven facilities; 07: Health, husks, happiness; 08: Pollution belt

**Status:** claimed

- [x] High land value births a 2×2 rectangle when four empty same-zone plots exist and the footprint touches a road; otherwise 1×1
- [x] Size is frozen; level-up does not grow the rectangle
- [x] Each tick at most one level-up per grown kind; abandoned buildings never level
- [x] Level 2 house requires School coverage on its plots; level 3 requires Hospital coverage
- [x] School/Hospital/Police/Firehouse coverage is a square of lots and is none without power; Park coverage does not need power and raises land value
- [x] Population and jobs scale as base × level × plots in the footprint
- [x] The player can toggle a land value overlay and an education overlay
- [x] Save/load keeps level and footprint
