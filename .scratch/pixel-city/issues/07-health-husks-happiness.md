# 07: Health, husks, happiness

**What to build:** Each building has health. Struggling still produces; abandoned is a bottom band: a husk that occupies plots, produces nothing, and keeps its zone. Missing power or water, high tax, and unemployment (houses only) nibble health. Happiness on the HUD is the average of building health, not a fifth nibble. Husks can recover if the cause lifts; new growth cannot use those plots until the husk is gone or revived.

**Blocked by:** 04: Tax rate; 06: Power and water

**Status:** claimed

- [x] Every building has health from 0 to 1; struggling and abandoned are visible bands (stamp/color) without an overlay
- [x] Struggling houses and shops still count population and jobs; abandoned ones count zero
- [x] Abandoned is a bottom band (not only exactly 0); the zone stays; new growth skips those plots
- [x] Missing power or water nibbles grown-building health; high tax nibbles health; unemployment nibbles house health only
- [x] Facilities do not take unemployment nibbles; they can still lose health from other causes later
- [x] HUD shows happiness as the city-wide average of building health (empty city is not “collapsing”)
- [x] Health rises when causes lift; a husk can leave abandoned and produce again
- [x] Save/load keeps health
