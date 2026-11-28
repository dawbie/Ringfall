extends CanvasLayer
## Location completion summary overlay.
## Displays defeated enemy count and an overall summary with placeholders for future gold/EXP.

@onready var enemies_killed_label: Label = $CenterBox/Panel/Margin/VBox/EnemiesKilled
@onready var rewards_label: Label = $CenterBox/Panel/Margin/VBox/RewardsLabel
@onready var summary_label: Label = $CenterBox/Panel/Margin/VBox/Summary
@onready var continue_btn: Button = $CenterBox/Panel/Margin/VBox/ContinueBtn


func _ready() -> void:
	continue_btn.pressed.connect(_on_continue_pressed)
	_populate_stats()
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.set_input_locked(true)
	continue_btn.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R or event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_on_continue_pressed()


func _populate_stats() -> void:
	var killed := GameState.enemies_killed
	var total := maxi(killed, GameState.total_enemies_in_level)
	enemies_killed_label.text = "Pokonani przeciwnicy: %d / %d" % [killed, total]
	rewards_label.text = "Zebrane zloto: %d   |   EXP: --  (wkrotce)" % GameState.gold
	summary_label.text = "Brama Pogranicza stoi otworem. Wszystkie zagrozenia zostaly usuniete."


func _on_continue_pressed() -> void:
	Engine.time_scale = 1.0
	GameState.reset_run()
	queue_free()
	get_tree().reload_current_scene()
