---
status: accepted
---

# A building occupies a rectangle of lots

The sim stays a 64×64 array of lots with terrain (grass, lake, forest, rock), not a pixel canvas and not city-block cells. A building occupies a 1×1 or 2×2 rectangle of plots; size is chosen at birth from land value and never grows. Stamps may be irregular pixels inside that rectangle. Grown kinds stay House, Shop, and Factory. We rejected free-form occupancy because it doubles the world, and “span only when a kind needs it” because high land value is allowed to be a larger house.
