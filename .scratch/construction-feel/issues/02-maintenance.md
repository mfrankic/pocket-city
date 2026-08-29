# 02: Maintenance

**What to build:** Every running tick, after income, the city pays Maintenance on each Road lot and each Facility. Grown buildings are not billed. Money floors at 0, still blocks spending, and does not end the game. A new city can still paint a first neighborhood.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] Each running tick charges Maintenance on each road lot and each facility
- [ ] Grown buildings are not billed; income is still tax times population in the same tick, then Maintenance, then money floors at 0
- [ ] Zero money still blocks spending and does not end the game
- [ ] Pause charges no Maintenance
- [ ] Starting money and rates still let the player paint a first neighborhood
- [ ] Save/load keeps money after Maintenance
