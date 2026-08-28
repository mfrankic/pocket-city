# 04: Tax rate

**What to build:** The player sets one city-wide tax rate. Income each tick is tax times population. Reaching zero money still only blocks spending. Default rate keeps early income in the same ballpark as the old constant-per-person tax.

**Blocked by:** 01: 64×64 terrain and camera

**Status:** ready-for-agent

- [ ] The player can raise and lower a single city-wide tax from the HUD or keys
- [ ] Each tick, money increases by tax × population (not a hidden constant)
- [ ] Zero money still blocks paint/spend and does not end the game
- [ ] Save/load keeps the tax rate
- [ ] HUD shows the current tax
