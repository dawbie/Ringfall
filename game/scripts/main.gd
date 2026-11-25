extends Node2D
## Coordinates the main prototype scene, wiring player health and death state to the HUD.

@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	Engine.time_scale = 1.0
	hud.restart_requested.connect(_on_restart_requested)

	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		hud.set_health(player.current_hp, player.max_hp)
		player.health_changed.connect(hud.set_health)
		player.died.connect(_on_player_died)


func _on_player_died() -> void:
	await get_tree().create_timer(0.5, true, false, true).timeout
	hud.show_death_menu()


func _on_restart_requested() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
