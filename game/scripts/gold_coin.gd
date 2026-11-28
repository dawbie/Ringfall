extends Area2D
## Collectible gold coin dropped by defeated enemies on the 2.5D floor.
## Pops into the air on spawn, bounces onto the ground, and is collected when Frodo walks near.

@export var value: int = 5
@export var pickup_radius: float = 20.0
@export var magnet_radius: float = 42.0
@export var gravity_z: float = 520.0

var height_z: float = 6.0
var velocity_z: float = 110.0
var scatter_velocity: Vector2 = Vector2.ZERO

var _pickup_delay: float = 0.25
var _bob_phase: float = 0.0
var _collected: bool = false
var _player: Player = null

@onready var visual: Node2D = $Visual
@onready var shadow: Polygon2D = $Shadow


func _ready() -> void:
	_bob_phase = randf() * TAU
	_player = get_tree().get_first_node_in_group("player") as Player


func setup_drop(drop_value: int, initial_vel: Vector2, initial_vz: float) -> void:
	value = drop_value
	scatter_velocity = initial_vel
	velocity_z = initial_vz
	height_z = 8.0


func _physics_process(delta: float) -> void:
	if _collected:
		return

	_pickup_delay = maxf(0.0, _pickup_delay - delta)
	_bob_phase += delta * 5.0

	if height_z > 0.0 or velocity_z > 0.0:
		velocity_z -= gravity_z * delta
		height_z += velocity_z * delta
		global_position += scatter_velocity * delta
		global_position.x = clampf(global_position.x, 18.0, 1782.0)
		global_position.y = clampf(global_position.y, 122.0, 240.0)
		if height_z <= 0.0:
			height_z = 0.0
			if absf(velocity_z) > 45.0:
				velocity_z = -velocity_z * 0.42
				scatter_velocity *= 0.45
				AudioManager.play_sfx(&"coin_drop", -6.0, 0.92, 1.12, 0.06)
			else:
				velocity_z = 0.0
				scatter_velocity = Vector2.ZERO

	var bob_y := sin(_bob_phase) * 1.5 if height_z <= 0.05 else 0.0
	visual.position.y = -height_z + bob_y
	var shadow_scale := clampf(1.0 - (height_z / 90.0), 0.5, 1.0)
	shadow.scale = Vector2(shadow_scale, shadow_scale)

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
		return

	if _player.is_dead or _pickup_delay > 0.0:
		return

	var dist := global_position.distance_to(_player.global_position)
	if dist <= magnet_radius and height_z <= 12.0:
		global_position = global_position.move_toward(_player.global_position, 130.0 * delta)

	if dist <= pickup_radius and absf(height_z - _player.height_z) <= 22.0:
		_collect()


func _collect() -> void:
	_collected = true
	GameState.add_gold(value)
	AudioManager.play_sfx(&"coin_pickup", -1.5, 0.96, 1.06, 0.04)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "position:y", visual.position.y - 12.0, 0.16)
	tween.tween_property(self, "modulate:a", 0.0, 0.16)
	tween.finished.connect(queue_free)
