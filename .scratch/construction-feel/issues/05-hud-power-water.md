# 05: HUD power and water percent

**What to build:** The HUD shows power percent and water percent: occupied plots with supply over occupied plots. An empty city reads full. An outage drops the power percent. Existing HUD numbers stay.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] HUD shows power percent and water percent
- [x] Percents are occupied plots with power (or water) over occupied plots
- [x] A city with no buildings shows both percents as full
- [x] An outage drops the power percent
- [x] Money, population, jobs, demands, tax, happiness, and clock remain on the HUD

## Answer

City getters `city_power_percent` and `city_water_percent` are the fraction of occupied plots (lots with a building) that are powered or watered. No buildings → 1. The HUD prints them as `pwr`/`wat` next to happiness. An outage zeroes power on occupied plots, so the power percent drops.
