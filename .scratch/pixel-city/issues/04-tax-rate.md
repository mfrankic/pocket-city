# 04: Tax rate

**What to build:** The player sets one city-wide tax rate. Income each tick is tax times population. Reaching zero money still only blocks spending. Default rate keeps early income in the same ballpark as the old constant-per-person tax.

**Blocked by:** 01: 64×64 terrain and camera

**Status:** claimed

- [x] The player can raise and lower a single city-wide tax from the HUD or keys
- [x] Each tick, money increases by tax × population (not a hidden constant)
- [x] Zero money still blocks paint/spend and does not end the game
- [x] Save/load keeps the tax rate
- [x] HUD shows the current tax
