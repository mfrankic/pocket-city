# 06: Irregular stamps

**What to build:** Buildings draw as irregular pixels inside their occupancy rectangle, including a Construction pattern. A 2×2 stamp fills that rectangle. Struggling and abandoned stay readable in the default view without an overlay.

**Blocked by:** 01: Construction births

**Status:** resolved

- [x] A finished house, shop, factory, and each facility uses a pixel stamp inside its rectangle, not a solid fill alone
- [x] Construction has a distinct stamp from a finished building of that kind
- [x] A 2×2 building’s stamp fills that rectangle
- [x] Struggling and abandoned stay readable without an overlay
- [x] The sim still does not store pixel masks

## Answer

Window-only 16×16 templates in `main.odin` draw inside the occupancy rectangle (scaled to 2×2). Construction uses a scaffold pattern; struggling dims the finished stamp; abandoned is a gray husk. The city still has no pixel masks.
