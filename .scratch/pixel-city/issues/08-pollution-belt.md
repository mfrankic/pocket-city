# 08: Pollution belt

**What to build:** Factories emit pollution that spreads to cardinal lots and decays. Roads and lakes hold it. A house reads the worst plot in its footprint and loses health from local pollution. An overlay shows the belt.

**Blocked by:** 03: Industrial, factories, three demands; 07: Health, husks, happiness

**Status:** ready-for-agent

- [ ] Factory plots emit pollution each tick; it spreads to cardinal neighbors and decays
- [ ] Roads and lakes hold pollution (a one-lot moat does not hide smoke)
- [ ] A house’s pollution nibble uses the worst plot in its footprint
- [ ] Shops and factories are not nibbled by pollution
- [ ] The player can toggle a pollution overlay
- [ ] After load, the belt matches (stored or recomputed consistently)
