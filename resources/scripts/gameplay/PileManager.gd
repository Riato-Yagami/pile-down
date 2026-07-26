class_name PileManager
extends Node

var layout_area: Control
var active_piles: Array[MemoryPile] = []
var pile_slots: Array[Vector2] = []
var _movement_tweens: Array[Tween] = []


func configure(
	board: Control,
	piles: Array[MemoryPile],
	slots: Array[Vector2]
) -> void:
	layout_area = board
	active_piles.assign(piles)
	pile_slots.assign(slots)


func rotate_active_piles(direction := 1, duration := 0.4) -> void:
	var perimeter_slots := _get_perimeter_slots()
	if perimeter_slots.size() < 2:
		return
	var movable_piles: Array[MemoryPile] = []
	var destination_positions: Array[Vector2] = []
	for pile in active_piles:
		if not is_instance_valid(pile) or pile.completed:
			continue
		var current_slot_index := _find_slot_index(perimeter_slots, pile.position)
		if current_slot_index >= 0:
			movable_piles.append(pile)
			var destination_index := posmod(
				current_slot_index + (1 if direction >= 0 else -1),
				perimeter_slots.size()
			)
			destination_positions.append(perimeter_slots[destination_index])
	if movable_piles.is_empty():
		return
	_movement_tweens.clear()
	var tween := (
		layout_area.create_tween()
		.set_parallel(true)
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_IN_OUT)
	)
	_movement_tweens.append(tween)
	for index in movable_piles.size():
		tween.tween_property(
			movable_piles[index],
			"position",
			destination_positions[index],
			duration
		)
	await tween.finished
	_movement_tweens.clear()


func _get_perimeter_slots() -> Array[Vector2]:
	var slots := pile_slots.duplicate()
	if slots.is_empty():
		for pile in active_piles:
			if is_instance_valid(pile):
				slots.append(pile.position)
	return _order_positions_around_perimeter(slots)


func _order_positions_around_perimeter(positions: Array[Vector2]) -> Array[Vector2]:
	var rows: Array[Array] = []
	var sorted_positions := positions.duplicate()
	sorted_positions.sort_custom(
		func(first: Vector2, second: Vector2) -> bool:
			if not is_equal_approx(first.y, second.y):
				return first.y < second.y
			return first.x < second.x
	)
	for position in sorted_positions:
		if rows.is_empty():
			rows.append([position])
			continue
		var current_row: Array = rows.back()
		var row_position := current_row[0] as Vector2
		if is_equal_approx(position.y, row_position.y):
			current_row.append(position)
		else:
			rows.append([position])

	if rows.size() <= 1:
		return sorted_positions

	var perimeter: Array[Vector2] = []
	for position_variant in rows.front():
		perimeter.append(position_variant as Vector2)
	for row_index in range(1, rows.size() - 1):
		var row: Array = rows[row_index]
		perimeter.append(row.back() as Vector2)
	var bottom_row: Array = rows.back()
	for index in range(bottom_row.size() - 1, -1, -1):
		perimeter.append(bottom_row[index] as Vector2)
	for row_index in range(rows.size() - 2, 0, -1):
		var row: Array = rows[row_index]
		var left_position := row.front() as Vector2
		if not perimeter.has(left_position):
			perimeter.append(left_position)
	return perimeter


func _find_slot_index(slots: Array[Vector2], position: Vector2) -> int:
	for index in slots.size():
		if slots[index].is_equal_approx(position):
			return index
	return -1


func _get_perimeter_piles() -> Array[MemoryPile]:
	var perimeter: Array[MemoryPile] = []
	for slot in _get_perimeter_slots():
		for pile in active_piles:
			if is_instance_valid(pile) and pile.position.is_equal_approx(slot):
				perimeter.append(pile)
				break
	return perimeter


func stop_all_movements() -> void:
	for tween in _movement_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_movement_tweens.clear()


func refresh_all_card_themes(colorblind_enabled: bool) -> void:
	for pile in active_piles:
		if is_instance_valid(pile):
			pile.set_colorblind_enabled(colorblind_enabled)
