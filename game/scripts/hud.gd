extends CanvasLayer
## Top-left player health, Sanity ("Wola"), Ring status HUD, vignettes, dialogue box, and death overlay.

signal restart_requested

const BAR_MAX_WIDTH: float = 96.0

var _dialogue_lines: PackedStringArray = PackedStringArray()
var _dialogue_index: int = 0
var _is_choice_dialogue: bool = false
var _choice_callback: Callable = Callable()
var _toast_tween: Tween = null
var _low_sanity_ratio: float = 0.0

@onready var hp_fill: ColorRect = $TopLeftHUD/BarFrame/BarBg/HpFill
@onready var hp_label: Label = $TopLeftHUD/HpValue
@onready var sanity_fill: ColorRect = $TopLeftHUD/SanityFrame/SanityBg/SanityFill
@onready var sanity_label: Label = $TopLeftHUD/SanityValue
@onready var ring_status: Label = $TopLeftHUD/RingStatus
@onready var gold_label: Label = $TopLeftHUD/GoldLabel
@onready var sanity_vignette: ColorRect = $SanityVignette
@onready var shadow_vignette: ColorRect = $ShadowVignette
@onready var toast_label: Label = $ToastLabel
@onready var dialogue_panel: ColorRect = $DialoguePanel
@onready var speaker_label: Label = $DialoguePanel/SpeakerLabel
@onready var dialogue_text: Label = $DialoguePanel/DialogueText
@onready var continue_hint: Label = $DialoguePanel/ContinueHint
@onready var choices_box: HBoxContainer = $DialoguePanel/ChoicesBox
@onready var choice_btn_0: Button = $DialoguePanel/ChoicesBox/ChoiceBtn0
@onready var choice_btn_1: Button = $DialoguePanel/ChoicesBox/ChoiceBtn1
@onready var death_overlay: ColorRect = $DeathOverlay
@onready var restart_button: Button = $DeathOverlay/CenterBox/VBox/RestartButton


func _ready() -> void:
	add_to_group("hud")
	death_overlay.visible = false
	shadow_vignette.visible = false
	sanity_vignette.visible = false
	dialogue_panel.visible = false
	toast_label.visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	choice_btn_0.pressed.connect(_on_choice_pressed.bind(0))
	choice_btn_1.pressed.connect(_on_choice_pressed.bind(1))
	GameState.gold_changed.connect(set_gold)
	set_gold(GameState.gold)


func _process(_delta: float) -> void:
	if _low_sanity_ratio > 0.0 and not death_overlay.visible:
		sanity_vignette.visible = true
		var pulse := 0.06 * sin(Time.get_ticks_msec() * 0.006)
		var alpha := clampf(_low_sanity_ratio * 0.45 + pulse, 0.04, 0.52)
		sanity_vignette.color = Color(0.05, 0.02, 0.1, alpha)
	else:
		sanity_vignette.visible = false


func set_health(current_hp: int, max_hp: int) -> void:
	var clamped_hp := clampi(current_hp, 0, maxi(1, max_hp))
	var ratio := float(clamped_hp) / float(maxi(1, max_hp))
	hp_fill.size.x = BAR_MAX_WIDTH * ratio
	hp_label.text = "%d / %d" % [clamped_hp, max_hp]


func set_sanity(current_sanity: int, max_sanity: int) -> void:
	var clamped := clampi(current_sanity, 0, maxi(1, max_sanity))
	var ratio := float(clamped) / float(maxi(1, max_sanity))
	sanity_fill.size.x = BAR_MAX_WIDTH * ratio
	sanity_label.text = "Wola: %d" % clamped

	if clamped <= 35:
		sanity_fill.color = Color(0.75, 0.24, 0.55, 1.0)
		sanity_label.add_theme_color_override("font_color", Color(0.95, 0.42, 0.65, 1.0))
	else:
		sanity_fill.color = Color(0.55, 0.42, 0.9, 1.0)
		sanity_label.add_theme_color_override("font_color", Color(0.78, 0.72, 0.96, 1.0))

	_low_sanity_ratio = clampf((50.0 - float(clamped)) / 50.0, 0.0, 1.0)


func set_ring_state(is_active: bool, time_remaining: float, _total_time: float) -> void:
	shadow_vignette.visible = is_active
	if is_active:
		ring_status.text = "Swiat Cieni (%.1fs)" % time_remaining
		ring_status.add_theme_color_override("font_color", Color(0.76, 0.9, 1.0, 1.0))
	elif time_remaining > 0.05:
		ring_status.text = "Pierscien [C]: %.1fs" % time_remaining
		ring_status.add_theme_color_override("font_color", Color(0.58, 0.54, 0.62, 1.0))
	else:
		ring_status.text = "Pierscien [C]: Gotowy"
		ring_status.add_theme_color_override("font_color", Color(0.91, 0.75, 0.32, 1.0))


func set_gold(amount: int) -> void:
	gold_label.text = "Zloto: %d" % amount


func show_toast(message: String, duration: float = 2.0) -> void:
	if _toast_tween != null and _toast_tween.is_running():
		_toast_tween.kill()
	toast_label.text = message
	toast_label.modulate = Color(1, 1, 1, 1)
	toast_label.visible = true
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.45).set_delay(duration)
	_toast_tween.finished.connect(func() -> void: toast_label.visible = false)


func start_dialogue(speaker: String, lines: PackedStringArray) -> void:
	if lines.is_empty():
		return
	_is_choice_dialogue = false
	_choice_callback = Callable()
	_dialogue_lines = lines
	_dialogue_index = 0

	speaker_label.text = speaker
	dialogue_text.text = _dialogue_lines[0]
	choices_box.visible = false
	continue_hint.visible = true
	continue_hint.text = "[Shift / Spacja] Dalej" if _dialogue_lines.size() > 1 else "[Shift / Spacja] Zamknij"
	dialogue_panel.visible = true
	_set_player_input_locked(true)


func start_choice_dialogue(speaker: String, prompt: String, options: PackedStringArray, callback: Callable) -> void:
	_is_choice_dialogue = true
	_choice_callback = callback
	_dialogue_lines = PackedStringArray()
	_dialogue_index = 0

	speaker_label.text = speaker
	dialogue_text.text = prompt
	continue_hint.visible = false
	choices_box.visible = true
	choice_btn_0.text = options[0] if options.size() > 0 else "Opcja 1"
	choice_btn_1.text = options[1] if options.size() > 1 else "Opcja 2"
	dialogue_panel.visible = true
	_set_player_input_locked(true)
	choice_btn_0.grab_focus()


func show_death_menu() -> void:
	_close_dialogue()
	shadow_vignette.visible = false
	sanity_vignette.visible = false
	death_overlay.visible = true
	restart_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if death_overlay.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_R or event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				_on_restart_pressed()
		return

	if not dialogue_panel.visible:
		return

	if _is_choice_dialogue:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_close_dialogue()
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		_advance_dialogue()


func _advance_dialogue() -> void:
	_dialogue_index += 1
	if _dialogue_index >= _dialogue_lines.size():
		_close_dialogue()
		return
	dialogue_text.text = _dialogue_lines[_dialogue_index]
	continue_hint.text = "[Shift / Spacja] Dalej" if _dialogue_index < _dialogue_lines.size() - 1 else "[Shift / Spacja] Zamknij"


func _on_choice_pressed(index: int) -> void:
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


func _on_restart_pressed() -> void:
	restart_requested.emit()
