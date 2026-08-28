# 06: Power and water

**What to build:** Stations supply power and Towers supply water along connected roads, up to a capacity in plots. Overlays show which plots are powered and watered. New houses, shops, and factories only grow on plots that have both. A Tower needs power; a Station needs nothing; a Park does not need power.

**Blocked by:** 05: Stamp seven facilities

**Status:** ready-for-agent

- [ ] Power flood-fills along connected roads from Stations, up to that Station’s capacity in plots
- [ ] Water flood-fills the same way from Towers that have power, up to capacity
- [ ] The player can toggle a power overlay and a water overlay
- [ ] A new house, shop, or factory does not grow on a plot that lacks power or water
- [ ] A Tower with no power supplies no water; a Station always attempts to supply (no self-power requirement)
- [ ] An unconnected road component stays dark/dry
- [ ] Save/load does not need to store the flags if they recompute; the city after load matches the same supplies
