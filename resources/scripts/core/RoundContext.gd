class_name RoundContext
extends RefCounted

var round_number := 1
var modifiers: RoundModifiers
var piles: Array[MemoryPile] = []
var game_manager: GameManager
var hand_manager: HandManager
var pile_manager: PileManager
var timer_manager: CountdownManager
var interface: Control
var rng: RandomNumberGenerator


func _init(current_round: int, round_modifiers: RoundModifiers) -> void:
	round_number = current_round
	modifiers = round_modifiers
	rng = RandomNumberGenerator.new()
	rng.randomize()
