extends Node2D
## Draws the 2.5D dark-fantasy Borderland Ruins environment (1800 px wide):
## twilight sky, distant mountain silhouettes, crumbling battlements, torches, and stone lane.

const ARENA_WIDTH: int = 1800
const LANE_TOP: int = 112
const LANE_BOTTOM: int = 248
const SCREEN_HEIGHT: int = 270
const TILE_SIZE: int = 32


func _draw() -> void:
	# Twilight sky bands
	draw_rect(Rect2(0, 0, ARENA_WIDTH, 44), Color("#0d0b14"))
	draw_rect(Rect2(0, 44, ARENA_WIDTH, 36), Color("#15111e"))
	draw_rect(Rect2(0, 80, ARENA_WIDTH, LANE_TOP - 80), Color("#1b1626"))

	# Distant jagged mountain peaks
	for i in range(0, 10):
		var mx := i * 190
		var peak := PackedVector2Array([
			Vector2(mx - 20, LANE_TOP),
			Vector2(mx + 65, 34 + (i % 2) * 14),
			Vector2(mx + 150, LANE_TOP),
		])
		draw_colored_polygon(peak, Color("#120f1a"))

	# Ruined battlements and flickering torch niches
	var ruin_index := 0
	for x in range(0, ARENA_WIDTH, 112):
		draw_rect(Rect2(x, 52, 86, LANE_TOP - 52), Color("#1f1a29"))
		draw_rect(Rect2(x + 10, 36, 22, 16), Color("#1f1a29"))
		draw_rect(Rect2(x + 52, 42, 18, 10), Color("#1f1a29"))
		if ruin_index % 2 == 0:
			draw_rect(Rect2(x + 40, 74, 6, 10), Color("#2c2233"))
			draw_rect(Rect2(x + 41, 70, 4, 5), Color("#cf6a2a"))
			draw_rect(Rect2(x + 42, 68, 2, 3), Color("#f6c563"))
		ruin_index += 1

	# Zone divider arches (Courtyard & Gate approach)
	for arch_x in [740, 1240]:
		draw_rect(Rect2(arch_x, 22, 18, LANE_TOP - 22), Color("#282233"))
		draw_rect(Rect2(arch_x + 4, 22, 10, LANE_TOP - 22), Color("#322a40"))

	# Back wall rim separating horizon from walkable 2.5D lane
	draw_rect(Rect2(0, LANE_TOP - 9, ARENA_WIDTH, 9), Color("#2e273a"))
	draw_line(Vector2(0, LANE_TOP), Vector2(ARENA_WIDTH, LANE_TOP), Color("#4a3f59"), 1.0)

	# Walkable 2.5D ground lane
	draw_rect(Rect2(0, LANE_TOP, ARENA_WIDTH, LANE_BOTTOM - LANE_TOP), Color("#231f29"))
	# Subtle worn path down the middle of the lane
	draw_rect(Rect2(0, 150, ARENA_WIDTH, 60), Color("#27232e"))

	# Cobblestone grid and mossy cracks
	var row := 0
	for y in range(LANE_TOP, LANE_BOTTOM, 16):
		var offset := (row % 2) * 16
		draw_line(Vector2(0, y), Vector2(ARENA_WIDTH, y), Color("#2d2836"), 1.0)
		for x in range(offset, ARENA_WIDTH, TILE_SIZE):
			draw_line(Vector2(x, y), Vector2(x, min(y + 16, LANE_BOTTOM)), Color("#2b2633"), 1.0)
		row += 1

	# Moss tufts near the safe camp & ruins
	for mx in [60, 130, 210, 350, 490, 680, 860, 1120, 1340]:
		draw_rect(Rect2(mx, LANE_TOP + 2, 8, 3), Color("#2b3b2c"))

	# Foreground drop-off / bottom rim
	draw_line(Vector2(0, LANE_BOTTOM), Vector2(ARENA_WIDTH, LANE_BOTTOM), Color("#433852"), 1.0)
	draw_rect(Rect2(0, LANE_BOTTOM + 1, ARENA_WIDTH, SCREEN_HEIGHT - LANE_BOTTOM), Color("#0f0c14"))
