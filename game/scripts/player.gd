class_name Player
extends CharacterBody2D
## 2.5D belt-scroller player controller for Frodo.
## Supports 3-hit ground combo, dash-through juggle, air slash, down-air pogo,
## directional dash with perfect-dodge bonus, and Ring Shadow Veil (C) with hidden corruption.

signal health_changed(current_hp: int, max_hp: int)
signal sanity_changed(current_sanity: int, max_sanity: int)
signal ring_state_changed(is_active: bool, cooldown_remaining: float, cooldown_total: float)
signal died

enum AttackKind { NONE, COMBO_1, COMBO_2, COMBO_3, DASH_ATTACK, AIR_SLASH, POGO_DOWN }

const ATTACK_SPECS: Dictionary = {
	AttackKind.COMBO_1: {
		"damage": 18,
		"knockback": 85.0,
		"duration": 0.20,
		"active_start": 0.03,
		"active_end": 0.13,
		"lunge": 40.0,
		"depth_tol": 16.0,
		"hitstop": 0.035,
		"shake": 1.8,
		"arc_color": Color(0.84, 0.94, 1.0, 0.78),
		"arc_scale": Vector2(1.0, 1.0),
		"arc_rot": 0.0,
		"arc_pos": Vector2(14, -13),
		"sword_rot_start": -1.45,
		"sword_rot_end": 1.2,
	},
	AttackKind.COMBO_2: {
		"damage": 20,
		"knockback": 95.0,
		"duration": 0.21,
		"active_start": 0.03,
		"active_end": 0.14,
		"lunge": 55.0,
		"depth_tol": 16.0,
		"hitstop": 0.038,
		"shake": 2.0,
		"arc_color": Color(0.72, 0.9, 1.0, 0.82),
		"arc_scale": Vector2(1.08, -1.0),
		"arc_rot": -0.15,
		"arc_pos": Vector2(15, -14),
		"sword_rot_start": 1.4,
		"sword_rot_end": -1.3,
	},
	AttackKind.COMBO_3: {
		"damage": 32,
		"knockback": 185.0,
		"duration": 0.28,
		"active_start": 0.05,
		"active_end": 0.19,
		"lunge": 125.0,
		"depth_tol": 18.0,
		"hitstop": 0.065,
		"shake": 3.4,
		"arc_color": Color(1.0, 0.86, 0.45, 0.88),
		"arc_scale": Vector2(1.32, 1.15),
		"arc_rot": 0.0,
		"arc_pos": Vector2(18, -13),
		"sword_rot_start": -1.75,
		"sword_rot_end": 1.4,
	},
	AttackKind.DASH_ATTACK: {
		"damage": 22,
		"knockback": 0.0,
		"launch_z": 148.0,
		"duration": 0.22,
		"active_start": 0.02,
		"active_end": 0.18,
		"lunge": 275.0,
		"depth_tol": 18.0,
		"hitstop": 0.045,
		"shake": 2.6,
		"arc_color": Color(0.68, 0.96, 1.0, 0.85),
		"arc_scale": Vector2(1.38, 0.82),
		"arc_rot": 0.0,
		"arc_pos": Vector2(16, -12),
		"sword_rot_start": -0.25,
		"sword_rot_end": 0.12,
	},
	AttackKind.AIR_SLASH: {
		"damage": 22,
		"knockback": 115.0,
		"duration": 0.22,
		"active_start": 0.03,
		"active_end": 0.16,
		"lunge": 35.0,
		"depth_tol": 18.0,
		"hitstop": 0.045,
		"shake": 2.4,
		"arc_color": Color(0.84, 0.94, 1.0, 0.84),
		"arc_scale": Vector2(1.18, 1.15),
		"arc_rot": 0.28,
		"arc_pos": Vector2(15, -10),
		"sword_rot_start": -1.5,
		"sword_rot_end": 1.35,
	},
	AttackKind.POGO_DOWN: {
		"damage": 20,
		"knockback": 75.0,
		"duration": 0.22,
		"active_start": 0.02,
		"active_end": 0.17,
		"lunge": 0.0,
		"depth_tol": 20.0,
		"hitstop": 0.05,
		"shake": 2.6,
		"arc_color": Color(1.0, 0.9, 0.5, 0.88),
		"arc_scale": Vector2(1.05, 1.05),
		"arc_rot": 1.57,
		"arc_pos": Vector2(0, 6),
		"sword_rot_start": 2.1,
		"sword_rot_end": 1.25,
	},
}

@export var max_hp: int = 100
@export var move_speed_x: float = 125.0
@export var move_speed_y: float = 88.0
@export var jump_force: float = 225.0
@export var pogo_bounce_force: float = 225.0
@export var gravity_z: float = 700.0

@export var dash_speed: float = 280.0
@export var dash_duration: float = 0.20
@export var dash_cooldown: float = 0.34
@export var post_hit_invuln_duration: float = 0.55
@export var combo_reset_window: float = 0.42
@export var low_obstacle_clear_height: float = 13.0

@export var max_sanity: int = 100
@export var ring_veil_duration: float = 3.5
@export var ring_veil_cooldown: float = 4.5
@export var ring_veil_speed_mult: float = 1.25
@export var ring_activation_sanity_cost: float = 12.0
@export var ring_drain_sanity_per_sec: float = 8.0
@export var ring_ambush_bonus_damage: int = 12
@export var perfect_dodge_bonus_damage: int = 10

var current_hp: int = max_hp
var current_sanity: float = float(max_sanity)
var bonus_damage: int = 0
var height_z: float = 0.0
var velocity_z: float = 0.0
var facing: int = 1
var is_dead: bool = false
var input_locked: bool = false

var _last_emitted_sanity: int = max_sanity
var _zero_sanity_hp_tick: float = 0.0

var _action_anim_locked: bool = false
var _attack_kind: AttackKind = AttackKind.NONE
var _attack_timer: float = 0.0
var _attack_duration: float = 0.0
var _attack_lunge_velocity: Vector2 = Vector2.ZERO
var _attack_hit_targets: Array[Node] = []
var _pogo_bounced_this_swing: bool = false
var _empowered_strike_bonus: int = 0

var _combo_step: int = 0
var _combo_window_timer: float = 0.0
var _buffered_attack: bool = false

var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_trail_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT

var _ring_veil_timer: float = 0.0
var _ring_cooldown_timer: float = 0.0

var _invuln_timer: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _current_interactable: Interactable = null
var root_duration_remaining: float = 0.0

@onready var body_pivot: Node2D = $BodyPivot
@onready var visual_rig: Node2D = $BodyPivot/VisualRig
@onready var sword_pivot: Node2D = $BodyPivot/VisualRig/SwordPivot
@onready var shadow: Polygon2D = $Shadow
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var attack_hitbox: Area2D = $BodyPivot/AttackHitbox
@onready var pogo_hitbox: Area2D = $BodyPivot/PogoHitbox
@onready var slash_arc: Polygon2D = $BodyPivot/SlashArc
@onready var foot_clearance: Area2D = $FootClearance
@onready var enemy_clearance: Area2D = $EnemyClearance
@onready var interaction_sensor: Area2D = $InteractionSensor


func _ready() -> void:
	add_to_group("player")
	current_hp = max_hp
	current_sanity = float(max_sanity)
	_last_emitted_sanity = max_sanity
	attack_hitbox.monitoring = false
	pogo_hitbox.monitoring = false
	slash_arc.visible = false
	anim_player.animation_finished.connect(_on_animation_finished)
	health_changed.emit(current_hp, max_hp)
	sanity_changed.emit(_last_emitted_sanity, max_sanity)
	ring_state_changed.emit(false, 0.0, ring_veil_cooldown)
	_update_visual_height()
	_play_locomotion_animation()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_update_timers(delta)
	if input_locked:
		velocity = Vector2.ZERO
		_clear_interactable_highlight()
		_update_vertical_motion(delta)
		move_and_slide()
		_update_visual_height()
		_update_visual_effects()
		_play_locomotion_animation()
		return

	_update_interactable_focus()
	_handle_action_inputs()
	_update_movement(delta)
	_update_attack_active_frames()
	_update_vertical_motion(delta)
	_update_low_obstacle_collision()
	_update_enemy_passthrough_collision()
	move_and_slide()
	_update_visual_height()
	_update_visual_effects()
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
	# Fioletowy błysk sygnalizujący unieruchomienie
	_spawn_hit_spark(global_position + Vector2(0, -18), Color(0.78, 0.35, 0.95, 1.0))


func _emit_sanity_if_changed() -> void:
	var rounded := clampi(int(ceilf(current_sanity)), 0, max_sanity)
	if rounded != _last_emitted_sanity:
		_last_emitted_sanity = rounded
		sanity_changed.emit(rounded, max_sanity)


func is_grounded() -> bool:
	return height_z <= 0.0 and velocity_z <= 0.0


func is_in_shadow_veil() -> bool:
	return _ring_veil_timer > 0.0 and not is_dead


func is_invincible() -> bool:
	return _is_dashing or _attack_kind == AttackKind.DASH_ATTACK or is_in_shadow_veil() or _invuln_timer > 0.0 or is_dead


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO, bypass_shadow_veil: bool = false, sanity_drain: int = 0) -> void:
	if is_dead or _is_dashing or _attack_kind == AttackKind.DASH_ATTACK or _invuln_timer > 0.0:
		return
	if is_in_shadow_veil() and not bypass_shadow_veil:
		return

	current_hp = maxi(0, current_hp - amount)
	health_changed.emit(current_hp, max_hp)
	if sanity_drain > 0:
		drain_sanity(float(sanity_drain))

	_cancel_attack()
	_combo_step = 0
	_buffered_attack = false

	_knockback_velocity = knockback
	_invuln_timer = post_hit_invuln_duration

	var cam := get_tree().get_first_node_in_group("main_camera")
	if cam != null and cam.has_method("shake"):
		cam.shake(3.2, 0.14)

	if current_hp <= 0:
		play_dead_animation()
		died.emit()
		return

	play_action_animation(&"hurt")


func play_action_animation(anim_name: StringName) -> void:
	if is_dead:
		return
	_action_anim_locked = true
	anim_player.play(anim_name)
	anim_player.seek(0.0, true)


func play_dead_animation() -> void:
	is_dead = true
	_cancel_attack()
	_is_dashing = false
	_ring_veil_timer = 0.0
	_action_anim_locked = true
	visual_rig.visible = true
	visual_rig.modulate = Color.WHITE
	velocity = Vector2.ZERO
	ring_state_changed.emit(false, _ring_cooldown_timer, ring_veil_cooldown)
	anim_player.play(&"dead")


func _update_timers(delta: float) -> void:
	_dash_cooldown_timer = maxf(0.0, _dash_cooldown_timer - delta)
	_invuln_timer = maxf(0.0, _invuln_timer - delta)
	root_duration_remaining = maxf(0.0, root_duration_remaining - delta)

	if _ring_veil_timer > 0.0:
		_ring_veil_timer = maxf(0.0, _ring_veil_timer - delta)
		if current_sanity > 0.0:
			drain_sanity(ring_drain_sanity_per_sec * delta)
		else:
			# When sanity reaches 0 inside the Ring, the Ring feeds on Frodo's life force
			_zero_sanity_hp_tick += delta
			if _zero_sanity_hp_tick >= 0.7:
				_zero_sanity_hp_tick = 0.0
				current_hp = maxi(0, current_hp - 5)
				health_changed.emit(current_hp, max_hp)
				if current_hp <= 0:
					play_dead_animation()
					died.emit()
					return

		if _ring_veil_timer <= 0.0:
			_exit_shadow_veil()
		else:
			ring_state_changed.emit(true, _ring_veil_timer, ring_veil_duration)
	elif _ring_cooldown_timer > 0.0:
		_zero_sanity_hp_tick = 0.0
		_ring_cooldown_timer = maxf(0.0, _ring_cooldown_timer - delta)
		ring_state_changed.emit(false, _ring_cooldown_timer, ring_veil_cooldown)

	if _attack_kind == AttackKind.NONE and _combo_window_timer > 0.0:
		_combo_window_timer -= delta
		if _combo_window_timer <= 0.0:
			_combo_step = 0

	if _attack_kind != AttackKind.NONE:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_finish_attack()

	if _is_dashing:
		_dash_timer -= delta
		_dash_trail_timer -= delta
		if _dash_trail_timer <= 0.0:
			_dash_trail_timer = 0.055
			_spawn_dash_afterimage(Color(0.62, 0.9, 1.0, 0.45))
		if _dash_timer <= 0.0:
			_is_dashing = false


func _handle_action_inputs() -> void:
	if Input.is_action_just_pressed("interact") and _current_interactable != null and is_grounded() and not _is_dashing:
		_current_interactable.interact(self)
		return

	if Input.is_action_just_pressed("ring_power"):
		if _ring_veil_timer > 0.0:
			_exit_shadow_veil()
		elif _ring_cooldown_timer <= 0.0:
			_enter_shadow_veil()

	if Input.is_action_just_pressed("jump") and is_grounded() and not _is_dashing:
		if _attack_kind != AttackKind.NONE:
			_cancel_attack()
		velocity_z = jump_force
		if not _action_anim_locked:
			anim_player.play(&"jump")

	# Dash can cancel ground attacks for responsive dodging
	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0 and not _is_dashing:
		_start_dash()
		return

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
	_spawn_hit_spark(global_position + Vector2(0, -14), Color(1.0, 0.82, 0.35, 1.0))
	ring_state_changed.emit(true, _ring_veil_timer, ring_veil_duration)


func _exit_shadow_veil() -> void:
	_ring_veil_timer = 0.0
	_zero_sanity_hp_tick = 0.0
	ring_state_changed.emit(false, _ring_cooldown_timer, ring_veil_cooldown)


func _start_dash() -> void:
	_cancel_attack()
	_buffered_attack = false
	_combo_step = 0
	_is_dashing = true
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	_dash_trail_timer = 0.0

	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vec.length_squared() > 0.04:
		_dash_dir = Vector2(input_vec.x, input_vec.y * 0.78).normalized()
		if absf(input_vec.x) > 0.05:
			facing = 1 if input_vec.x > 0.0 else -1
			body_pivot.scale.x = facing
	else:
		_dash_dir = Vector2(facing, 0.0)

	_check_perfect_dodge()
	_spawn_dash_afterimage(Color(0.62, 0.9, 1.0, 0.55))
	play_action_animation(&"dash")


func _check_perfect_dodge() -> void:
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
			_spawn_hit_spark(global_position + Vector2(0, -16), Color(0.65, 0.95, 1.0, 1.0))
			var cam := get_tree().get_first_node_in_group("main_camera")
			if cam != null and cam.has_method("trigger_hitstop"):
				cam.trigger_hitstop(0.055)
			break


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
	_attack_hit_targets.clear()
	_pogo_bounced_this_swing = false
	_buffered_attack = false

	# Striking out of the Ring's Shadow Veil ends it early for a stronger ambush blow
	if is_in_shadow_veil():
		_empowered_strike_bonus = maxi(_empowered_strike_bonus, ring_ambush_bonus_damage)
		_exit_shadow_veil()

	var input_x := Input.get_axis("move_left", "move_right")
	if absf(input_x) > 0.05 and kind != AttackKind.DASH_ATTACK:
		facing = 1 if input_x > 0.0 else -1
		body_pivot.scale.x = facing

	var lunge := float(spec["lunge"])
	if kind == AttackKind.DASH_ATTACK:
		_attack_lunge_velocity = _dash_dir * lunge
		_spawn_dash_afterimage(Color(0.75, 0.96, 1.0, 0.65))
	else:
		_attack_lunge_velocity = Vector2(facing * lunge, 0.0)

	if kind == AttackKind.AIR_SLASH and velocity_z < 45.0:
		velocity_z = 45.0

	var base_arc_color: Color = spec["arc_color"]
	if _empowered_strike_bonus > 0:
		base_arc_color = Color(1.0, 0.85, 0.4, 0.92)
	slash_arc.color = base_arc_color
	slash_arc.scale = spec["arc_scale"]
	slash_arc.rotation = float(spec["arc_rot"])
	slash_arc.position = spec["arc_pos"]
	slash_arc.visible = false

	if kind == AttackKind.POGO_DOWN:
		_action_anim_locked = true
		anim_player.stop()
		visual_rig.rotation = 0.16
		visual_rig.scale = Vector2(0.95, 1.08)
	else:
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


func _update_movement(delta: float) -> void:
	var veil_mult := ring_veil_speed_mult if is_in_shadow_veil() else 1.0

	if _is_dashing:
		velocity = _dash_dir * dash_speed * veil_mult
		return

	# Unieruchomienie przez pułapkę cienia — gracz może atakować, ale nie może się ruszać
	if root_duration_remaining > 0.0 and not _is_dashing:
		velocity = _knockback_velocity
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 480.0 * delta)
		return

	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _attack_kind == AttackKind.DASH_ATTACK:
		velocity = _attack_lunge_velocity
		_attack_lunge_velocity = _attack_lunge_velocity.move_toward(Vector2.ZERO, 180.0 * delta)
	elif _attack_kind != AttackKind.NONE:
		var air_control := 0.85 if not is_grounded() else 0.25
		velocity.x = input_vec.x * move_speed_x * air_control * veil_mult + _attack_lunge_velocity.x + _knockback_velocity.x
		velocity.y = input_vec.y * move_speed_y * air_control * veil_mult + _attack_lunge_velocity.y + _knockback_velocity.y
		_attack_lunge_velocity = _attack_lunge_velocity.move_toward(Vector2.ZERO, 680.0 * delta)
	else:
		velocity.x = input_vec.x * move_speed_x * veil_mult + _knockback_velocity.x
		velocity.y = input_vec.y * move_speed_y * veil_mult + _knockback_velocity.y
		if input_vec.x > 0.05:
			facing = 1
		elif input_vec.x < -0.05:
			facing = -1
		body_pivot.scale.x = facing

	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 480.0 * delta)


func _update_attack_active_frames() -> void:
	if _attack_kind == AttackKind.NONE:
		return

	var spec: Dictionary = ATTACK_SPECS[_attack_kind]
	var elapsed := _attack_duration - _attack_timer
	var progress := clampf(elapsed / maxf(_attack_duration, 0.01), 0.0, 1.0)
	var in_active := elapsed >= float(spec["active_start"]) and elapsed <= float(spec["active_end"])
	var is_pogo := _attack_kind == AttackKind.POGO_DOWN

	attack_hitbox.monitoring = in_active and not is_pogo
	pogo_hitbox.monitoring = in_active and is_pogo
	slash_arc.visible = in_active

	if is_pogo:
		sword_pivot.position = Vector2(0, -4)
		sword_pivot.rotation = lerpf(float(spec["sword_rot_start"]), float(spec["sword_rot_end"]), progress)

	if not in_active:
		return

	var active_area := pogo_hitbox if is_pogo else attack_hitbox
	var depth_tol := float(spec["depth_tol"])
	var max_height_diff := 36.0 if is_pogo else 28.0

	for area in active_area.get_overlapping_areas():
		var target := area.get_parent() as Node2D
		if target == null or target == self or target in _attack_hit_targets:
			continue
		if not target.is_in_group("enemies"):
			continue
		if absf(target.global_position.y - global_position.y) > depth_tol:
			continue
		if height_z > max_height_diff:
			continue

		_attack_hit_targets.append(target)
		if target.has_method("take_damage"):
			var kb_dir := float(facing)
			if is_pogo and absf(target.global_position.x - global_position.x) > 2.0:
				kb_dir = signf(target.global_position.x - global_position.x)
			var launch_z := float(spec.get("launch_z", 0.0))
			var total_damage := int(spec["damage"]) + bonus_damage + _empowered_strike_bonus
			_empowered_strike_bonus = 0
			target.take_damage(total_damage, Vector2(kb_dir * float(spec["knockback"]), 0.0), launch_z)

			var spark_pos: Vector2 = (global_position + target.global_position) * 0.5 + Vector2(0, -14)
			var spark_color := Color(1.0, 0.9, 0.45, 1.0) if is_pogo else Color(1.0, 0.94, 0.72, 1.0)
			if is_pogo:
				spark_pos = global_position + Vector2(0, -height_z + 2.0)
				_trigger_pogo_bounce()

			_spawn_hit_spark(spark_pos, spark_color)
			var cam := get_tree().get_first_node_in_group("main_camera")
			if cam != null:
				if cam.has_method("shake"):
					cam.shake(float(spec["shake"]), 0.10)
				if cam.has_method("trigger_hitstop"):
					cam.trigger_hitstop(float(spec["hitstop"]))


func _trigger_pogo_bounce() -> void:
	if _pogo_bounced_this_swing:
		return
	_pogo_bounced_this_swing = true
	height_z = maxf(height_z, 8.0)
	velocity_z = pogo_bounce_force
	_dash_cooldown_timer = 0.0


func _spawn_hit_spark(world_pos: Vector2, spark_color: Color) -> void:
	var spark := Polygon2D.new()
	spark.polygon = PackedVector2Array([-6, 0, -2, -2, 0, -6, 2, -2, 6, 0, 2, 2, 0, 6, -2, 2])
	spark.color = spark_color
	spark.global_position = world_pos
	spark.z_index = 20
	get_parent().add_child(spark)

	var tween := spark.create_tween()
	tween.set_parallel(true)
	tween.tween_property(spark, "scale", Vector2(1.45, 1.45), 0.12)
	tween.tween_property(spark, "modulate:a", 0.0, 0.12)
	tween.finished.connect(spark.queue_free)


func _spawn_dash_afterimage(tint: Color) -> void:
	var ghost := Polygon2D.new()
	ghost.polygon = PackedVector2Array([-7, -5, 6, -5, 5, -20, 3, -28, -5, -27, -6, -20])
	ghost.color = tint
	ghost.global_position = global_position + Vector2(0, -height_z)
	ghost.scale.x = facing
	ghost.z_index = z_index - 1
	get_parent().add_child(ghost)

	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.18)
	tween.finished.connect(ghost.queue_free)


func _update_vertical_motion(delta: float) -> void:
	if height_z > 0.0 or velocity_z > 0.0:
		velocity_z -= gravity_z * delta
		height_z += velocity_z * delta
		if height_z <= 0.0:
			height_z = 0.0
			velocity_z = 0.0
			if _attack_kind == AttackKind.POGO_DOWN or _attack_kind == AttackKind.AIR_SLASH:
				_cancel_attack()


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


func _update_visual_height() -> void:
	body_pivot.position.y = -height_z
	var shadow_scale := clampf(1.0 - (height_z / 110.0), 0.45, 1.0)
	shadow.scale = Vector2(shadow_scale, shadow_scale)


func _update_visual_effects() -> void:
	if _invuln_timer > 0.0 and not _is_dashing:
		visual_rig.visible = int(_invuln_timer * 24.0) % 2 == 0
	else:
		visual_rig.visible = true

	if is_in_shadow_veil():
		var pulse := 0.42 + 0.08 * sin(Time.get_ticks_msec() * 0.012)
		visual_rig.modulate = Color(0.72, 0.86, 1.0, pulse)
	elif _empowered_strike_bonus > 0:
		visual_rig.modulate = Color(1.15, 1.06, 0.85, 1.0)
	elif not _action_anim_locked:
		visual_rig.modulate = Color.WHITE


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
