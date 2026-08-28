# 02: Buildings are records

**What to build:** A house or shop still occupies one plot and the city plays as after 01, but occupancy is a building identity shared by its plots, not a kind painted on the lot. Save and load still round-trip the city. This is the prefactor for stamps, 2×2 footprints, and health.

**Blocked by:** 01: 64×64 terrain and camera

**Status:** ready-for-agent

- [ ] Growing a house or shop still dribbles the same way; population, jobs, and demand match the two-zone rules
- [ ] Each occupied plot points at one building; demolishing any lot of it removes that building and leaves the zone
- [ ] Painting a different zone on an occupied plot removes the building and keeps the new zone
- [ ] The window still shows house/shop/empty/road as before
- [ ] Save/load round-trips buildings by identity; junk files leave the current city alone
- [ ] Existing growth, paint, and money tests still pass in spirit (one house and one shop per tick, etc.)
