package hud

MAP_W :: 960
MAP_H :: 560
LEFT_W :: 220
INSPECT_W :: 280
KEYS_H :: 36
WIN_W :: LEFT_W + MAP_W + INSPECT_W
WIN_H :: MAP_H + KEYS_H

on_hud :: proc(mx, my: f32) -> bool {
	return mx < LEFT_W || mx >= f32(LEFT_W + MAP_W) || my >= f32(MAP_H)
}
