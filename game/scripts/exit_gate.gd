extends Interactable
## Exit archway at the end of the Borderland Ruins.
## Remains sealed until all real enemies (excluding sanity nightmares) are defeated.

signal gate_entered

var is_unlocked: bool = false
var _announced_unlock: bool = false

@onready var barrier_glow: Polygon2D = $BarrierGlow


func _ready() -> void:
	super._ready()
	_refresh_gate_state()


func _process(_delta: float) -> void:
	_refresh_gate_state()
	if is_unlocked:
		barrier_glow.color = Color(0.35, 0.88, 0.56, 0.35 + 0.12 * sin(Time.get_ticks_msec() * 0.005))
	else:
		barrier_glow.color = Color(0.85, 0.24, 0.32, 0.42 + 0.15 * sin(Time.get_ticks_msec() * 0.007))


func _refresh_gate_state() -> void:
	var alive_guards := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if node.is_in_group("nightmares"):
			continue
		if "state" in node and int(node.get("state")) == Enemy.State.DEAD:
			continue
		alive_guards += 1

	var now_unlocked := alive_guards == 0
	if now_unlocked and not is_unlocked and not _announced_unlock:
		_announced_unlock = true
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null and hud.has_method("show_toast"):
			hud.show_toast("Straznik Bramy pokonany! Przejscie otwarte.", 2.2)

	is_unlocked = now_unlocked
	prompt_text = "[Shift] Przejdz przez brame" if is_unlocked else "[Shift] Brama zapieczetowana"
	if _highlighted:
		set_highlighted(true)


func _on_interacted(_player: Player) -> void:
	if not is_unlocked:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null and hud.has_method("show_toast"):
			hud.show_toast("Pokonaj wszystkich orkow i Straznika Bramy!", 1.8)
		return

	gate_entered.emit()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("show_toast"):
		hud.show_toast("Lokacja ukonczona! (Ekran podsumowania w kolejnym kroku)", 2.2)
