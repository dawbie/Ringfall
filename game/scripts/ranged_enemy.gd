class_name RangedEnemy
extends CharacterBody2D
## 2.5D ranged enemy (Orc Trapper / Crossbowman).
## Maintains shooting distance, aligns depth, fires bolts and immobilizing shadow snares,
## and transforms into drifting smoke when Frodo enters the Shadow Veil.

signal died(enemy: RangedEnemy)
signal health_changed(current_hp: int, max_hp: int)

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectile.tscn")

enum State { IDLE, POSITION, CONFUSED, AIM, RECOVER, HURT, DEAD }

@export var max_hp: int = 80
@export var move_speed_x: float = 72.0
@export var move_speed_y: float = 58.0
@export var aggro_range: float = 380.0
@export var ideal_range_x: float = 155.0
@export var retreat_range_x: float = 72.0
@export var max_shoot_range_x: float = 250.0
@export var depth_tolerance: float = 10.0
@export var aim_duration: float = 0.52
@export var recover_duration: float = 0.85
@export var hurt_duration: float = 0.20
@export var gravity_z: float = 640.0
@export var max_consecutive_staggers: int = 2
@export var poise_duration: float = 1.4

var current_hp: int = max_hp
var state: State = State.IDLE
var facing: int = -1
var height_z: float = 0.0
var velocity_z: float = 0.0

var _state_timer: float = 0.0
var _walk_cycle: float = 0.0
var _smoke_cycle: float = 0.0
var _confused_dir: float = 1.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _target: Node2D = null
var _shot_counter: int = 0
var _next_shot_is_snare: bool = false
var _stagger_count: int = 0
var _stagger_reset_timer: float = 0.0
var _poise_timer: float = 0.0
var _hit_flash_timer: float = 0.0

@onready var body_pivot: Node2D = $BodyPivot
@onready var visual_rig: Node2D = $BodyPivot/VisualRig
@onready var shadow_smoke: Node2D = $BodyPivot/ShadowSmokeForm
@onready var crossbow_pivot: Node2D = $BodyPivot/VisualRig/CrossbowPivot
@onready var aim_line: Polygon2D = $BodyPivot/AimLine
@onready var telegraph_marker: Polygon2D = $BodyPivot/VisualRig/TelegraphMarker
@onready var hurtbox: Area2D = $Hurtbox
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var overhead_hp: Node2D = $OverheadHP
@onready var shadow: Polygon2D = $Shadow


func _ready() -> void:
	add_to_group("enemies")
	current_hp = max_hp
	aim_line.visible = false
	telegraph_marker.visible = false
	shadow_smoke.visible = false
	overhead_hp.set_health(current_hp, max_hp)
	_target = get_tree().get_first_node_in_group("player") as Node2D
	_update_facing(-1)


func _physics_process(delta: float) -> void:
	_update_vertical_motion(delta)
	_update_visual_height()
	_update_wraith_appearance(delta)

	if state == State.DEAD:
		return

	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Node2D
		if _target == null:
			return

	_state_timer = maxf(0.0, _state_timer - delta)
	_poise_timer = maxf(0.0, _poise_timer - delta)
	_hit_flash_timer = maxf(0.0, _hit_flash_timer - delta)
	if _stagger_reset_timer > 0.0:
		_stagger_reset_timer -= delta
		if _stagger_reset_timer <= 0.0:
			_stagger_count = 0

	match state:
		State.IDLE:
			_process_idle()
		State.POSITION:
			_process_position(delta)
		State.CONFUSED:
			_process_confused(delta)
		State.AIM:
			_process_aim()
		State.RECOVER:
			_process_recover()
		State.HURT:
			_process_hurt(delta)

	move_and_slide()
	_update_visuals()


func get_windup_remaining() -> float:
	return _state_timer if state == State.AIM else 99.0


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO, launch_z: float = 0.0) -> void:
	if state == State.DEAD:
		return

	current_hp = maxi(0, current_hp - amount)
	overhead_hp.set_health(current_hp, max_hp)
	health_changed.emit(current_hp, max_hp)
	_hit_flash_timer = 0.11

	if current_hp <= 0:
		aim_line.visible = false
		telegraph_marker.visible = false
		if launch_z > 0.0:
			height_z = maxf(height_z, 2.0)
			velocity_z = maxf(velocity_z, launch_z)
		_enter_dead()
		return

	var can_stagger := true
	if launch_z > 0.0:
		can_stagger = true
	elif _poise_timer > 0.0:
		can_stagger = false
	else:
		_stagger_count += 1
		_stagger_reset_timer = 1.0
		if _stagger_count > max_consecutive_staggers:
			_stagger_count = 0
			_poise_timer = poise_duration
			can_stagger = false

	if not can_stagger:
		if state == State.IDLE:
			state = State.POSITION
		if state in [State.POSITION, State.RECOVER] and knockback.length_squared() > 0.1:
			move_and_collide(knockback.normalized() * 3.0)
		return

	aim_line.visible = false
	telegraph_marker.visible = false
	if launch_z > 0.0:
		height_z = maxf(height_z, 2.0)
		velocity_z = maxf(velocity_z, launch_z)

	state = State.HURT
	_state_timer = hurt_duration
	_knockback_velocity = knockback


func _is_target_veiled() -> bool:
	return _target != null and is_instance_valid(_target) and _target.has_method("is_in_shadow_veil") and bool(_target.call("is_in_shadow_veil"))


func _process_idle() -> void:
	velocity = Vector2.ZERO
	if _is_target_veiled():
		return
	if global_position.distance_to(_target.global_position) <= aggro_range:
		state = State.POSITION


func _process_position(delta: float) -> void:
	if bool(_target.get("is_dead")):
		velocity = Vector2.ZERO
		state = State.IDLE
		return

	if _is_target_veiled():
		_enter_confused()
		return

	var dx := _target.global_position.x - global_position.x
	var dy := _target.global_position.y - global_position.y
	if absf(dx) > 4.0:
		_update_facing(1 if dx > 0.0 else -1)

	var abs_dx := absf(dx)
	if abs_dx >= retreat_range_x and abs_dx <= max_shoot_range_x and absf(dy) <= depth_tolerance:
		_enter_aim()
		return

	var dir_x := 0.0
	if abs_dx < retreat_range_x:
		# Back away from Frodo if he gets too close
		dir_x = -1.0 if dx >= 0.0 else 1.0
	elif abs_dx > ideal_range_x:
		dir_x = 1.0 if dx > 0.0 else -1.0

	var dir_y := 0.0
	if absf(dy) > 4.0:
		dir_y = signf(dy)

	# Dodge around arena walls if backed into a corner while retreating
	if abs_dx < retreat_range_x and test_move(global_transform, Vector2(dir_x * 12.0, 0.0)):
		dir_x = 0.0
		if absf(dy) <= depth_tolerance:
			_enter_aim()
			return

	velocity = Vector2(dir_x * move_speed_x, dir_y * move_speed_y)
	_walk_cycle += delta * 10.0


func _enter_confused() -> void:
	state = State.CONFUSED
	_state_timer = 0.9
	_confused_dir = -1.0 if facing > 0 else 1.0
	aim_line.visible = false
	telegraph_marker.visible = false


func _process_confused(delta: float) -> void:
	if not _is_target_veiled():
		state = State.POSITION if global_position.distance_to(_target.global_position) <= aggro_range else State.IDLE
		return

	if _state_timer <= 0.0:
		_state_timer = 1.1
		_confused_dir *= -1.0
		_update_facing(1 if _confused_dir > 0.0 else -1)

	velocity = Vector2(_confused_dir * 20.0, 0.0)
	_walk_cycle += delta * 4.0


func _enter_aim() -> void:
	state = State.AIM
	_state_timer = aim_duration
	velocity = Vector2.ZERO
	_shot_counter += 1
	_next_shot_is_snare = (_shot_counter % 2 == 0)

	var dx := _target.global_position.x - global_position.x
	if absf(dx) > 1.0:
		_update_facing(1 if dx > 0.0 else -1)

	aim_line.visible = true
	aim_line.color = Color(0.78, 0.34, 0.96, 0.55) if _next_shot_is_snare else Color(0.96, 0.32, 0.25, 0.5)
	telegraph_marker.visible = true
	telegraph_marker.color = Color(0.82, 0.38, 1.0, 1.0) if _next_shot_is_snare else Color(1.0, 0.72, 0.22, 1.0)


func _process_aim() -> void:
	velocity = Vector2.ZERO
	if _is_target_veiled():
		_enter_confused()
		return
	if _state_timer <= 0.0:
		_fire_projectile()


func _fire_projectile() -> void:
	aim_line.visible = false
	telegraph_marker.visible = false
	var proj := PROJECTILE_SCENE.instantiate() as Projectile
	if proj != null and get_parent() != null:
		proj.global_position = global_position + Vector2(facing * 12.0, 0.0)
		proj.setup(float(facing), _next_shot_is_snare)
		get_parent().add_child(proj)

	state = State.RECOVER
	_state_timer = recover_duration


func _process_recover() -> void:
	velocity = Vector2.ZERO
	if _state_timer <= 0.0:
		state = State.POSITION


func _process_hurt(delta: float) -> void:
	velocity = _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 420.0 * delta)
	if _state_timer <= 0.0 and height_z <= 0.0:
		_knockback_velocity = Vector2.ZERO
		state = State.POSITION


func _enter_dead() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	aim_line.visible = false
	telegraph_marker.visible = false
	hurtbox.set_deferred("monitorable", false)
	body_collision.set_deferred("disabled", true)
	died.emit(self)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual_rig, "rotation", -1.45, 0.3)
	tween.tween_property(visual_rig, "position", Vector2(-6, -3), 0.3)
	tween.tween_property(visual_rig, "modulate", Color(0.5, 0.45, 0.5, 0.0), 0.75).set_delay(0.35)
	tween.finished.connect(queue_free)


func _update_facing(new_facing: int) -> void:
	facing = new_facing
	body_pivot.scale.x = facing


func _update_vertical_motion(delta: float) -> void:
	if height_z > 0.0 or velocity_z > 0.0:
		velocity_z -= gravity_z * delta
		height_z += velocity_z * delta
		if height_z <= 0.0:
			height_z = 0.0
			velocity_z = 0.0


func _update_visual_height() -> void:
	body_pivot.position.y = -height_z
	overhead_hp.set_vertical_lift(height_z)
	var shadow_scale := clampf(1.0 - (height_z / 110.0), 0.45, 1.0)
	shadow.scale = Vector2(shadow_scale, shadow_scale)


func _update_wraith_appearance(delta: float) -> void:
	var veiled := _is_target_veiled() and state != State.DEAD
	visual_rig.visible = not veiled
	shadow_smoke.visible = veiled
	overhead_hp.visible = not veiled and state != State.DEAD
	if veiled:
		aim_line.visible = false
		_smoke_cycle += delta * 4.2
		var torso := shadow_smoke.get_node_or_null("SmokeTorso") as Polygon2D
		var head := shadow_smoke.get_node_or_null("SmokeHead") as Polygon2D
		if torso != null:
			torso.position = Vector2(sin(_smoke_cycle) * 1.2, cos(_smoke_cycle * 0.9) * 0.8)
		if head != null:
			head.position = Vector2(sin(_smoke_cycle + 1.0) * 1.4, -absf(cos(_smoke_cycle * 0.8)) * 1.5)


func _update_visuals() -> void:
	match state:
		State.IDLE:
			visual_rig.position = Vector2.ZERO
			visual_rig.rotation = 0.0
			visual_rig.modulate = Color.WHITE
			crossbow_pivot.rotation = 0.0
		State.POSITION, State.CONFUSED:
			visual_rig.position = Vector2(0.0, -absf(sin(_walk_cycle)) * 1.8)
			visual_rig.rotation = 0.06 if velocity.x * facing > 0.0 else -0.04
			visual_rig.modulate = Color.WHITE
			crossbow_pivot.rotation = 0.05
		State.AIM:
			var t := 1.0 - (_state_timer / maxf(aim_duration, 0.01))
			visual_rig.position = Vector2(-1.5 * t, 0.0)
			visual_rig.rotation = -0.08 * t
			visual_rig.modulate = Color(1.25, 0.95, 1.35, 1.0) if _next_shot_is_snare else Color(1.35, 1.0, 0.8, 1.0)
			crossbow_pivot.rotation = -0.05
		State.RECOVER:
			visual_rig.position = Vector2(-1.0, 0.0)
			visual_rig.rotation = -0.06
			visual_rig.modulate = Color.WHITE
			crossbow_pivot.rotation = -0.2
		State.HURT:
			visual_rig.position = Vector2(-3.0, -1.0)
			visual_rig.rotation = -0.25
			visual_rig.modulate = Color(2.0, 0.5, 0.5, 1.0)
			crossbow_pivot.rotation = -0.35

	if _hit_flash_timer > 0.0 and state != State.HURT:
		visual_rig.modulate = Color(1.9, 1.5, 1.3, 1.0)
