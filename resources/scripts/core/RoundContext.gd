class_name RoundContext
extends RefCounted

var round_number := 1
var modifiers: RoundModifiers
var piles: Array[MemoryPile] = []


func _init(current_round: int, round_modifiers: RoundModifiers) -> void:
	round_number = current_round
	modifiers = round_modifiers
