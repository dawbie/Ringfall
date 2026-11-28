extends Node
## Global run state for Ringfall.
## Tracks the hidden Ring corruption level, defeated enemies, and collected gold across scenes.

signal gold_changed(new_gold: int)

var ring_corruption: int = 0
var ring_uses: int = 0
var enemies_killed: int = 0
var total_enemies_in_level: int = 0
var gold: int = 0


func add_ring_corruption(amount: int = 1) -> void:
	ring_corruption += maxi(0, amount)
	ring_uses += 1


func register_enemy_kill() -> void:
	enemies_killed += 1


func add_gold(amount: int) -> void:
	gold += maxi(0, amount)
	gold_changed.emit(gold)


func reset_run() -> void:
	ring_corruption = 0
	ring_uses = 0
	enemies_killed = 0
	total_enemies_in_level = 0
	gold = 0
	gold_changed.emit(gold)
