class_name Interactable
extends Area2D
## Base class for 2.5D world interactables (NPCs, campfires, shrines, exits).
## Displays a clean floating prompt when targeted by the player.

signal interacted(player: Player)

@export var prompt_text: String = "[Shift] Interakcja"
@export var one_shot: bool = false
@export var depth_tolerance: float = 34.0

var _used: bool = false
var _highlighted: bool = false
var _prompt_label: Label = null


func _ready() -> void:
	collision_layer = 64
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("interactables")
	_create_prompt_label()


func can_interact(player: Player) -> bool:
	if _used and one_shot:
		return false
	if player == null or player.is_dead:
		return false
	return absf(player.global_position.y - global_position.y) <= depth_tolerance


func set_highlighted(active: bool) -> void:
	_highlighted = active
	if _prompt_label != null:
		_prompt_label.visible = active and not (_used and one_shot)
		_prompt_label.text = prompt_text


func interact(player: Player) -> void:
	if not can_interact(player):
		return
	if one_shot:
		_used = true
		set_highlighted(false)
	interacted.emit(player)
	_on_interacted(player)


func _on_interacted(_player: Player) -> void:
	pass


func _create_prompt_label() -> void:
	_prompt_label = Label.new()
	_prompt_label.visible = false
	_prompt_label.position = Vector2(-60, -48)
	_prompt_label.size = Vector2(120, 14)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 8)
	_prompt_label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.58, 1.0))
	_prompt_label.add_theme_color_override("font_shadow_color", Color(0.04, 0.03, 0.06, 1.0))
	_prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	_prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	_prompt_label.z_index = 25
	add_child(_prompt_label)
