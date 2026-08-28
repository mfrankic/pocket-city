---
status: superseded by ADR-0009
---

# Residential demand has a base

Residential demand is `base + jobs − population`. Commercial demand is `population − jobs`. The base exists so a new city at 0/0 can grow a few houses; we rejected a seed job building and a “free growth until N” special case. Without the base the city never starts. Every house has the same population; every shop has the same jobs. No levels.
