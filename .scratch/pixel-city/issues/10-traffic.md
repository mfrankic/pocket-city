# 10: Traffic

**What to build:** Each connected road component has traffic equal to grown buildings on that component divided by its road lots. High load nibbles health of grown buildings that access that component. An overlay colors the roads.

**Blocked by:** 07: Health, husks, happiness

**Status:** ready-for-agent

- [ ] Traffic is per connected road component: grown buildings ÷ road lots (no trips, no cars)
- [ ] High load nibbles health of grown buildings whose access is that component
- [ ] Painting more roads on the same component can relieve the nibble
- [ ] The player can toggle a traffic overlay on roads
- [ ] Facilities do not count as grown buildings in the load
