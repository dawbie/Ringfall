extends Interactable
## Ancient crossroads shrine offering a moral/tactical choice for the run.

var _target_player: Player = null
@onready var rune_glow: Polygon2D = $RuneGlow


func _ready() -> void:
	one_shot = false
	super._ready()


func _process(_delta: float) -> void:
	if _used:
		rune_glow.visible = false
	else:
		var pulse := 0.55 + 0.35 * sin(Time.get_ticks_msec() * 0.005)
		rune_glow.modulate.a = pulse


func _on_interacted(player: Player) -> void:
	_target_player = player
	AudioManager.play_sfx(&"dialogue_blip", -3.0, 0.95, 1.05)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("start_choice_dialogue"):
		hud.start_choice_dialogue(
			"Pradawna Kapliczka",
			"Kamienny oltarz emanuje starym swiatlem. W poblizu czai sie tez szept Pierscienia...",
			PackedStringArray([
				"Blogoslawienstwo swiatla (+30 HP, +4 do ataku)",
				"Przyjmij szept cienia (+10 do ataku)"
			]),
			_on_choice_selected
		)


func _on_choice_selected(choice_index: int) -> void:
	if _used:
		return
	_used = true
	one_shot = true
	set_highlighted(false)
	if _target_player == null or not is_instance_valid(_target_player):
		return

	var hud := get_tree().get_first_node_in_group("hud")
	if choice_index == 0:
		AudioManager.play_sfx(&"shrine_light", -1.0, 0.98, 1.02)
		_target_player.heal(30)
		_target_player.restore_sanity(35.0)
		_target_player.add_bonus_damage(4)
		if hud != null and hud.has_method("show_toast"):
			hud.show_toast("Swiatlo wzmacnia: +30 HP, +35 Woli, +4 DMG!")
	else:
		AudioManager.play_sfx(&"shrine_shadow", -1.0, 0.98, 1.02)
		_target_player.add_bonus_damage(10)
		_target_player.drain_sanity(20.0)
		GameState.add_ring_corruption(1)
		if hud != null and hud.has_method("show_toast"):
			hud.show_toast("Cien wyostrza miecz (+10 DMG), lecz maci umysl!")
