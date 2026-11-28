extends Interactable
## Friendly NPC (Sam) providing guidance and lore at the start of the path.

@export var speaker_name: String = "Sam"
@export var dialogue_lines: PackedStringArray = PackedStringArray([
	"Frodo, przed nami Zmierzchowe Ruiny. Droge do bramy blokuja orki i ich ciezkozbrojny Straznik.",
	"Pamietaj: unik [X] chroni przed ciosem, a szybkie ciecie z uniku [X -> Z] pozwala zajsc wroga od tylu.",
	"Pierscien [C] ukryje Cie przed orkami, ale oslabia Twoja Wole. W razie czego wroc do ogniska, by odzyskac sily."
])

var _idle_time: float = 0.0
@onready var visual_rig: Node2D = $VisualRig


func _process(delta: float) -> void:
	_idle_time += delta * 3.0
	visual_rig.scale = Vector2(1.0 + 0.02 * sin(_idle_time), 1.0 - 0.02 * sin(_idle_time))


func _on_interacted(_player: Player) -> void:
	AudioManager.play_sfx(&"dialogue_blip", -2.5, 0.96, 1.04)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("start_dialogue"):
		hud.start_dialogue(speaker_name, dialogue_lines)
