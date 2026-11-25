extends Node2D
## Draws procedural dark-fantasy placeholder floor tiles and background silhouettes
## for the 2.5D test corridor so depth and horizontal movement read clearly.

const ARENA_WIDTH: int = 1200
const LANE_TOP: int = 112
const LANE_BOTTOM: int = 248
const SCREEN_HEIGHT: int = 270
const TILE_SIZE: int = 32


func _draw() -> void:
	# Sky / distant dark horizon
	draw_rect(Rect2(0, 0, ARENA_WIDTH, LANE_TOP), Color("#131018"))

	# Distant ruined wall silhouettes along the horizon
	for x in range(0, ARENA_WIDTH, 96):
		draw_rect(Rect2(x, 42, 72, LANE_TOP - 42), Color("#1c1724"))
		draw_rect(Rect2(x + 12, 26, 20, 16), Color("#1c1724"))
		draw_rect(Rect2(x + 44, 34, 16, 8), Color("#1c1724"))
		# Dim torch / ember accent on every second ruin
		if (x / 96) % 2 == 0:
			draw_rect(Rect2(x + 34, 72, 4, 6), Color("#b85d28"))

	# Back wall rim separating horizon from walkable 2.5D lane
	draw_rect(Rect2(0, LANE_TOP - 8, ARENA_WIDTH, 8), Color("#2c2536"))
	draw_line(Vector2(0, LANE_TOP), Vector2(ARENA_WIDTH, LANE_TOP), Color("#443a52"), 1.0)

	# Walkable 2.5D ground lane
	draw_rect(Rect2(0, LANE_TOP, ARENA_WIDTH, LANE_BOTTOM - LANE_TOP), Color("#242029"))

	# Subtle cobblestone / grid rows to make X and Y depth easy to judge
	var row := 0
	for y in range(LANE_TOP, LANE_BOTTOM, 16):
		var offset := (row % 2) * 16
		draw_line(Vector2(0, y), Vector2(ARENA_WIDTH, y), Color("#2d2834"), 1.0)
		for x in range(offset, ARENA_WIDTH, TILE_SIZE):
			draw_line(Vector2(x, y), Vector2(x, min(y + 16, LANE_BOTTOM)), Color("#2b2631"), 1.0)
		row += 1

	# Foreground drop-off / bottom rim
	draw_line(Vector2(0, LANE_BOTTOM), Vector2(ARENA_WIDTH, LANE_BOTTOM), Color("#3f354b"), 1.0)
	draw_rect(Rect2(0, LANE_BOTTOM + 1, ARENA_WIDTH, SCREEN_HEIGHT - LANE_BOTTOM), Color("#100d14"))
