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
			_on_restart_pressed()


func _on_restart_pressed() -> void:
	restart_requested.emit()
