extends SceneTree

const HandManagerScript := preload(
	"res://resources/scripts/gameplay/HandManager.gd"
)


func _init() -> void:
	var manager := HandManagerScript.new() as HandManager
	manager.rng.seed = 7

	var level_one: Array[int] = [9, 9, 9]
	manager._apply_lucky_hand(level_one, [4, 2, 7], 0, false, 9, 1, 0, 0)
	assert(level_one == [2, 9, 9])

	var level_two: Array[int] = [9, 9]
	manager._apply_lucky_hand(level_two, [2, 4, 7], 0, false, 9, 2, 0, 0)
	assert(level_two == [2, 4])

	var double_down: Array[int] = [9, 9, 9]
	manager._apply_lucky_hand(double_down, [5, 8], 0, false, 9, 3, 2, 0)
	assert(double_down == [5, 4, 3])

	var shared_value: Array[int] = [9, 9, 9]
	manager._apply_lucky_hand(shared_value, [4, 4, 7], 0, false, 9, 3, 0, 0)
	assert(shared_value == [4, 7, 4])

	var deja_vu: Array[int] = [9, 9, 9]
	manager._apply_lucky_hand(deja_vu, [4, 4, 7], 0, false, 9, 3, 0, 1)
	assert(deja_vu == [4, 4, 7])

	var pile_up: Array[int] = [0, 0, 0]
	manager._apply_lucky_hand(pile_up, [3, 6, 6], 0, true, 9, 3, 2, 0)
	assert(pile_up == [6, 7, 8])

	var protected_joker: Array[int] = [8, 99, 8]
	var protected_slots: Array[int] = [1]
	manager._apply_lucky_hand(
		protected_joker, [4, 7], 0, false, 9, 3, 2, 0,
		protected_slots
	)
	assert(protected_joker[1] == 99)
	assert(protected_joker[0] == 4)
	assert(protected_joker[2] == 3)

	assert(manager.get_most_advanced_value([5, 2, 8], false) == 2)
	assert(manager.get_most_advanced_value([5, 2, 8], true) == 8)
	assert(manager.get_most_shared_expected_value([4, 4, 7], false) == 4)
	var first_pile := MemoryPile.new()
	first_pile.current_value = 6
	var advanced_pile := MemoryPile.new()
	advanced_pile.current_value = 2
	var active_piles: Array[MemoryPile] = [first_pile, advanced_pile]
	assert(manager.get_most_advanced_pile(active_piles, false) == advanced_pile)
	assert(manager.get_most_advanced_pile(active_piles, true) == first_pile)

	first_pile.free()
	advanced_pile.free()
	manager.free()
	print("Lucky Hand tests passed.")
	quit()
