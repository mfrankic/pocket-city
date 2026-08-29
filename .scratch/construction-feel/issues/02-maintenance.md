# 02: Maintenance

**What to build:** Every running tick, after income, the city pays Maintenance on each Road lot and each Facility. Grown buildings are not billed. Money floors at 0, still blocks spending, and does not end the game. A new city can still paint a first neighborhood.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] Each running tick charges Maintenance on each road lot and each facility
- [x] Grown buildings are not billed; income is still tax times population in the same tick, then Maintenance, then money floors at 0
- [x] Zero money still blocks spending and does not end the game
- [x] Pause charges no Maintenance
- [x] Starting money and rates still let the player paint a first neighborhood
- [x] Save/load keeps money after Maintenance

## Answer

Each running `tick` adds tax × population, then charges 1 per Road lot and 1 per Facility, then floors Money at 0. Grown buildings are not billed. Pause still means the window does not call `tick`. Starting money still covers a first neighborhood. Save already stored money; no format bump.
