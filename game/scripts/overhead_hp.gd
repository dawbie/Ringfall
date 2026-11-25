extends Node2D
## Compact pixel-style overhead health bar and numeric HP display.
## Attached outside BodyPivot so it never mirrors when facing flips.

@export var bar_width: float = 28.0
@export var bar_height: float = 4.0
@export var fill_color: Color = Color(0.24, 0.78, 0.38, 1.0)
@export var offset_y: float = -36.0

var _current_hp: int = 100
var _max_hp: int = 100
var _vertical_lift: float = 0.0


func set_health(current_hp: int, max_hp: int) -> void:
	_current_hp = clampi(current_hp, 0, maxi(1, max_hp))
	_max_hp = maxi(1, max_hp)
	queue_redraw()


func set_vertical_lift(height_z: float) -> void:
	_vertical_lift = height_z
	queue_redraw()


func _draw() -> void:
	var y_top := offset_y - _vertical_lift
	var x_left := -bar_width * 0.5
	var ratio := float(_current_hp) / float(_max_hp)

	# Dark pixel border & background
	draw_rect(Rect2(x_left - 1.0, y_top - 1.0, bar_width + 2.0, bar_height + 2.0), Color(0.05, 0.04, 0.07, 0.9))
	draw_rect(Rect2(x_left, y_top, bar_width, bar_height), Color(0.18, 0.14, 0.18, 0.95))

	if ratio > 0.0:
		var fill_w := maxf(1.0, bar_width * ratio)
		draw_rect(Rect2(x_left, y_top, fill_w, bar_height), fill_color)

	# Crisp numeric HP readout centered above the bar
	var font := ThemeDB.fallback_font
	if font != null:
		var text := "%d" % _current_hp
		var font_size := 8
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos := Vector2(-text_size.x * 0.5, y_top - 2.0)
		draw_string(font, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.04, 0.03, 0.06, 0.95))
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.95, 0.93, 0.9, 1.0))
