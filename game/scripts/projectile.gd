class_name Projectile
extends Area2D
## 2.5D horizontal projectile (bolt or immobilizing shadow snare).
## Checks Y-depth alignment, player jump height, and collides with tall world pillars/walls.

@export var speed: float = 195.0
@export var damage: int = 16
@export var knockback_force: float = 55.0
@export var root_duration: float = 0.0
@export var depth_tolerance: float = 13.0
@export var max_lifetime: float = 2.6

var direction_x: float = -1.0
var _life_timer: float = 0.0
var _spent: bool = false

@onready var bolt_visual: Polygon2D = $BoltVisual
@onready var snare_visual: Polygon2D = $SnareVisual


func _ready() -> void:
	_life_timer = max_lifetime
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	_apply_style()


func setup(dir_x: float, is_snare: bool) -> void:
	direction_x = 1.0 if dir_x >= 0.0 else -1.0
	if is_snare:
		speed = 165.0
		damage = 10
		root_duration = 1.2
		knockback_force = 20.0
	else:
		speed = 210.0
		damage = 16
		root_duration = 0.0
		knockback_force = 60.0
	if is_node_ready():
		_apply_style()


func _apply_style() -> void:
	scale.x = direction_x
	bolt_visual.visible = root_duration <= 0.0
	snare_visual.visible = root_duration > 0.0


func _physics_process(delta: float) -> void:
	if _spent:
		return

	position.x += direction_x * speed * delta
	if root_duration > 0.0:
		snare_visual.rotation += delta * 12.0

	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _spent:
		return
	var victim := area.get_parent() as Player
	if victim == null or victim.is_dead:
		return
	if absf(victim.global_position.y - global_position.y) > depth_tolerance:
		return
	if victim.height_z > 16.0:
		return
	if victim.is_invincible():
		return

	_spent = true
	victim.take_damage(damage, Vector2(direction_x * knockback_force, 0.0))
	if root_duration > 0.0 and victim.has_method("apply_root"):
		victim.apply_root(root_duration)
	_spawn_impact_flash()
	queue_free()


func _on_body_entered(_body: Node2D) -> void:
	if _spent:
		return
	_spent = true
	AudioManager.play_sfx(&"projectile_impact", -3.5, 0.92, 1.10, 0.04)
	_spawn_impact_flash()
	queue_free()


func _spawn_impact_flash() -> void:
	var spark := Polygon2D.new()
	spark.polygon = PackedVector2Array([-4, 0, -1, -1, 0, -4, 1, -1, 4, 0, 1, 1, 0, 4, -1, 1])
	spark.color = Color(0.85, 0.38, 0.95, 1.0) if root_duration > 0.0 else Color(1.0, 0.72, 0.35, 1.0)
	spark.global_position = global_position + Vector2(0, -13)
	spark.z_index = 20
	get_parent().add_child(spark)

	var tween := spark.create_tween()
	tween.tween_property(spark, "modulate:a", 0.0, 0.14)
	tween.finished.connect(spark.queue_free)
