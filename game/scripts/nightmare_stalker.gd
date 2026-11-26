class_name NightmareStalker
extends CharacterBody2D
## Shadow creature spawned at low sanity (Don't Starve style).
## Can perceive and strike Frodo even inside the Ring's Shadow Veil; defeating it restores sanity.

signal died(stalker: NightmareStalker)

enum State { CHASE, WINDUP, ATTACK, RECOVER, HURT, DISSOLVING }

@export var max_hp: int = 40
@export var move_speed_x: float = 92.0
@export var move_speed_y: float = 68.0
@export var attack_range_x: float = 30.0
@export var depth_tolerance: float = 14.0
@export var windup_duration: float = 0.38
@export var attack_duration: float = 0.16
@export var recover_duration: float = 0.42
@export var hurt_duration: float = 0.20
@export var attack_damage: int = 18
@export var sanity_damage: int = 8
@export var attack_knockback: float = 100.0
@export var sanity_reward: float = 16.0
@export var dissolve_sanity_threshold: float = 55.0
@export var gravity_z: float = 640.0

var current_hp: int = max_hp
var state: State = State.CHASE
var facing: int = -1
var height_z: float = 0.0
var velocity_z: float = 0.0

var _state_timer: float = 0.0
var _float_cycle: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _attack_hit_targets: Array[Node] = []
var _target: Player = null

@onready var body_pivot: Node2D = $BodyPivot
@onready var visual_rig: Node2D = $BodyPivot/VisualRig
@onready var claw_pivot: Node2D = $BodyPivot/VisualRig/ClawPivot
@onready var telegraph_marker: Polygon2D = $BodyPivot/VisualRig/TelegraphMarker
@onready var attack_hitbox: Area2D = $BodyPivot/AttackHitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var overhead_hp: Node2D = $OverheadHP
@onready var shadow: Polygon2D = $Shadow


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("nightmares")
	current_hp = max_hp
	attack_hitbox.monitoring = false
	telegraph_marker.visible = false
	overhead_hp.set_health(current_hp, max_hp)
	_target = get_tree().get_first_node_in_group("player") as Player


func _physics_process(delta: float) -> void:
	_update_vertical_motion(delta)
	_update_visual_height()

	if state == State.DISSOLVING:
		return

	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Player
		if _target == null:
			return

	if _target.is_dead or _target.current_sanity >= dissolve_sanity_threshold:
		_dissolve(false)
		return

	_state_timer = maxf(0.0, _state_timer - delta)
	_float_cycle += delta * 7.0

	match state:
		State.CHASE:
			_process_chase()
		State.WINDUP:
			_process_windup()
		State.ATTACK:
			_process_attack()
		State.RECOVER:
			_process_recover()
		State.HURT:
			_process_hurt(delta)

	move_and_slide()
	_update_visuals()


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO, launch_z: float = 0.0) -> void:
	if state == State.DISSOLVING:
		return

	current_hp = maxi(0, current_hp - amount)
	overhead_hp.set_health(current_hp, max_hp)
	attack_hitbox.monitoring = false
	telegraph_marker.visible = false

	if launch_z > 0.0:
		height_z = maxf(height_z, 2.0)
		velocity_z = maxf(velocity_z, launch_z)

	if current_hp <= 0:
		_dissolve(true)
		return

	state = State.HURT
	_state_timer = hurt_duration
	_knockback_velocity = knockback


func _process_chase() -> void:
	var dx := _target.global_position.x - global_position.x
	var dy := _target.global_position.y - global_position.y
	if absf(dx) > 3.0:
		_update_facing(1 if dx > 0.0 else -1)

	if absf(dx) <= attack_range_x and absf(dy) <= depth_tolerance:
		state = State.WINDUP
		_state_timer = windup_duration
		telegraph_marker.visible = true
		velocity = Vector2.ZERO
		return

	var flank_sign := -1.0 if dx >= 0.0 else 1.0
	var desired := _target.global_position + Vector2(flank_sign * 20.0, 0.0)
	var to_desired := desired - global_position
	var dir := Vector2.ZERO
	if absf(to_desired.x) > 3.0:
		dir.x = signf(to_desired.x)
	if absf(to_desired.y) > 2.0:
		dir.y = signf(to_desired.y)

	# Shadow creatures glide straight through the gloom aggressively
	velocity = Vector2(dir.x * move_speed_x, dir.y * move_speed_y)


func _process_windup() -> void:
	velocity = Vector2.ZERO
	if _state_timer <= 0.0:
		state = State.ATTACK
		_state_timer = attack_duration
		_attack_hit_targets.clear()
		telegraph_marker.visible = false
		velocity = Vector2(facing * 85.0, 0.0)
		attack_hitbox.monitoring = true


func _process_attack() -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 10.0)

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
			if victim_z > 20.0:
				continue

			_attack_hit_targets.append(victim)
			if victim.has_method("take_damage"):
				victim.take_damage(attack_damage, Vector2(facing * attack_knockback, 0.0), true, sanity_damage)

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


func _dissolve(reward_sanity: bool) -> void:
	state = State.DISSOLVING
	velocity = Vector2.ZERO
	attack_hitbox.monitoring = false
	telegraph_marker.visible = false
	hurtbox.set_deferred("monitorable", false)
	body_collision.set_deferred("disabled", true)
	died.emit(self)

	if reward_sanity and _target != null and is_instance_valid(_target) and not _target.is_dead:
		_target.restore_sanity(sanity_reward)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null and hud.has_method("show_toast"):
			hud.show_toast("Rozproszono zjawe (+%d Woli)" % int(sanity_reward), 1.4)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual_rig, "scale", Vector2(1.4, 0.3), 0.32)
	tween.tween_property(visual_rig, "modulate:a", 0.0, 0.32)
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


func _update_visuals() -> void:
	var hover := -3.0 + sin(_float_cycle) * 2.5
	match state:
		State.CHASE:
			visual_rig.position = Vector2(0.0, hover)
			visual_rig.rotation = 0.14
			visual_rig.modulate = Color(1, 1, 1, 0.88)
			claw_pivot.rotation = -0.25 + sin(_float_cycle * 1.4) * 0.15
		State.WINDUP:
			var t := 1.0 - (_state_timer / maxf(windup_duration, 0.01))
			visual_rig.position = Vector2(-2.0 * t, hover)
			visual_rig.rotation = -0.22 * t
			visual_rig.modulate = Color(1.3, 0.7, 0.9, 0.96)
			claw_pivot.rotation = lerpf(-0.2, -1.6, t)
		State.ATTACK:
			visual_rig.position = Vector2(4.0, hover)
			visual_rig.rotation = 0.28
			visual_rig.modulate = Color.WHITE
			claw_pivot.rotation = 1.15
		State.RECOVER:
			visual_rig.position = Vector2(0.0, hover)
			visual_rig.rotation = 0.05
			visual_rig.modulate = Color(1, 1, 1, 0.85)
			claw_pivot.rotation = 0.35
		State.HURT:
			visual_rig.position = Vector2(-3.0, hover - 1.0)
			visual_rig.rotation = -0.28
			visual_rig.modulate = Color(1.8, 0.45, 0.75, 0.95)
			claw_pivot.rotation = -0.4
