# 03: Industrial, factories, three demands

**What to build:** The player paints industrial. Factories dribble in like houses and shops. The HUD shows three demand numbers from the freight loop: residential is base plus all jobs minus population; commercial is population minus shop jobs; industrial is shop jobs minus factory jobs.

**Blocked by:** 02: Buildings are records

**Status:** claimed

- [x] The player can paint industrial on a plot for money; cannot zone a road; same-zone paint spends nothing
- [x] Each running tick grows at most one factory when industrial demand is positive, on an empty industrial plot with cardinal road access
- [x] A factory provides jobs, not population; HUD shows population, jobs, and R/C/I demand
- [x] Residential demand is base + (shop jobs + factory jobs) − population
- [x] Commercial demand is population − shop jobs (not all jobs)
- [x] Industrial demand is shop jobs − factory jobs
- [x] Factories are distinct on the map (color/stamp); save/load keeps industrial zones and factories
