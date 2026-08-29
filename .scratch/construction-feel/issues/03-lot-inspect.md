# 03: Lot inspect

**What to build:** The lot under the cursor shows terrain, road or plot, zone, building kind, Construction remaining ticks when unfinished, level and health when finished, and power, water, pollution, land value, traffic, crime, fire, and education. Left click still paints. Off-map or HUD shows no fake lot.

**Blocked by:** 01: Construction births

**Status:** resolved

- [x] Moving the cursor over a lot updates inspect without painting
- [x] Inspect shows terrain, road or plot, zone, and building kind
- [x] Inspect shows Construction remaining ticks when unfinished, and level and health when finished
- [x] Inspect shows power, water, pollution, land value, traffic, crime, fire, and education on that lot
- [x] Cursor on the HUD or off the map does not show a lying lot
- [x] Left click still paints with the current tool

## Answer

The window maps the cursor to a lot (`hover_lot`) and draws inspect on the HUD from existing city getters. Hover does not paint. Cursor on the HUD or off the map shows no lot. Left click still paints. When finished, Inspect names Abandoned or Struggling if that band applies; it does not print the Health number.
