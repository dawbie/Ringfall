extends Node
## Global run state for Ringfall.
## Tracks the hidden Ring corruption level silently across scenes without exposing it in UI.

var ring_corruption: int = 0
var ring_uses: int = 0


func add_ring_corruption(amount: int = 1) -> void:
	ring_corruption += maxi(0, amount)
	ring_uses += 1


func reset_run() -> void:
	ring_corruption = 0
	ring_uses = 0
