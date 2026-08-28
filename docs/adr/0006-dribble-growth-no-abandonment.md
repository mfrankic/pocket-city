---
status: superseded by ADR-0010
---

# Growth dribbles; buildings do not rot

Each running tick develops at most one house and one shop, picked at random from eligible plots (zoned, empty, cardinal road access, that demand positive). We rejected developing every eligible plot in one tick (the city flashes into existence) and a per-plot chance (hides the demand rule). Negative demand only blocks new growth. Buildings do not abandon.
