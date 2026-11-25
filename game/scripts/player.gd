class_name Player
extends CharacterBody2D
## 2.5D belt-scroller player controller for Frodo.
## Supports ground-plane movement, simulated height_z jump, melee slash with depth check,
## directional dash with i-frames, knockback, and 100 HP overhead display.

signal health_changed(current_hp: int, max_hp: int)
signal died

@export var max_hp: int = 100
@export var move_speed_x: float = 125.0
@export var move_speed_y: float = 88.0
@export var jump_force: float = 220.0
@export var gravity_z: float = 700.0

@export var attack_damage: int = 20
@export var attack_knockback: float = 125.0
@export var attack_depth_tolerance: float = 16.0
@export var attack_duration: float = 0.24
@export var attack_cooldown: float = 0.28

@export var dash_speed: float = 280.0
@export var dash_duration: float = 0.20
@export var dash_cooldown: float = 0.36

@export var post_hit_invuln_duration: float = 0.55

var current_hp: int = max_hp
var height_z: float = 0.0
var velocity_z: float = 0.0
var facing: int = 1
var is_dead: bool = false

var _action_anim_locked: bool = false
var _is_attacking: bool = false
var _attack_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0
var _attack_hit_targets: Array[Node] = []

var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT

var _invuln_timer: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO

@onready var body_pivot: Node2D = $BodyPivot
@onready var visual_rig: Node2D = $BodyPivot/VisualRig
@onready var shadow: Polygon2D = $Shadow
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var attack_hitbox: Area2D = $BodyPivot/AttackHitbox
@onready var slash_arc: Polygon2D = $BodyPivot/SlashArc


func _ready() -> void:
	add_to_group("player")
	current_hp = max_hp
	attack_hitbox.monitoring = false
	slash_arc.visible = false
	anim_player.animation_finished.connect(_on_animation_finished)
	health_changed.emit(current_hp, max_hp)
	_update_visual_height()
	_play_locomotion_animation()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_update_timers(delta)
	_handle_action_inputs()
	_update_movement(delta)
	_update_attack_active_frames()
	_update_vertical_motion(delta)
	move_and_slide()
	_update_visual_height()
	_update_invuln_flicker()
	_play_locomotion_animation()


func is_grounded() -> bool:
	return height_z <= 0.0 and velocity_z <= 0.0


func is_invincible() -> bool:
	return _is_dashing or _invuln_timer > 0.0 or is_dead


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_invincible():
		return

	current_hp = maxi(0, current_hp - amount)
	health_changed.emit(current_hp, max_hp)

	# Cancel active swing on hit
	_is_attacking = false
	attack_hitbox.monitoring = false
	slash_arc.visible = false

	_knockback_velocity = knockback
	_invuln_timer = post_hit_invuln_duration

	var cam := get_tree().get_first_node_in_group("main_camera")
	if cam != null and cam.has_method("shake"):
		cam.shake(3.2, 0.14)

	if current_hp <= 0:
		play_dead_animation()
		died.emit()
		return

	play_hurt_animation()


func play_action_animation(anim_name: StringName) -> void:
	if is_dead:
		return
	_action_anim_locked = true
	anim_player.play(anim_name)
	anim_player.seek(0.0, true)


func play_hurt_animation() -> void:
	play_action_animation(&"hurt")


func play_dead_animation() -> void:
	is_dead = true
	_is_attacking = false
	_is_dashing = false
	_action_anim_locked = true
	attack_hitbox.monitoring = false
	slash_arc.visible = false
	visual_rig.visible = true
	velocity = Vector2.ZERO
	anim_player.play(&"dead")


func _update_timers(delta: float) -> void:
	_attack_cooldown_timer = maxf(0.0, _attack_cooldown_timer - delta)
	_dash_cooldown_timer = maxf(0.0, _dash_cooldown_timer - delta)
	_invuln_timer = maxf(0.0, _invuln_timer - delta)

	if _is_attacking:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_is_attacking = false
			attack_hitbox.monitoring = false
			slash_arc.visible = false

	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false


func _handle_action_inputs() -> void:
	if Input.is_action_just_pressed("jump") and is_grounded() and not _is_dashing:
		velocity_z = jump_force
		if not _action_anim_locked:
			anim_player.play(&"jump")

	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0 and not _is_dashing:
		_start_dash()
		return

	if Input.is_action_just_pressed("attack") and _attack_cooldown_timer <= 0.0 and not _is_attacking and not _is_dashing:
		_start_attack()


func _start_dash() -> void:
	_is_dashing = true
	_is_attacking = false
	attack_hitbox.monitoring = false
	slash_arc.visible = false
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown

	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vec.length_squared() > 0.04:
		# Scale Y slightly so diagonal dashes feel natural on the 2.5D plane
		_dash_dir = Vector2(input_vec.x, input_vec.y * 0.78).normalized()
		if absf(input_vec.x) > 0.05:
			facing = 1 if input_vec.x > 0.0 else -1
			body_pivot.scale.x = facing
	else:
		_dash_dir = Vector2(facing, 0.0)

	play_action_animation(&"dash")


func _start_attack() -> void:
	_is_attacking = true
	_attack_timer = attack_duration
	_attack_cooldown_timer = attack_cooldown
	_attack_hit_targets.clear()
	slash_arc.visible = false
	play_action_animation(&"attack")


func _update_movement(delta: float) -> void:
	if _is_dashing:
		velocity = _dash_dir * dash_speed
		return

	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed_mult := 0.35 if (_is_attacking and is_grounded()) else 1.0
	velocity.x = input_vec.x * move_speed_x * speed_mult + _knockback_velocity.x
	velocity.y = input_vec.y * move_speed_y * speed_mult + _knockback_velocity.y

	if not _is_attacking:
		if input_vec.x > 0.05:
			facing = 1
		elif input_vec.x < -0.05:
			facing = -1
		body_pivot.scale.x = facing

	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 480.0 * delta)


func _update_attack_active_frames() -> void:
	if not _is_attacking:
		return

	var elapsed := attack_duration - _attack_timer
	var in_active_window := elapsed >= 0.04 and elapsed <= 0.16
	attack_hitbox.monitoring = in_active_window
	slash_arc.visible = elapsed >= 0.05 and elapsed <= 0.14

	if not in_active_window:
		return

	for area in attack_hitbox.get_overlapping_areas():
		var target := area.get_parent()
		if target == null or target == self or target in _attack_hit_targets:
			continue
		if not target.is_in_group("enemies"):
			continue
		if absf(target.global_position.y - global_position.y) > attack_depth_tolerance:
			continue
		if height_z > 28.0:
			continue

		_attack_hit_targets.append(target)
		if target.has_method("take_damage"):
			target.take_damage(attack_damage, Vector2(facing * attack_knockback, 0.0))
			_spawn_hit_spark((global_position + target.global_position) * 0.5 + Vector2(0, -14))
			var cam := get_tree().get_first_node_in_group("main_camera")
			if cam != null:
				if cam.has_method("shake"):
					cam.shake(2.4, 0.09)
				if cam.has_method("trigger_hitstop"):
					cam.trigger_hitstop(0.042)


func _spawn_hit_spark(world_pos: Vector2) -> void:
	var spark := Polygon2D.new()
	spark.polygon = PackedVector2Array([-6, 0, -2, -2, 0, -6, 2, -2, 6, 0, 2, 2, 0, 6, -2, 2])
	spark.color = Color(1.0, 0.94, 0.72, 1.0)
	spark.global_position = world_pos
	spark.z_index = 20
	get_parent().add_child(spark)

	var tween := spark.create_tween()
	tween.set_parallel(true)
	tween.tween_property(spark, "scale", Vector2(1.4, 1.4), 0.12)
	tween.tween_property(spark, "modulate:a", 0.0, 0.12)
	tween.finished.connect(spark.queue_free)


func _update_vertical_motion(delta: float) -> void:
	if height_z > 0.0 or velocity_z > 0.0:
		velocity_z -= gravity_z * delta
		height_z += velocity_z * delta
		if height_z <= 0.0:
			height_z = 0.0
			velocity_z = 0.0


func _update_visual_height() -> void:
	body_pivot.position.y = -height_z
	var shadow_scale := clampf(1.0 - (height_z / 110.0), 0.45, 1.0)
	shadow.scale = Vector2(shadow_scale, shadow_scale)


func _update_invuln_flicker() -> void:
	if _invuln_timer > 0.0 and not _is_dashing:
		visual_rig.visible = int(_invuln_timer * 24.0) % 2 == 0
	else:
		visual_rig.visible = true


func _play_locomotion_animation() -> void:
	if _action_anim_locked or is_dead:
		return

	var target_anim: StringName = &"idle"
	if not is_grounded():
		target_anim = &"jump"
	elif velocity.length_squared() > 25.0:
		target_anim = &"run"

	if anim_player.current_animation != target_anim:
		anim_player.play(target_anim)


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name in [&"attack", &"dash", &"hurt"]:
		_action_anim_locked = false
		_play_locomotion_animation()
