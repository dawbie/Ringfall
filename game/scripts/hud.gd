extends CanvasLayer
## Top-left player health HUD and death overlay menu with quick restart.

signal restart_requested

const BAR_MAX_WIDTH: float = 96.0

@onready var hp_fill: ColorRect = $TopLeftHUD/BarFrame/BarBg/HpFill
@onready var hp_label: Label = $TopLeftHUD/HpValue
@onready var death_overlay: ColorRect = $DeathOverlay
@onready var restart_button: Button = $DeathOverlay/CenterBox/VBox/RestartButton


func _ready() -> void:
	death_overlay.visible = false
	restart_button.pressed.connect(_on_restart_pressed)


func set_health(current_hp: int, max_hp: int) -> void:
	var clamped_hp := clampi(current_hp, 0, maxi(1, max_hp))
	var ratio := float(clamped_hp) / float(maxi(1, max_hp))
	hp_fill.size.x = BAR_MAX_WIDTH * ratio
	hp_label.text = "%d / %d" % [clamped_hp, max_hp]


func show_death_menu() -> void:
	death_overlay.visible = true
	restart_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not death_overlay.visible:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R or event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
<<<<<<< Updated upstream
			_on_restart_pressed()
=======
			_close_dialogue()
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		_advance_dialogue()


func _advance_dialogue() -> void:
	AudioManager.play_sfx(&"dialogue_blip", -3.0, 0.95, 1.06)
	_dialogue_index += 1
	if _dialogue_index >= _dialogue_lines.size():
		_close_dialogue()
		return
	dialogue_text.text = _dialogue_lines[_dialogue_index]
	continue_hint.text = "[Shift / Spacja] Dalej" if _dialogue_index < _dialogue_lines.size() - 1 else "[Shift / Spacja] Zamknij"


func _on_choice_pressed(index: int) -> void:
	AudioManager.play_sfx(&"ui_click", -2.0, 0.98, 1.02)
	var cb := _choice_callback
	_close_dialogue()
	if cb.is_valid():
		cb.call(index)


func _close_dialogue() -> void:
	dialogue_panel.visible = false
	_is_choice_dialogue = false
	_choice_callback = Callable()
	_set_player_input_locked(false)


func _set_player_input_locked(locked: bool) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.set_input_locked(locked)
>>>>>>> Stashed changes


func _on_restart_pressed() -> void:
	AudioManager.play_sfx(&"ui_click", -2.0, 0.98, 1.02)
	restart_requested.emit()
