---
status: superseded by ADR-0007
---

# Lot is the plot

The world is a grid of lots: one square, at most one building, shown as a colored rectangle (later a tiny stamp). We rejected city-block cells (one square = hundreds of people and many buildings) because that hides the pixel-object look, and free-form pixel blobs because the simulation would no longer be a 2D array. Multi-lot buildings are out until a building actually needs to span lots.
