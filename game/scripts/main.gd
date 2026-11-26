extends Node2D
## Coordinates the main scene, wiring player HP, Sanity, Ring veil, Nightmare spawning, and death menu.

const NIGHTMARE_SCENE: PackedScene = preload("res://scenes/nightmare_stalker.tscn")

var _player: Player = null
var _actors_parent: Node2D = null
var _nightmare_spawn_timer: float = 2.0
var _announced_madness: bool = false

@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	Engine.time_scale = 1.0
	hud.restart_requested.connect(_on_restart_requested)

	_player = get_tree().get_first_node_in_group("player") as Player
	_actors_parent = find_child("YSortActors", true, false) as Node2D
	if _player != null:
		hud.set_health(_player.current_hp, _player.max_hp)
		hud.set_sanity(int(ceilf(_player.current_sanity)), _player.max_sanity)
		hud.set_ring_state(false, 0.0, _player.ring_veil_cooldown)
		_player.health_changed.connect(hud.set_health)
		_player.sanity_changed.connect(hud.set_sanity)
		_player.ring_state_changed.connect(hud.set_ring_state)
		_player.died.connect(_on_player_died)


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player) or _player.is_dead or _actors_parent == null:
		return

	if _player.current_sanity > 40.0:
		_announced_madness = false
		_nightmare_spawn_timer = 1.5
		return

	if not _announced_madness:
		_announced_madness = true
		hud.show_toast("Umysl slabnie — cienie wylaniaja sie z mroku!", 2.4)

	var active_nightmares := get_tree().get_nodes_in_group("nightmares").size()
	var max_nightmares := 2 if _player.current_sanity <= 20.0 else 1
	if active_nightmares >= max_nightmares:
		return

	_nightmare_spawn_timer -= delta
	if _nightmare_spawn_timer <= 0.0:
		_spawn_nightmare()
		_nightmare_spawn_timer = 4.2 if _player.current_sanity <= 20.0 else 6.5


func _spawn_nightmare() -> void:
	var stalker := NIGHTMARE_SCENE.instantiate() as Node2D
	if stalker == null:
		return
	var side := -1.0 if randf() < 0.5 else 1.0
	var spawn_x := clampf(_player.global_position.x + side * 195.0, 28.0, 1772.0)
	var spawn_y := clampf(_player.global_position.y + randf_range(-28.0, 28.0), 124.0, 238.0)
	stalker.position = Vector2(spawn_x, spawn_y)
	_actors_parent.add_child(stalker)


func _on_player_died() -> void:
	await get_tree().create_timer(0.5, true, false, true).timeout
	hud.show_death_menu()


func _on_restart_requested() -> void:
	Engine.time_scale = 1.0
	GameState.reset_run()
	get_tree().reload_current_scene()
