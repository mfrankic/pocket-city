# 01: 64×64 terrain and camera

**What to build:** A new city is a 64×64 grid with generated grass, lake, forest, and rock. The player pans and zooms, cannot paint on lake or rock, and bulldozes forest into grass for money. The two-zone toy still plays on this map. Save and load keep terrain.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] A new city is 64×64 lots, each with terrain (grass, lake, forest, or rock), generated at city creation
- [ ] The player cannot paint a road or zone on lake or rock
- [ ] Bulldozing forest spends money and turns that lot to grass; bulldozing grass/road/building behaves as today
- [ ] The player can pan and zoom the map
- [ ] Residential/commercial paint, roads, dribble growth, money, pause, and HUD still work
- [ ] Save/load round-trips the larger map and terrain; a junk or old-size file leaves the current city alone
