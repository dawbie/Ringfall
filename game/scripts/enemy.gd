class_name Enemy
extends CharacterBody2D
## 2.5D test enemy (dark orc) with simple belt-scroller AI:
## chases the player, aligns Y depth, telegraphs melee strikes, attacks, and takes damage.

signal died(enemy: Enemy)
signal health_changed(current_hp: int, max_hp: int)

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVER, HURT, DEAD }

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

var current_hp: int = max_hp
var state: State = State.IDLE
var facing: int = -1

var _state_timer: float = 0.0
var _walk_cycle: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _attack_hit_targets: Array[Node] = []
var _target: Node2D = null

@onready var body_pivot: Node2D = $BodyPivot
@onready var visual_rig: Node2D = $BodyPivot/VisualRig
@onready var weapon_pivot: Node2D = $BodyPivot/VisualRig/WeaponPivot
@onready var telegraph_marker: Polygon2D = $BodyPivot/VisualRig/TelegraphMarker
@onready var attack_hitbox: Area2D = $BodyPivot/AttackHitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var overhead_hp: Node2D = $OverheadHP


func _ready() -> void:
	add_to_group("enemies")
	current_hp = max_hp
	attack_hitbox.monitoring = false
	telegraph_marker.visible = false
	overhead_hp.set_health(current_hp, max_hp)
	_target = get_tree().get_first_node_in_group("player") as Node2D
	_update_facing(-1)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Node2D
		if _target == null:
			return

	_state_timer = maxf(0.0, _state_timer - delta)

	match state:
		State.IDLE:
			_process_idle()
		State.CHASE:
			_process_chase(delta)
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


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if state == State.DEAD:
		return

	current_hp = maxi(0, current_hp - amount)
	overhead_hp.set_health(current_hp, max_hp)
	health_changed.emit(current_hp, max_hp)
	attack_hitbox.monitoring = false
	telegraph_marker.visible = false

	if current_hp <= 0:
		_enter_dead()
		return

	state = State.HURT
	_state_timer = hurt_duration
	_knockback_velocity = knockback


func _process_idle() -> void:
	velocity = Vector2.ZERO
	if global_position.distance_to(_target.global_position) <= aggro_range:
		state = State.CHASE


func _process_chase(delta: float) -> void:
	var target_dead: bool = bool(_target.get("is_dead"))
	if target_dead:
		velocity = Vector2.ZERO
		state = State.IDLE
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

	# Simple obstacle sidestep if blocked horizontally by a pillar or slab.
	if is_on_wall() and absf(dir_y) < 0.1:
		dir_y = -1.0 if global_position.y > 180.0 else 1.0

	velocity = Vector2(dir_x * move_speed_x, dir_y * move_speed_y)
	_walk_cycle += delta * 10.0


func _enter_windup() -> void:
	state = State.WINDUP
	_state_timer = windup_duration
	velocity = Vector2.ZERO
	telegraph_marker.visible = true
	AudioManager.play_sfx(&"enemy_windup", -1.0 if is_elite else -3.0, 0.84 if is_elite else 0.95, 0.93 if is_elite else 1.06, 0.08)
	var dx := _target.global_position.x - global_position.x
	if absf(dx) > 1.0:
		_update_facing(1 if dx > 0.0 else -1)


func _process_windup(_delta: float) -> void:
	velocity = Vector2.ZERO
	if _state_timer <= 0.0:
		_enter_attack()


func _enter_attack() -> void:
	state = State.ATTACK
	_state_timer = attack_duration
	_attack_hit_targets.clear()
	telegraph_marker.visible = false
	velocity = Vector2(facing * 45.0, 0.0)
	attack_hitbox.monitoring = true
	AudioManager.play_sfx(&"enemy_attack", -1.5, 0.84 if is_elite else 0.95, 0.93 if is_elite else 1.07, 0.06)


func _process_attack() -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 8.0)

	if attack_hitbox.monitoring:
		for area in attack_hitbox.get_overlapping_areas():
			var victim := area.get_parent()
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
	if _state_timer <= 0.0:
		_knockback_velocity = Vector2.ZERO
		state = State.CHASE


func _enter_dead() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	attack_hitbox.monitoring = false
	hurtbox.set_deferred("monitorable", false)
	body_collision.set_deferred("disabled", true)
<<<<<<< Updated upstream
=======
	GameState.register_enemy_kill()
	AudioManager.play_sfx(&"enemy_death", -1.0, 0.80 if is_elite else 0.92, 0.90 if is_elite else 1.06, 0.05)
	_spawn_gold_drops()
>>>>>>> Stashed changes
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


func _update_visuals(_delta: float) -> void:
	match state:
		State.IDLE:
			visual_rig.position = Vector2.ZERO
			visual_rig.rotation = 0.0
			visual_rig.modulate = Color.WHITE
			weapon_pivot.rotation = 0.1
		State.CHASE:
			visual_rig.position = Vector2(0.0, -absf(sin(_walk_cycle)) * 2.0)
			visual_rig.rotation = 0.07
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
