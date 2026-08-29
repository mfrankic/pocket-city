# Construction, maintenance, and feel

**Status:** ready-for-agent

PIXEL CITY is already playable. This spec is the next slice from the ChatGPT catalog: Construction, Maintenance, and window feel (stamps, inspect, speed, power/water on the HUD). Glossary: `CONTEXT.md`. Decisions: ADR-0003, 0007–0012 (accepted).

## Problem Statement

Grown buildings pop in finished, so the city never looks like it is being built. Money only goes down when the player paints, so a large road net is free to keep. The map is solid rectangles, there is no lot inspect, speed is fixed, and power/water live only on overlays. The player cannot see the catalog’s “buildings evolve” beat, cannot feel a two-sided treasury, and cannot read a lot or hurry time without leaving the default view.

## Solution

A new house, shop, or factory occupies its plots in Construction for one Month of ticks, produces nothing, then becomes level 1 with health. Facilities stay instant. Every tick, Maintenance bills each Road lot and each Facility; Money floors at 0. The window draws irregular pixel stamps inside each building rectangle, shows the lot under the cursor, lets the player run 1× / 2× / 4×, and puts power and water percents on the HUD. The `city` seam stays the whole simulation; the window stays the adapter.

## User Stories

1. As a player, I want a new house to appear in Construction rather than finished, so that growth looks like building.
2. As a player, I want a new shop to appear in Construction, so that commercial growth has the same beat.
3. As a player, I want a new factory to appear in Construction, so that industrial growth has the same beat.
4. As a player, I want Construction to last one Month of ticks from birth, so that I can see the scaffold before it finishes.
5. As a player, I want that timer to run from birth, not from the calendar month, so that two houses born on different ticks finish at different times.
6. As a player, I want Construction to become level 1 with full health when the Month is up, so that it then plays by the usual health rules.
7. As a player, I want Construction to occupy its plots, so that nothing else grows on that footprint.
8. As a player, I want Construction to produce no population or jobs, so that demand stays up while it is unfinished.
9. As a player, I want Construction excluded from happiness, so that scaffolds do not look like a collapsing city.
10. As a player, I want a city that is only Construction (or empty) to show happiness as not collapsing, so that a new town is not already failing.
11. As a player, I want facilities to stamp finished, so that a station I place is not a month of darkness.
12. As a player, I want level-up to stay instant, so that density does not freeze a house for another Month.
13. As a player, I want Construction never to level, so that an unfinished house does not densify.
14. As a player, I want an outage not to freeze Construction, so that a dark month does not leave permanent scaffolds.
15. As a player, I want growth to still start only on powered and watered plots, so that Construction does not appear in the dark.
16. As a player, I want fire intensity to be allowed on Construction lots, so that fire is not a special case.
17. As a player, I want fire not to nibble Construction, so that a scaffold without health is not instantly a husk.
18. As a player, I want a finished building that is still on fire to nibble as today, so that finishing into a blaze can husk.
19. As a player, I want bulldozing Construction to remove the building and keep the zone, so that a scaffold is not a trap.
20. As a player, I want Construction to count as a grown building for traffic, so that a building site still loads the road.
21. As a player, I want at most one new Construction per grown kind per tick, so that dribble still holds.
22. As a player, I want several Constructions in flight at once, so that a growing neighborhood is full of scaffolds.
23. As a player, I want save and load to keep Construction and remaining ticks, so that I can quit mid-build.
24. As a player, I want a junk or old-version save to leave the current city alone, so that a format bump is not a crash.
25. As a player, I want Construction to look different from a finished house, shop, or factory, so that I can see it without inspect.
26. As a player, I want every tick to charge Maintenance on each road lot, so that extra asphalt costs money to keep.
27. As a player, I want every tick to charge Maintenance on each facility, so that stamps are not free after placement.
28. As a player, I want grown buildings not to pay Maintenance, so that I am not billed twice (tax already uses population).
29. As a player, I want income still added every tick (tax times population), so that money stays smooth.
30. As a player, I want Maintenance subtracted after income in the same tick, so that a living city can cover its roads.
31. As a player, I want Money to floor at 0 after Maintenance, so that the treasury cannot go negative.
32. As a player, I want zero Money to still block spending and not end the game, so that I can wait for tax.
33. As a player, I want paused time to charge no Maintenance, so that pause still means the city does not move.
34. As a player, I want starting money and Maintenance rates to let me paint a first neighborhood, so that a new city is not instantly broke.
35. As a player, I want save and load to keep Money after Maintenance, so that a drained treasury survives a quit.
36. As a player, I want stamps that may look irregular inside the building rectangle, so that a house is a pixel object without a pixel sim.
37. As a player, I want a 2×2 building’s stamp to fill that rectangle, so that a large house is one object.
38. As a player, I want Construction, struggling, and abandoned to stay readable in the default view, so that fail and build are obvious without an overlay.
39. As a player, I want the lot under the cursor inspected, so that I can read a lot without painting it (left click still paints).
40. As a player, I want inspect to show terrain, road or plot, zone, building kind, Construction remaining ticks when unfinished, level and health when finished, and power, water, pollution, land value, traffic, crime, fire, and education on that lot, so that overlays are not the only way to debug.
41. As a player, I want inspect to update as I move the cursor, so that I can sweep the map.
42. As a player, I want inspect to show nothing illegal when the cursor is off the map or on the HUD, so that the panel does not lie.
43. As a player, I want to run the sim at 1×, 2×, and 4×, so that I can watch or skip time.
44. As a player, I want pause to still stop ticks at any speed, so that I can paint without the city moving.
45. As a player, I want 1× to match today’s tick rate, so that old feel is the default.
46. As a player, I want the HUD to show power percent and water percent, so that I see supply without toggling overlays.
47. As a player, I want those percents to be occupied plots with power (or water) over occupied plots, so that empty grass does not look supplied.
48. As a player, I want an empty city (no buildings) to show those percents as full, so that a new map is not “0% power”.
49. As a player, I want an outage to drop the power percent, so that a dark month is visible on the HUD.
50. As a player, I want existing HUD numbers (money, population, jobs, demands, tax, happiness, clock) to remain, so that feel is additive.
51. As a player, I want no extra simulation systems from the ChatGPT catalog in this slice, so that garbage, extra events, more kinds, and demand nudges wait.

## Implementation Decisions

- One module: the city. Construction remaining ticks, finish, Maintenance, and supply percents live there. The window is an adapter: pixel stamps, cursor inspect, speed, HUD. Tests and the window call the same commands and getters.
- Construction is a grown building with remaining ticks (one Month of ticks at birth). It has no health and no level until it finishes. Finish sets level 1 and health 1 and remaining 0. Facilities never get remaining ticks.
- Each tick: existing derived/health/dribble/level-up/income, then decrement Construction remaining (skip if already 0), finish those that hit 0, then subtract Maintenance, then floor Money at 0. Outage does not pause remaining. Level-up does not enter Construction and skips unfinished buildings.
- Construction counts as a grown building for traffic. It does not produce population or jobs. Happiness averages health only on present buildings that are not Construction; if that set is empty, happiness is 1.
- apply-health and fire nibbles skip Construction. Fire intensity and ignition on lots are unchanged.
- Maintenance is named constants: cost per Road lot and per Facility per tick. Choose values so a new city can paint a first neighborhood on starting money. Do not add demand nudges.
- Supply percent: among lots with a building, the fraction powered and the fraction watered. No buildings → 1. Getters on the city for the HUD.
- Inspect reads existing lot/building getters plus Construction remaining. Cursor position is window-only; left click still paints.
- Speed is window-only: 1× is the current tick interval; 2× and 4× run more city ticks per second. Pause still means zero ticks.
- Stamps are window-only templates inside the occupancy rectangle. The sim does not store pixel masks. Construction, struggling, and husk stay distinct from a healthy finished stamp.
- Save is versioned. Bump the version for Construction remaining. A mismatch returns not-ok and does not change the current city.
- Do not add Small/Large roads, extra grown kinds, unlocks, a win, three taxes, radius coverage, hour-as-rule, 8× speed, hover-to-paint inspect, or a second seam.

## Testing Decisions

- A good test is a city, commands, ticks with a deterministic pick, then getters: Construction remaining, population/jobs still zero until finish, health appears at finish, happiness ignores Construction, Maintenance drops money, money never negative, supply percents, save/load remaining ticks. No Raylib. No snapshot of private arrays except through getters meant for the window.
- Test the city module only. Prior art: `city` tests that grow with `pick_first`, `expect_value` on money and lot fields, health bands, month vs tick, save/load junk files leave the city alone.
- Cover: birth enters Construction; one Month of ticks later it is level 1 with health and production; facilities are never Construction; level-up skips Construction and does not add remaining ticks; outage does not freeze remaining; fire intensity can exist without nibble during Construction; bulldoze Construction keeps zone; traffic counts Construction; Maintenance on roads and facilities; grown buildings not billed; income then Maintenance then floor 0; broke still cannot spend; empty city supply percents are 1; occupied unpowered lots pull power percent down; save version mismatch leaves city alone.

## Out of Scope

- Garbage, extra events (recession, drought, boom, pollution spike), Apartment/Office/Warehouse as kinds, Small/Large roads, unlocks, a win, three taxes, demand nudges, radius coverage, hour as a rule, Construction on level-up, 8× speed, undo/redo, moving traffic pixels, a Select tool.
- Testing the window, camera, stamp bitmaps, or overlay drawing.

## Further Notes

- Vocabulary is `CONTEXT.md`. ADR-0012: the share is a catalog, not this spec.
- Tickets: `.scratch/construction-feel/issues/`. Frontier (no blockers): 01 Construction births, 02 Maintenance, 04 Sim speed, 05 HUD power and water percent. Implement with `/implement` in a fresh window, blockers-first.
