# 12: Month, graphs, outage

**What to build:** Time has a month (a span of ticks). The HUD shows a clock whose hour is not a rule. Graphs sample population, jobs, money, and happiness each month. Each month has a small chance that Stations supply no power for that month.

**Blocked by:** 06: Power and water; 07: Health, husks, happiness

**Status:** ready-for-agent

- [ ] A month is N ticks; income and health still change every tick
- [ ] HUD shows year/month/day (or equivalent) derived from ticks; hour does not change the sim
- [ ] Graphs show at least population, jobs, money, and happiness by month
- [ ] Each month, a small chance of an outage: Stations supply 0 power for that month; taps fail if Towers lose power
- [ ] After the outage month, Stations supply again without the player restamping
- [ ] Save/load keeps tick/month and whether this month is an outage
