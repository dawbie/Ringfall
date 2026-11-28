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
<<<<<<< Updated upstream
=======
var _current_interactable: Interactable = null
var root_duration_remaining: float = 0.0
var _footstep_timer: float = 0.0
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
=======
	sanity_changed.emit(_last_emitted_sanity, max_sanity)
	ring_state_changed.emit(false, 0.0, ring_veil_cooldown)
	AudioManager.set_player_dead(false)
	AudioManager.set_shadow_veil_active(false)
	AudioManager.set_sanity_ratio(1.0)
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
	_update_invuln_flicker()
	_play_locomotion_animation()


=======
	_update_visual_effects()
	_update_footstep_audio(delta)
	_play_locomotion_animation()


func set_input_locked(locked: bool) -> void:
	input_locked = locked
	if locked:
		velocity = Vector2.ZERO
		_clear_interactable_highlight()


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	current_hp = mini(max_hp, current_hp + amount)
	health_changed.emit(current_hp, max_hp)
	_spawn_hit_spark(global_position + Vector2(0, -16), Color(0.45, 0.95, 0.55, 1.0))


func add_bonus_damage(amount: int) -> void:
	bonus_damage += amount


func restore_sanity(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_sanity = minf(float(max_sanity), current_sanity + amount)
	_emit_sanity_if_changed()


func drain_sanity(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_sanity = maxf(0.0, current_sanity - amount)
	_emit_sanity_if_changed()


func apply_root(duration: float) -> void:
	## Unieruchamia Froda przez podany czas (pułapka cienia od łucznika).
	## Czas nie sumuje się — bierzemy dłuższy z bieżącego i nowego.
	root_duration_remaining = maxf(root_duration_remaining, duration)
	AudioManager.play_sfx(&"snare_root", -1.5, 0.95, 1.05)
	# Fioletowy błysk sygnalizujący unieruchomienie
	_spawn_hit_spark(global_position + Vector2(0, -18), Color(0.78, 0.35, 0.95, 1.0))


func _emit_sanity_if_changed() -> void:
	var rounded := clampi(int(ceilf(current_sanity)), 0, max_sanity)
	if rounded != _last_emitted_sanity:
		_last_emitted_sanity = rounded
		sanity_changed.emit(rounded, max_sanity)
		AudioManager.set_sanity_ratio(current_sanity / float(maxi(1, max_sanity)))


>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
	play_hurt_animation()
=======
	AudioManager.play_sfx(&"player_hurt", 0.0, 0.94, 1.06)
	play_action_animation(&"hurt")
>>>>>>> Stashed changes


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
<<<<<<< Updated upstream
=======
	AudioManager.set_shadow_veil_active(false)
	AudioManager.set_player_dead(true)
	AudioManager.play_sfx(&"player_death", -1.0, 0.98, 1.02)
	ring_state_changed.emit(false, _ring_cooldown_timer, ring_veil_cooldown)
>>>>>>> Stashed changes
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
		AudioManager.play_sfx(&"jump", -3.0, 0.95, 1.08)
		if not _action_anim_locked:
			anim_player.play(&"jump")

	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0 and not _is_dashing:
		_start_dash()
		return

<<<<<<< Updated upstream
	if Input.is_action_just_pressed("attack") and _attack_cooldown_timer <= 0.0 and not _is_attacking and not _is_dashing:
		_start_attack()
=======
	if Input.is_action_just_pressed("attack"):
		if _is_dashing:
			_start_dash_attack()
		elif _attack_kind != AttackKind.NONE:
			# Buffer next combo attack if pressed near the end of current swing
			if _attack_timer <= _attack_duration * 0.55 and is_grounded():
				_buffered_attack = true
		else:
			_start_contextual_attack()


func _enter_shadow_veil() -> void:
	_ring_veil_timer = ring_veil_duration
	_ring_cooldown_timer = ring_veil_cooldown
	_zero_sanity_hp_tick = 0.0
	drain_sanity(ring_activation_sanity_cost)
	GameState.add_ring_corruption(1)
	AudioManager.set_shadow_veil_active(true)
	AudioManager.play_sfx(&"ring_enter", -1.0, 0.98, 1.02)
	_spawn_hit_spark(global_position + Vector2(0, -14), Color(1.0, 0.82, 0.35, 1.0))
	ring_state_changed.emit(true, _ring_veil_timer, ring_veil_duration)


func _exit_shadow_veil() -> void:
	_ring_veil_timer = 0.0
	_zero_sanity_hp_tick = 0.0
	AudioManager.set_shadow_veil_active(false)
	AudioManager.play_sfx(&"ring_exit", -2.5, 0.96, 1.04)
	ring_state_changed.emit(false, _ring_cooldown_timer, ring_veil_cooldown)
>>>>>>> Stashed changes


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

<<<<<<< Updated upstream
	play_action_animation(&"dash")


func _start_attack() -> void:
	_is_attacking = true
	_attack_timer = attack_duration
	_attack_cooldown_timer = attack_cooldown
=======
	var perfect_dodged := _check_perfect_dodge()
	if not perfect_dodged:
		AudioManager.play_sfx(&"dash", -2.5, 0.94, 1.08)
	_spawn_dash_afterimage(Color(0.62, 0.9, 1.0, 0.55))
	play_action_animation(&"dash")


func _check_perfect_dodge() -> bool:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.state == Enemy.State.DEAD:
			continue
		if absf(enemy.global_position.y - global_position.y) > 18.0:
			continue
		if absf(enemy.global_position.x - global_position.x) > 52.0:
			continue

		var threatening := (
			enemy.state == Enemy.State.ATTACK
			or (enemy.state == Enemy.State.WINDUP and enemy.get_windup_remaining() <= 0.24)
		)
		if threatening:
			_dash_cooldown_timer = 0.0
			_empowered_strike_bonus = maxi(_empowered_strike_bonus, perfect_dodge_bonus_damage)
			AudioManager.play_sfx(&"perfect_dodge", 0.5, 0.98, 1.04)
			_spawn_hit_spark(global_position + Vector2(0, -16), Color(0.65, 0.95, 1.0, 1.0))
			var cam := get_tree().get_first_node_in_group("main_camera")
			if cam != null and cam.has_method("trigger_hitstop"):
				cam.trigger_hitstop(0.055)
			return true
	return false


func _start_dash_attack() -> void:
	_is_dashing = false
	_combo_step = 0
	_buffered_attack = false
	_begin_attack(AttackKind.DASH_ATTACK)


func _start_contextual_attack() -> void:
	if not is_grounded():
		if Input.is_action_pressed("move_down"):
			_begin_attack(AttackKind.POGO_DOWN)
		else:
			_begin_attack(AttackKind.AIR_SLASH)
		return

	_combo_step = (_combo_step % 3) + 1
	var kind: AttackKind = AttackKind.COMBO_1
	if _combo_step == 2:
		kind = AttackKind.COMBO_2
	elif _combo_step == 3:
		kind = AttackKind.COMBO_3
	_begin_attack(kind)


func _begin_attack(kind: AttackKind) -> void:
	var spec: Dictionary = ATTACK_SPECS[kind]
	_attack_kind = kind
	_attack_duration = float(spec["duration"])
	_attack_timer = _attack_duration
>>>>>>> Stashed changes
	_attack_hit_targets.clear()
	slash_arc.visible = false
<<<<<<< Updated upstream
	play_action_animation(&"attack")
=======

	if kind == AttackKind.POGO_DOWN:
		_action_anim_locked = true
		anim_player.stop()
		visual_rig.rotation = 0.16
		visual_rig.scale = Vector2(0.95, 1.08)
		AudioManager.play_sfx(&"sword_pogo", -2.0, 0.95, 1.08)
	elif kind == AttackKind.COMBO_3 or kind == AttackKind.DASH_ATTACK:
		AudioManager.play_sfx(&"sword_swing_heavy", -1.5, 0.94, 1.04)
		play_action_animation(&"attack")
	else:
		AudioManager.play_sfx(&"sword_swing_light", -2.5, 0.93, 1.09)
		play_action_animation(&"attack")


func _finish_attack() -> void:
	var finished_kind := _attack_kind
	_cancel_attack()
	if finished_kind in [AttackKind.COMBO_1, AttackKind.COMBO_2]:
		_combo_window_timer = combo_reset_window
	elif finished_kind == AttackKind.COMBO_3:
		_combo_step = 0
		_combo_window_timer = 0.0

	if _buffered_attack and is_grounded() and not _is_dashing:
		_buffered_attack = false
		_start_contextual_attack()


func _cancel_attack() -> void:
	_attack_kind = AttackKind.NONE
	_attack_timer = 0.0
	_attack_lunge_velocity = Vector2.ZERO
	attack_hitbox.monitoring = false
	pogo_hitbox.monitoring = false
	slash_arc.visible = false
	sword_pivot.position = Vector2(4, -12)
	sword_pivot.rotation = 0.0
	if _action_anim_locked and anim_player.current_animation == &"attack":
		_action_anim_locked = false
	elif not anim_player.is_playing() and _action_anim_locked:
		_action_anim_locked = false
		visual_rig.rotation = 0.0
		visual_rig.scale = Vector2.ONE
>>>>>>> Stashed changes


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
<<<<<<< Updated upstream
			target.take_damage(attack_damage, Vector2(facing * attack_knockback, 0.0))
			_spawn_hit_spark((global_position + target.global_position) * 0.5 + Vector2(0, -14))
=======
			var kb_dir := float(facing)
			if is_pogo and absf(target.global_position.x - global_position.x) > 2.0:
				kb_dir = signf(target.global_position.x - global_position.x)
			var launch_z := float(spec.get("launch_z", 0.0))
			var is_heavy_hit := (
				_attack_kind == AttackKind.COMBO_3
				or _attack_kind == AttackKind.DASH_ATTACK
				or _empowered_strike_bonus > 0
			)
			var total_damage := int(spec["damage"]) + bonus_damage + _empowered_strike_bonus
			_empowered_strike_bonus = 0
			target.take_damage(total_damage, Vector2(kb_dir * float(spec["knockback"]), 0.0), launch_z)
			AudioManager.play_sfx(&"hit_heavy" if is_heavy_hit else &"hit_flesh", -1.0, 0.92, 1.08, 0.02)

			var spark_pos: Vector2 = (global_position + target.global_position) * 0.5 + Vector2(0, -14)
			var spark_color := Color(1.0, 0.9, 0.45, 1.0) if is_pogo else Color(1.0, 0.94, 0.72, 1.0)
			if is_pogo:
				spark_pos = global_position + Vector2(0, -height_z + 2.0)
				_trigger_pogo_bounce()

			_spawn_hit_spark(spark_pos, spark_color)
>>>>>>> Stashed changes
			var cam := get_tree().get_first_node_in_group("main_camera")
			if cam != null:
				if cam.has_method("shake"):
					cam.shake(2.4, 0.09)
				if cam.has_method("trigger_hitstop"):
					cam.trigger_hitstop(0.042)


<<<<<<< Updated upstream
func _spawn_hit_spark(world_pos: Vector2) -> void:
=======
func _trigger_pogo_bounce() -> void:
	if _pogo_bounced_this_swing:
		return
	_pogo_bounced_this_swing = true
	height_z = maxf(height_z, 8.0)
	velocity_z = pogo_bounce_force
	_dash_cooldown_timer = 0.0
	AudioManager.play_sfx(&"pogo_bounce", -1.0, 0.96, 1.06)


func _spawn_hit_spark(world_pos: Vector2, spark_color: Color) -> void:
>>>>>>> Stashed changes
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
		var was_airborne := height_z > 2.0
		velocity_z -= gravity_z * delta
		height_z += velocity_z * delta
		if height_z <= 0.0:
			height_z = 0.0
			velocity_z = 0.0
<<<<<<< Updated upstream
=======
			if was_airborne and not is_dead:
				AudioManager.play_sfx(&"land", -4.5, 0.92, 1.08)
			if _attack_kind == AttackKind.POGO_DOWN or _attack_kind == AttackKind.AIR_SLASH:
				_cancel_attack()


func _update_footstep_audio(delta: float) -> void:
	if (
		is_dead
		or input_locked
		or not is_grounded()
		or _is_dashing
		or _attack_kind != AttackKind.NONE
		or root_duration_remaining > 0.0
		or velocity.length_squared() <= 400.0
	):
		_footstep_timer = 0.05
		return

	_footstep_timer -= delta
	if _footstep_timer <= 0.0:
		_footstep_timer = 0.27
		AudioManager.play_sfx(&"footstep", -7.5, 0.88, 1.12, 0.14)


func _update_interactable_focus() -> void:
	var best: Interactable = null
	var best_dist := INF
	for area in interaction_sensor.get_overlapping_areas():
		var candidate := area as Interactable
		if candidate == null or not candidate.can_interact(self):
			continue
		var d := global_position.distance_squared_to(candidate.global_position)
		if d < best_dist:
			best_dist = d
			best = candidate

	if _current_interactable != best:
		if _current_interactable != null and is_instance_valid(_current_interactable):
			_current_interactable.set_highlighted(false)
		_current_interactable = best
		if _current_interactable != null:
			_current_interactable.set_highlighted(true)


func _clear_interactable_highlight() -> void:
	if _current_interactable != null and is_instance_valid(_current_interactable):
		_current_interactable.set_highlighted(false)
	_current_interactable = null


func _update_low_obstacle_collision() -> void:
	if height_z >= low_obstacle_clear_height:
		set_collision_mask_value(6, false)
	elif not foot_clearance.has_overlapping_bodies():
		set_collision_mask_value(6, true)


func _update_enemy_passthrough_collision() -> void:
	var can_phase := (
		_is_dashing
		or _attack_kind == AttackKind.DASH_ATTACK
		or is_in_shadow_veil()
		or height_z >= 18.0
	)
	if can_phase:
		set_collision_mask_value(3, false)
		set_collision_layer_value(2, false)
	elif not enemy_clearance.has_overlapping_bodies():
		set_collision_mask_value(3, true)
		set_collision_layer_value(2, true)
>>>>>>> Stashed changes


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
