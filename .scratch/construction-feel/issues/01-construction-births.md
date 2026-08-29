# 01: Construction births

**What to build:** A new house, shop, or factory occupies its plots in Construction for one Month of ticks from birth, produces nothing, then becomes level 1 with health. Facilities stay instant. Save and load keep remaining ticks. Construction looks unfinished in the default view.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] A new house, shop, or factory appears in Construction and occupies its plots
- [ ] Construction lasts one Month of ticks from birth (not aligned to the calendar month), then becomes level 1 with full health
- [ ] Construction produces no population or jobs; happiness ignores it; an only-Construction city is not collapsing
- [ ] Facilities stamp finished; level-up stays instant and skips Construction
- [ ] An outage does not freeze remaining ticks; fire may sit on the lots but does not nibble until health exists
- [ ] Bulldozing Construction removes the building and keeps the zone
- [ ] Construction counts for traffic; at most one new Construction per grown kind per tick
- [ ] Save/load keeps Construction and remaining ticks; a junk or old-version file leaves the current city alone
