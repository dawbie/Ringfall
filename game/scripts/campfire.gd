extends Interactable
## Safe campfire resting point that restores Frodo's health.

@export var heal_amount: int = 100

var _flicker_time: float = 0.0
@onready var flame_outer: Polygon2D = $FlameOuter
@onready var flame_inner: Polygon2D = $FlameInner


func _process(delta: float) -> void:
	_flicker_time += delta * 9.0
	var s := 1.0 + 0.14 * sin(_flicker_time)
	flame_outer.scale = Vector2(1.0, s)
	flame_inner.scale = Vector2(1.0 + 0.1 * cos(_flicker_time * 1.3), 1.0 + 0.18 * cos(_flicker_time))


func _on_interacted(player: Player) -> void:
	player.heal(heal_amount)
	player.restore_sanity(100.0)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("show_toast"):
		hud.show_toast("Odpoczynek przy ognisku: zdrowie i wola odnowione!")
