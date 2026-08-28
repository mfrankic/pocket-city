# PIXEL CITY

**Status:** ready-for-agent

The player already has a 32×32 two-zone toy. This spec is the confirmed game: 64×64 fail/recover PIXEL CITY behind the existing `city` seam. Glossary: `CONTEXT.md`. Decisions: ADR-0003 (accepted), ADR-0007 through ADR-0011 (accepted). ADR-0001, 0002, 0004, 0005, 0006 are superseded.

## Problem Statement

The small game can be painted and watched, but nothing can go wrong in a way the player has to fix. There is no industrial belt, no utilities to cover, no husk, no reason to stamp anything but roads and two zones. The player wants the ChatGPT PIXEL CITY finish: a city that grows, jams, pollutes, burns, and recovers, still with no people and no cars, still a lot grid with colored stamps.

## Solution

Keep one module — the city — as the whole simulation. The window only paints, stamps, pans, and reads overlays. The player paints roads and three zones, stamps seven facilities, and sets a tax rate. Houses, shops, and factories dribble in and level up. Power and water follow roads. Parks and civic stamps cover squares of lots. Health can fail into a visible husk. Fire and outages roll once a month. There is no win. Money at zero only blocks spending.

## User Stories

1. As a player, I want a 64×64 city of lots, so that the map feels like a small city rather than a postage stamp.
2. As a player, I want each lot to be grass, lake, forest, or rock when the city is created, so that the map is not a blank green field.
3. As a player, I want lakes and rock unbuildable, so that I must work around geography.
4. As a player, I want a tower to require a touching lake, so that water supply is a placement puzzle.
5. As a player, I want forest to become grass when I bulldoze it, so that I can clear land for a cost.
6. As a player, I want not to paint roads or zones on lake or rock, so that illegal paint is refused.
7. As a player, I want to paint a road on grass for money, so that buildings can get access.
8. As a player, I want painting a road on a road to do nothing and spend nothing, so that drag-paint is safe.
9. As a player, I want to paint residential, commercial, or industrial on a plot for money, so that growth has somewhere to go.
10. As a player, I want painting the same zone again to spend nothing, so that drag-paint is safe.
11. As a player, I want not to zone a road, so that roads stay access.
12. As a player, I want demolishing a building to leave the zone, so that I do not re-paint after a husk.
13. As a player, I want demolishing a road to leave an empty plot, so that I can re-plan streets.
14. As a player, I want stamping a facility to clear any zone on that plot, so that a station is not also residential.
15. As a player, I want every facility to need road access, so that stamps sit on the network.
16. As a player, I want all seven facilities stampable from the start, so that money is the gate, not unlocks.
17. As a player, I want to stamp a station, so that a road component can have power.
18. As a player, I want a station to need no power or water itself, so that the city can boot.
19. As a player, I want a station to be allowed 2×2, so that a plant looks like a plant.
20. As a player, I want to stamp a tower on a plot that touches a lake, so that water can flow along roads.
21. As a player, I want a tower to need power, so that an outage dries taps.
22. As a player, I want to stamp a park without power, so that a green square still raises land value in the dark.
23. As a player, I want to stamp a school, police, firehouse, or hospital, so that coverage is a placement decision.
24. As a player, I want those four to have no coverage when unpowered, so that an outage shuts civic stamps.
25. As a player, I want coverage to be a square of lots that counts through roads, so that a park across the street still works.
26. As a player, I want school coverage to be education, so that houses cannot densify without schools.
27. As a player, I want a house to stay at level 1 without education, so that missing schools cap density, not kill the block.
28. As a player, I want a house to need hospital coverage to reach level 3, so that hospitals are the last density gate.
29. As a player, I want police coverage to lower crime, so that police is not a park.
30. As a player, I want crime to nibble shop health and land value, not houses or happiness, so that commercial feels unsafe streets.
31. As a player, I want a firehouse to decay fire and block ignition in its coverage, so that I recover from fire by stamping cover.
32. As a player, I want houses to appear one at a time when residential demand is positive, so that the city dribbles rather than flashes.
33. As a player, I want shops to appear one at a time when commercial demand is positive, so that jobs follow people.
34. As a player, I want factories to appear one at a time when industrial demand is positive, so that shops pull manufacturing.
35. As a player, I want a new grown building to appear complete at level 1, so that I do not watch construction frames.
36. As a player, I want high land value to birth 2×2 footprints and low land value to birth 1×1, so that rich land looks bigger.
37. As a player, I want that size frozen for the life of the building, so that leveling does not eat neighboring lots.
38. As a player, I want population and jobs to be base times level times plots, so that a 2×2 level-1 house equals four 1×1 level-1 houses.
39. As a player, I want at most one level-up per grown kind per tick, so that density rises slowly.
40. As a player, I want a level-up only when that demand is positive, land value is high enough, health is not abandoned, and gates are met, so that husks and missing schools do not densify.
41. As a player, I want abandoned buildings never to level, so that rot is not also a promotion.
42. As a player, I want residential demand to be base plus all jobs minus population, so that a new city can start and jobs pull houses.
43. As a player, I want commercial demand to be population minus shop jobs, so that people want shops specifically.
44. As a player, I want industrial demand to be shop jobs minus factory jobs, so that factories are not a second commercial.
45. As a player, I want growth only on footprints that touch a road, so that I must paint access.
46. As a player, I want a 2×2 footprint to need only some plot touching a road, not every plot, so that large buildings are not rings of asphalt.
47. As a player, I want power to flood-fill along connected roads from stations, up to capacity in plots, so that a second station is a real decision.
48. As a player, I want water to flood-fill the same way from towers, so that I learn one graph.
49. As a player, I want grown buildings that lack power or water to lose health, so that coverage holes become husks.
50. As a player, I want to see which plots are powered and watered on overlays, so that I can find the dark side of town.
51. As a player, I want each building to have health from 0 to 1, so that fail is gradual.
52. As a player, I want struggling buildings to keep producing population or jobs, so that the stamp is a warning, not a second abandon.
53. As a player, I want abandoned to be a bottom band, not only exactly 0, so that a husk lasts more than one regen tick.
54. As a player, I want an abandoned building to occupy its plots, produce nothing, keep its zone, and look like a husk, so that I must bulldoze or wait for recovery.
55. As a player, I want health to rise when causes lift, so that fixing power can revive a husk.
56. As a player, I want happiness to be the city-wide average of health on the HUD and graphs only, so that I do not count the same pain twice.
57. As a player, I want missing power or water to nibble health, so that utilities matter.
58. As a player, I want traffic on a road component (grown buildings divided by road lots) to nibble health of grown buildings on that component, so that extra roads are the recover action.
59. As a player, I want a tax rate I set, with income equal to tax times population, so that tax is a lever.
60. As a player, I want high tax to nibble health, so that greedy rates have a cost.
61. As a player, I want unemployment (population above jobs) to nibble house health only, so that a job shortage empties homes, not shops.
62. As a player, I want local pollution to nibble house health, so that industrial next to residential hurts those houses, not the whole map equally.
63. As a player, I want factories to emit pollution that spreads to cardinal lots and decays, so that I see a belt on the overlay.
64. As a player, I want roads and lakes to hold pollution, so that a one-lot moat does not hide smoke.
65. As a player, I want a house to read the worst pollution in its footprint, so that a 2×2 on a dirty corner suffers.
66. As a player, I want land value derived from road access, pollution, nearby facilities, and terrain, so that growth prefers nicer plots.
67. As a player, I want land value not to be money, so that I do not confuse treasury with dirt.
68. As a player, I want an overlay for pollution, land value, traffic, fire, crime, and education, plus power and water, so that the picture can carry the sim.
69. As a player, I want one overlay at a time, so that the map stays readable.
70. As a player, I want struggling and husk visible without an overlay, so that fail is obvious in the default view.
71. As a player, I want fire as per-plot intensity, not a moving agent, so that the lot grid stays the world.
72. As a player, I want fire to spread to cardinal plots with a low chance, never onto road, lake, or rock, so that streets are firebreaks.
73. As a player, I want a building on a burning plot to take a health nibble, so that fire uses the same fail bar.
74. As a player, I want firehouse coverage to decay intensity and block new ignition, so that I recover by stamping cover.
75. As a player, I want each month a small chance to ignite a random grown-building plot that has no firehouse coverage, so that fire happens without a debug key.
76. As a player, I want each month a small chance of an outage (stations supply no power for that month), so that I feel a dark month.
77. As a player, I want fire and outage to be allowed in the same month, so that bad luck can stack.
78. As a player, I want income and health to change every tick, so that money is smooth.
79. As a player, I want fire spread, decay, ignition, outage, and graphs to use the month, so that disasters are slow.
80. As a player, I want a clock on the HUD whose hour is not a rule, so that I see time without a day/night sim.
81. As a player, I want history graphs of population, jobs, money, and happiness (and other fail stats that exist), bucketed by month, so that I can see a decline.
82. As a player, I want to pan and zoom, so that 64×64 stamps and overlays are usable.
83. As a player, I want to pause and run, so that I can paint without the city moving.
84. As a player, I want tools for road, three zones, bulldoze, and each facility, so that I can do every verb.
85. As a player, I want a control for the tax rate, so that tax is not a hidden constant.
86. As a player, I want HUD for money, population, jobs, three demands, happiness, pause, and current tool, so that I know why the city is stuck.
87. As a player, I want zero money to block spending but not end the game, so that I can wait for tax.
88. As a player, I want placing roads, zones, and facilities to spend money, so that expansion has a cost.
89. As a player, I want to save and load the whole city (lots, buildings, money, tax, time, health, fire, pollution), so that a session can stop.
90. As a player, I want a failed load to leave the current city alone, so that a junk file is not a crash.
91. As a player, I want no win screen, so that recovery is the game, not a score.
92. As a player, I want no individual people or cars, so that the sim stays aggregates.
93. As a player, I want stamps that may look irregular inside the rectangle, so that a house is a pixel object without a pixel sim.
94. As a player, I want bulldozing any lot of a building to remove the whole building and keep zones, so that a 2×2 is one object.
95. As a player, I want painting a different zone on one lot of a building to remove the whole building, so that rezone is not a hole in a footprint.
96. As a player, I want new growth to skip plots occupied by husks, so that abandoned land is a cleanup decision.
97. As a player, I want facilities to ignore unemployment and pollution nibbles, so that a station does not rot from jobless houses (they can still burn).
98. As a player, I want crime computed from local density, city unemployment, and police coverage, so that police is local.
99. As a player, I want starting money and costs to let me paint a first neighborhood, so that a new city is not stuck at zero.

## Implementation Decisions

- One module: the city. All rules live there. The window is an adapter: input, camera, overlays, HUD, graphs, stamps. Tests and the window call the same commands and getters.
- Map size is 64. `city_new` generates terrain (grass with some lakes, forests, and rocks). The player does not paint terrain.
- A lot has terrain and is a road or a plot. A plot may have a zone. Occupancy is a building identity shared by a 1×1 or 2×2 rectangle of plots, not an enum on a single lot. Lots without a building have no identity.
- Grown kinds: house, shop, factory. Stamped kinds: station, tower, park, school, police, firehouse, hospital. Facilities have no level. Stamp requires an empty plot (or rectangle for 2×2 station), road access, and (for tower) a cardinal lake neighbor. Stamp on a zoned plot clears the zone.
- Each tick: recompute power, water, traffic per road component, pollution (emit, cardinal spread, decay), land value, crime, coverage, education; apply health deltas; then at most one new house, shop, factory and at most one level-up of each of those kinds; then add income (tax × population). Month counters fire spread/decay, ignition, outage, and graph samples. Hour/day/year are derived for the HUD.
- Randomness for growth picks and monthly disaster rolls is injected at tick (same idea as today’s `Pick`), so tests are deterministic.
- Demand is city-wide: residential = base + (shop jobs + factory jobs) − population; commercial = population − shop jobs; industrial = shop jobs − factory jobs. Growth and level-up need that demand positive, a footprint of empty same-zone plots (or an existing grown building for level-up), and cardinal road access on the footprint.
- Power and water: flood-fill along roads from powered stations / from towers that have power. Capacity is a constant per facility times its plots. Outage: stations contribute 0 for that month.
- Health 0–1. Causes as grilled. Happiness = average health of buildings (define empty city as 1 or 0 consistently; prefer 1 so a new city is not “collapsing”). Abandoned is a bottom band; struggling a middle band. Production full unless abandoned.
- Tax is one city-wide number the player sets; default should make early income similar to the old constant-per-pop. High tax nibbles health.
- Save is versioned. A size or version mismatch returns not-ok and does not change the current city. Save the sim, not camera or overlay.
- Named constants (map size aside) are balance: costs, capacities, coverage square size, land-value 2×2 threshold, health bands, month length, fire spread chance, disaster chances, nibble rates, starting money. Do not invent extra systems to avoid picking a constant.
- Stamps in the window may be irregular pixels inside the rectangle; the sim does not store pixel masks.
- Do not add a second lot kind for wires or pipes. Do not add agents, ECS, or threads.

## Testing Decisions

- A good test is a city, commands, ticks with a deterministic pick, then getters: money, population, jobs, demands, a lot’s kind/zone/terrain, a building’s kind/level/health/footprint, power/water/pollution/fire/crime/education on a plot. No Raylib. No snapshot of private arrays except through getters already meant for the window.
- Test the city module only. Prior art: `city` tests that paint, tick with `pick_first`, and `expect_value` on money, lot fields, and demands; save/load round-trips; junk files leave the city alone.
- Cover: 64×64 bounds; terrain blocks paint; forest bulldoze; three zones; stamp clears zone and refuses without road or lake; demand formulas; one-per-kind dribble and one-per-kind level-up; 2×2 birth vs 1×1; school/hospital gates; power/water flood-fill and outage; health bands and husk occupancy; tax income; traffic nibble on a jammed component; pollution spread; crime on shops; fire spread and firehouse; month vs tick; save version.

## Out of Scope

- Individual people, cars, pathfinding trips, pixel-canvas simulation, 3×3 or free-form occupancy, city-block cells.
- Wire/pipe lots, radius power, land value as a stored resource or second diffusion field.
- Day/night rules, disasters other than fire and outage, ChatGPT event structs, three tax sliders, facility unlocks, a win/population target.
- Crime that reads happiness; happiness as a health nibble; struggling that scales production.
- Multiplayer, 3D, mods, ECS, threading, a map editor for terrain.
- Testing the window, camera, or overlay drawing.

## Further Notes

- Vocabulary is `CONTEXT.md`. If a ticket wants a synonym on the Avoid list, the glossary wins.
- ADR-0003 still holds (road or plot). ADR-0007 occupancy, 0008 product, 0009 demands and levels, 0010 health and dribble, 0011 roads and squares.
- Next step is `/to-tickets`: vertical slices through this spec, each demoable, blocked by earlier slices, implemented with `/implement` in a fresh window.
