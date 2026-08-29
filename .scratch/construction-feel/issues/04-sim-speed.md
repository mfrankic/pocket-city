# 04: Sim speed

**What to build:** The player can run the sim at 1×, 2×, or 4×. 1× matches today’s tick rate. Pause still stops ticks at any speed.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] The player can set 1×, 2×, and 4×
- [x] 1× matches the current tick rate
- [x] 2× runs twice as many ticks per second as 1×; 4× four times
- [x] Pause stops ticks at any speed
- [x] HUD shows the current speed

## Answer

Speed is window-only. `-`/`=` (and keypad) step 1× → 2× → 4×. 1× keeps `TICK_DT`; 2× and 4× multiply frame time into the accumulator so more `city.tick` calls happen per second. Pause still skips the accumulator at any speed. The HUD prints the current multiplier next to PAUSED/RUNNING.
