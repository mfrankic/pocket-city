# 13: Fire and firehouse

**What to build:** Fire is per-plot intensity, not an agent. Each month it may linger and, with low chance, spread to a cardinal plot that is not road, lake, or rock. A building on intensity above 0 takes a health nibble. Each month a small chance ignites a random plot that has a grown building and no Firehouse coverage. Firehouse coverage decays intensity and blocks ignition. Overlay shows fire. Outage and fire may coincide.

**Blocked by:** 05: Stamp seven facilities; 07: Health, husks, happiness; 12: Month, graphs, outage

**Status:** ready-for-agent

- [ ] Fire is a per-plot intensity 0–1, not a moving entity
- [ ] Each month, intensity lingers; with low chance it spreads to a cardinal plot except road, lake, or rock
- [ ] A building on a plot with intensity > 0 takes a health nibble (not instant zero)
- [ ] Each month, a small chance ignites one random plot that has a grown building and no Firehouse coverage
- [ ] Firehouse coverage (square, needs power) decays intensity and blocks new ignition
- [ ] Intensity 0 means out; the player can toggle a fire overlay
- [ ] Fire and an outage may happen in the same month
- [ ] Save/load keeps fire intensity
