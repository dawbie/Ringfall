class_name Enemy
extends CharacterBody2D
## 2.5D test enemy (dark orc) with simple belt-scroller AI:
## chases the player, aligns Y depth, telegraphs melee strikes, attacks, and takes damage.

signal died(enemy: Enemy)
signal health_changed(current_hp: int, max_hp: int)

const GOLD_COIN_SCENE: PackedScene = preload("res://scenes/gold_coin.tscn")

enum State { IDLE, CHASE, CONFUSED, WINDUP, ATTACK, RECOVER, HURT, DEAD }

@export var max_hp: int = 100
@export var move_speed_x: float = 68.0
@export var move_speed_y: float = 52.0
@export var aggro_range: float = 340.0
@export var preferred_offset_x: float = 24.0
@export var attack_range_x: float = 32.0
@export var depth_tolerance: float = 12.0
@export var windup_duration: float = 0.48
@export var attack_duration: float = 0.18
@export var recover_duration: float = 0.55
@export var hurt_duration: float = 0.22
@export var attack_damage: int = 20
@export var attack_knockback: float = 95.0
@export var gravity_z: float = 640.0
@export var is_elite: bool = false
@export var max_consecutive_staggers: int = 2
@export var poise_duration: float = 1.55

var current_hp: int = max_hp
var state: State = State.IDLE
var facing: int = -1
var height_z: float = 0.0
var velocity_z: float = 0.0
var _base_scale: float = 1.0

var _state_timer: float = 0.0
var _walk_cycle: float = 0.0
var _smoke_cycle: float = 0.0
var _confused_dir: float = 1.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _attack_hit_targets: Array[Node] = []
var _target: Node2D = null
var _detour_dir_y: float = 0.0
var _detour_timer: float = 0.0
var _stagger_count: int = 0
var _stagger_reset_timer: float = 0.0
var _poise_timer: float = 0.0
var _hit_flash_timer: float = 0.0

@onready var body_pivot: Node2D = $BodyPivot
@onready var visual_rig: Node2D = $BodyPivot/VisualRig
@onready var shadow_smoke: Node2D = $BodyPivot/ShadowSmokeForm
@onready var weapon_pivot: Node2D = $BodyPivot/VisualRig/WeaponPivot
@onready var telegraph_marker: Polygon2D = $BodyPivot/VisualRig/TelegraphMarker
@onready var attack_hitbox: Area2D = $BodyPivot/AttackHitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var overhead_hp: Node2D = $OverheadHP
@onready var shadow: Polygon2D = $Shadow


func _ready() -> void:
	add_to_group("enemies")
	current_hp = max_hp
	attack_hitbox.monitoring = false
	telegraph_marker.visible = false
	shadow_smoke.visible = false
	if is_elite:
		_base_scale = 1.24
		overhead_hp.offset_y = -48.0
		overhead_hp.fill_color = Color(0.95, 0.52, 0.18, 1.0)
		var armor := visual_rig.get_node_or_null("ArmorShoulder") as Polygon2D
		if armor != null:
			armor.color = Color(0.55, 0.22, 0.26, 1.0)
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
		State.CHASE:
			_process_chase(delta)
		State.CONFUSED:
			_process_confused(delta)
		State.WINDUP:
			_process_windup(delta)
		State.ATTACK:
			_process_attack()
		State.RECOVER:
			_process_recover()
		State.HURT:
			_process_hurt(delta)

	move_and_slide()
	_update_visuals(delta)


func get_windup_remaining() -> float:
	return _state_timer if state == State.WINDUP else 99.0


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO, launch_z: float = 0.0) -> void:
	if state == State.DEAD:
		return

	current_hp = maxi(0, current_hp - amount)
	overhead_hp.set_health(current_hp, max_hp)
	health_changed.emit(current_hp, max_hp)
	_hit_flash_timer = 0.11

	if current_hp <= 0:
		attack_hitbox.monitoring = false
		telegraph_marker.visible = false
		if launch_z > 0.0:
			height_z = maxf(height_z, 2.0)
			velocity_z = maxf(velocity_z, launch_z)
		_enter_dead()
		return

	var can_stagger := true
	if state == State.ATTACK:
		can_stagger = false
	elif is_elite and state == State.WINDUP:
		can_stagger = false
	elif launch_z > 0.0:
		can_stagger = true
	elif _poise_timer > 0.0:
		can_stagger = false
	else:
		_stagger_count += 1
		_stagger_reset_timer = 1.1
		if _stagger_count > max_consecutive_staggers:
			_stagger_count = 0
			_poise_timer = poise_duration
			can_stagger = false

	if not can_stagger:
		# Absorb stagger with poise so attack spamming cannot stunlock enemies infinitely
		if state == State.IDLE:
			state = State.CHASE
		if state in [State.CHASE, State.RECOVER] and knockback.length_squared() > 0.1:
			move_and_collide(knockback.normalized() * 3.0)
		return

	attack_hitbox.monitoring = false
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
		state = State.CHASE


func _process_chase(delta: float) -> void:
	var target_dead: bool = bool(_target.get("is_dead"))
	if target_dead:
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

	if absf(dx) <= attack_range_x and absf(dy) <= depth_tolerance:
		_enter_windup()
		return

	# Approach either left or right flank of the player on the same Y depth lane.
	var flank_sign := -1.0 if dx >= 0.0 else 1.0
	var desired_pos := _target.global_position + Vector2(flank_sign * preferred_offset_x, 0.0)
	var to_desired := desired_pos - global_position

	var dir_x := 0.0
	if absf(to_desired.x) > 4.0:
		dir_x = signf(to_desired.x)

	var dir_y := 0.0
	if absf(to_desired.y) > 3.0:
		dir_y = signf(to_desired.y)

	_detour_timer = maxf(0.0, _detour_timer - delta)
	var step_probe := Vector2(dir_x * move_speed_x, dir_y * move_speed_y).normalized() * 10.0
	if step_probe.length_squared() > 0.1 and test_move(global_transform, step_probe):
		if _detour_timer <= 0.0 or absf(_detour_dir_y) < 0.1:
			var up_clear := not test_move(global_transform, Vector2(0.0, -14.0))
			var down_clear := not test_move(global_transform, Vector2(0.0, 14.0))
			if up_clear and down_clear:
				_detour_dir_y = -1.0 if global_position.y > 180.0 else 1.0
			elif up_clear:
				_detour_dir_y = -1.0
			elif down_clear:
				_detour_dir_y = 1.0
			else:
				_detour_dir_y = 0.0
			_detour_timer = 0.45

		if absf(_detour_dir_y) > 0.1:
			dir_y = _detour_dir_y
			if test_move(global_transform, Vector2(dir_x * 10.0, 0.0)):
				dir_x = 0.0
		elif absf(dir_x) < 0.1:
			dir_x = 1.0 if global_position.x < _target.global_position.x else -1.0
			if absf(dir_x) < 0.1:
				dir_x = 1.0

	velocity = Vector2(dir_x * move_speed_x, dir_y * move_speed_y)
	_walk_cycle += delta * 10.0


func _enter_confused() -> void:
	state = State.CONFUSED
	_state_timer = 0.9
	_confused_dir = -1.0 if facing > 0 else 1.0
	telegraph_marker.visible = false
	attack_hitbox.monitoring = false


func _process_confused(delta: float) -> void:
	if not _is_target_veiled():
		if global_position.distance_to(_target.global_position) <= aggro_range:
			state = State.CHASE
		else:
			state = State.IDLE
		return

	if _state_timer <= 0.0:
		_state_timer = 1.1
		_confused_dir *= -1.0
		_update_facing(1 if _confused_dir > 0.0 else -1)

	velocity = Vector2(_confused_dir * 20.0, 0.0)
	_walk_cycle += delta * 4.0


func _enter_windup() -> void:
	state = State.WINDUP
	_state_timer = windup_duration
	velocity = Vector2.ZERO
	telegraph_marker.visible = true
	var dx := _target.global_position.x - global_position.x
	if absf(dx) > 1.0:
		_update_facing(1 if dx > 0.0 else -1)


func _process_windup(_delta: float) -> void:
	velocity = Vector2.ZERO
	if _is_target_veiled():
		_enter_confused()
		return
	if _state_timer <= 0.0:
		_enter_attack()


func _enter_attack() -> void:
	state = State.ATTACK
	_state_timer = attack_duration
	_attack_hit_targets.clear()
	telegraph_marker.visible = false
	velocity = Vector2(facing * 45.0, 0.0)
	attack_hitbox.monitoring = true


func _process_attack() -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 8.0)

	if attack_hitbox.monitoring:
		for area in attack_hitbox.get_overlapping_areas():
			var victim := area.get_parent() as Node2D
			if victim == null or victim == self or victim in _attack_hit_targets:
				continue
			if not victim.is_in_group("player"):
				continue
			if absf(victim.global_position.y - global_position.y) > depth_tolerance + 4.0:
				continue
			var victim_z := 0.0
			if "height_z" in victim:
				victim_z = float(victim.height_z)
			if victim_z > 18.0:
				continue

			_attack_hit_targets.append(victim)
			if victim.has_method("take_damage"):
				victim.take_damage(attack_damage, Vector2(facing * attack_knockback, 0.0))

	if _state_timer <= 0.0:
		attack_hitbox.monitoring = false
		state = State.RECOVER
		_state_timer = recover_duration


func _process_recover() -> void:
	velocity = Vector2.ZERO
	if _state_timer <= 0.0:
		state = State.CHASE


func _process_hurt(delta: float) -> void:
	velocity = _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 420.0 * delta)
	if _state_timer <= 0.0 and height_z <= 0.0:
		_knockback_velocity = Vector2.ZERO
		state = State.CHASE


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


func _enter_dead() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	attack_hitbox.monitoring = false
	hurtbox.set_deferred("monitorable", false)
	body_collision.set_deferred("disabled", true)
	GameState.register_enemy_kill()
	_spawn_gold_drops()
	died.emit(self)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual_rig, "rotation", -1.45, 0.3)
	tween.tween_property(visual_rig, "position", Vector2(-6, -3), 0.3)
	tween.tween_property(visual_rig, "modulate", Color(0.5, 0.45, 0.5, 0.0), 0.75).set_delay(0.35)
	tween.finished.connect(queue_free)


func _spawn_gold_drops() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var coin_count := 4 if is_elite else 2
	for i in range(coin_count):
		var coin := GOLD_COIN_SCENE.instantiate()
		if coin == null:
			continue
		coin.position = position + Vector2(randf_range(-6.0, 6.0), randf_range(-4.0, 4.0))
		parent_node.call_deferred("add_child", coin)
		var angle := randf_range(0.0, TAU)
		var vel := Vector2(cos(angle), sin(angle) * 0.55) * randf_range(35.0, 75.0)
		coin.call_deferred("setup_drop", 5, vel, randf_range(95.0, 145.0))


func _update_facing(new_facing: int) -> void:
	facing = new_facing
	body_pivot.scale = Vector2(facing * _base_scale, _base_scale)


func _update_wraith_appearance(delta: float) -> void:
	var veiled := _is_target_veiled() and state != State.DEAD
	visual_rig.visible = not veiled
	shadow_smoke.visible = veiled
	overhead_hp.visible = not veiled and state != State.DEAD

	if veiled:
		_smoke_cycle += delta * 4.2
		var torso := shadow_smoke.get_node_or_null("SmokeTorso") as Polygon2D
		var head := shadow_smoke.get_node_or_null("SmokeHead") as Polygon2D
		var drift_a := shadow_smoke.get_node_or_null("SmokeDriftA") as Polygon2D
		var drift_b := shadow_smoke.get_node_or_null("SmokeDriftB") as Polygon2D
		var leg_l := shadow_smoke.get_node_or_null("SmokeLegsLeft") as Polygon2D
		var leg_r := shadow_smoke.get_node_or_null("SmokeLegsRight") as Polygon2D
		if torso != null:
			torso.position = Vector2(sin(_smoke_cycle) * 1.2, cos(_smoke_cycle * 0.9) * 0.8)
			torso.scale = Vector2(1.0 + 0.06 * sin(_smoke_cycle * 1.3), 1.0 + 0.05 * cos(_smoke_cycle))
		if head != null:
			head.position = Vector2(sin(_smoke_cycle + 1.1) * 1.5, -absf(cos(_smoke_cycle * 0.8)) * 1.6)
			head.rotation = 0.06 * sin(_smoke_cycle * 0.9)
		if drift_a != null:
			drift_a.position = Vector2(-1.5 + sin(_smoke_cycle * 1.4) * 2.2, -1.5 - absf(sin(_smoke_cycle)) * 3.0)
			drift_a.modulate.a = 0.35 + 0.25 * sin(_smoke_cycle * 1.2)
		if drift_b != null:
			drift_b.position = Vector2(1.5 + cos(_smoke_cycle * 1.3) * 2.2, -1.0 - absf(cos(_smoke_cycle * 0.9)) * 3.2)
			drift_b.modulate.a = 0.32 + 0.25 * cos(_smoke_cycle * 1.1)
		if leg_l != null:
			leg_l.position = Vector2(sin(_smoke_cycle + 0.5) * 0.9, 0.0)
		if leg_r != null:
			leg_r.position = Vector2(cos(_smoke_cycle + 0.5) * 0.9, 0.0)


func _update_visuals(_delta: float) -> void:
	match state:
		State.IDLE:
			visual_rig.position = Vector2.ZERO
			visual_rig.rotation = 0.0
			visual_rig.modulate = Color.WHITE
			weapon_pivot.rotation = 0.1
		State.CHASE, State.CONFUSED:
			visual_rig.position = Vector2(0.0, -absf(sin(_walk_cycle)) * 2.0)
			visual_rig.rotation = 0.07 if state == State.CHASE else 0.0
			visual_rig.modulate = Color.WHITE
			weapon_pivot.rotation = -0.2 + sin(_walk_cycle) * 0.12
		State.WINDUP:
			var t := 1.0 - (_state_timer / maxf(windup_duration, 0.01))
			visual_rig.position = Vector2(-2.0 * t, 0.0)
			visual_rig.rotation = -0.18 * t
			visual_rig.modulate = Color(1.45, 0.9, 0.55, 1.0)
			weapon_pivot.rotation = lerpf(-0.2, -1.75, t)
		State.ATTACK:
			visual_rig.position = Vector2(3.0, 0.0)
			visual_rig.rotation = 0.2
			visual_rig.modulate = Color.WHITE
			weapon_pivot.rotation = 1.2
		State.RECOVER:
			visual_rig.position = Vector2.ZERO
			visual_rig.rotation = 0.06
			visual_rig.modulate = Color.WHITE
			weapon_pivot.rotation = 0.45
		State.HURT:
			visual_rig.position = Vector2(-3.0, -1.0)
			visual_rig.rotation = -0.25
			visual_rig.modulate = Color(2.0, 0.5, 0.5, 1.0)
			weapon_pivot.rotation = -0.4

	if _hit_flash_timer > 0.0 and state != State.HURT:
		visual_rig.modulate = Color(1.9, 1.5, 1.3, 1.0)
