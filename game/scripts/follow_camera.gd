extends Camera2D
## Smoothly follows the player horizontally across the 2.5D corridor
## while supporting screen shake and brief hitstop feedback.

@export var follow_speed: float = 8.0
@export var look_ahead_x: float = 28.0

var _target: Node2D = null
var _shake_intensity: float = 0.0
var _shake_timer: float = 0.0
var _hitstop_timer: float = 0.0


func _ready() -> void:
	add_to_group("main_camera")
	_target = get_tree().get_first_node_in_group("player") as Node2D
	if _target != null:
		global_position.x = _target.global_position.x + look_ahead_x
	global_position.y = 135.0


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func shake(intensity: float = 3.0, duration: float = 0.12) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)
	_shake_timer = maxf(_shake_timer, duration)


func trigger_hitstop(duration: float = 0.04) -> void:
	_hitstop_timer = maxf(_hitstop_timer, duration)
	Engine.time_scale = 0.05


func _process(delta: float) -> void:
	var raw_delta := delta / maxf(Engine.time_scale, 0.001)

	if _hitstop_timer > 0.0:
		_hitstop_timer -= raw_delta
		if _hitstop_timer <= 0.0:
			Engine.time_scale = 1.0

	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Node2D
	else:
		var facing_offset := 0.0
		if "facing" in _target:
			facing_offset = float(_target.facing) * look_ahead_x
		var desired_x := _target.global_position.x + facing_offset
		global_position.x = lerpf(global_position.x, desired_x, 1.0 - exp(-follow_speed * raw_delta))
		global_position.y = 135.0

	if _shake_timer > 0.0:
		_shake_timer -= raw_delta
		offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		if _shake_timer <= 0.0:
			_shake_intensity = 0.0
			offset = Vector2.ZERO
	else:
		offset = Vector2.ZERO
