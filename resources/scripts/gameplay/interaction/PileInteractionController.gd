class_name PileInteractionController
extends RefCounted

## Mouse/touch pile dragging and collision-constrained placement.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func on_pile_drag_requested(
	host: GameManager, pile: MemoryPile, pointer_position: Vector2
) -> void:
	if (
		host.input_locked
		or not host.bonus_manager.has_bonus(&"pile_mover")
		or host.selected_card != null
		or pile.completed
		or host.moving_pile != null
	):
		return
	host.moving_pile = pile
	host._pile_touch_index = -1
	host._moving_pile_pointer = pointer_position
	host._moving_pile_offset = pointer_position - pile.global_position
	host._moving_pile_last_valid_position = pile.position
	host.special_rule_manager.moving_pile_pattern.begin_manual_move(pile)
	pile.move_to_front()


static func on_pile_drag_released(
	host: GameManager, pile: MemoryPile, pointer_position: Vector2
) -> void:
	if pile == host.moving_pile:
		host._moving_pile_pointer = pointer_position
		host.moving_pile.global_position = (
			pointer_position - host._moving_pile_offset
		).round()
		host._finish_pile_move()


static func finish_pile_move(host: GameManager) -> void:
	if host.moving_pile == null or not is_instance_valid(host.moving_pile):
		host.moving_pile = null
		host._pile_touch_index = -1
		return
	var requested_position := host.moving_pile.position
	host.moving_pile.position = host._nearest_valid_pile_position(
		host.moving_pile,
		requested_position,
		host._moving_pile_last_valid_position
	)
	host.pile_manager.refresh_slots_from_current_positions()
	host.special_rule_manager.moving_pile_pattern.finish_manual_move(host.moving_pile)
	host.moving_pile = null
	host._pile_touch_index = -1


static func nearest_valid_pile_position(
	host: GameManager,
	pile: MemoryPile,
	requested_position: Vector2,
	fallback_position: Vector2
) -> Vector2:
	var movement_bounds := host._pile_movement_bounds(pile)
	var minimum := movement_bounds.position
	var maximum := movement_bounds.end
	var clamped_request := Vector2(
		clampf(requested_position.x, minimum.x, maximum.x),
		clampf(requested_position.y, minimum.y, maximum.y)
	)
	pile.position = clamped_request.round()
	if host._is_valid_pile_position(pile):
		return pile.position

	# A coarse board-wide pass finds the closest legal region without making
	# release time depend on the distance from an invalid drop. The local
	# pixel pass below then removes the small grid approximation.
	const SEARCH_STEP := 4
	var found := false
	var best_position := fallback_position
	var best_distance_squared := INF
	for y in range(floori(minimum.y), ceili(maximum.y) + 1, SEARCH_STEP):
		for x in range(floori(minimum.x), ceili(maximum.x) + 1, SEARCH_STEP):
			var candidate := Vector2(x, y)
			var distance_squared := candidate.distance_squared_to(clamped_request)
			if distance_squared >= best_distance_squared:
				continue
			pile.position = candidate
			if host._is_valid_pile_position(pile):
				found = true
				best_position = candidate
				best_distance_squared = distance_squared

	if found:
		var refine_minimum := (best_position - Vector2.ONE * SEARCH_STEP).max(minimum)
		var refine_maximum := (best_position + Vector2.ONE * SEARCH_STEP).min(maximum)
		for y in range(floori(refine_minimum.y), ceili(refine_maximum.y) + 1):
			for x in range(floori(refine_minimum.x), ceili(refine_maximum.x) + 1):
				var candidate := Vector2(x, y)
				var distance_squared := candidate.distance_squared_to(clamped_request)
				if distance_squared >= best_distance_squared:
					continue
				pile.position = candidate
				if host._is_valid_pile_position(pile):
					best_position = candidate
					best_distance_squared = distance_squared
		return best_position

	pile.position = fallback_position
	return fallback_position


static func pile_movement_bounds(host: GameManager, pile: MemoryPile) -> Rect2:
	# PilesBoard is a direct child of the game Control and does not clip its
	# children. Negative/local positions therefore safely expose the margins
	# around the original compact board.
	const SCREEN_MARGIN := 2.0
	var minimum := -host.piles_board.position + Vector2.ONE * SCREEN_MARGIN
	var maximum := (
		host.size
		- host.piles_board.position
		- pile.size
		- Vector2.ONE * SCREEN_MARGIN
	)
	return Rect2(minimum, (maximum - minimum).max(Vector2.ZERO))


static func is_valid_pile_position(host: GameManager, pile: MemoryPile) -> bool:
	var candidate_rect := host._transformed_control_rect(pile)
	var screen_rect := host._transformed_control_rect(host).grow(-2.0)
	if not screen_rect.encloses(candidate_rect):
		return false
	var forbidden_controls: Array[Control] = [
		host.hand_tray,
	]
	for forbidden in forbidden_controls:
		if (
			forbidden.visible
			and candidate_rect.intersects(host._transformed_control_rect(forbidden))
		):
			return false
	for other in host.piles:
		if not is_instance_valid(other) or other == pile or other.completed:
			continue
		var center := candidate_rect.get_center()
		var other_center := host._transformed_control_rect(other).get_center()
		if center.distance_to(other_center) < host.Difficulty.MINIMUM_PILE_DISTANCE:
			return false
	if host.round_modifiers.floor_is_lava_enabled and host.lava_rule_controller.touches_rect(candidate_rect):
		return false
	return true


static func handle_pile_touch_input(host: GameManager, event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if host.moving_pile != null:
				return host._pile_touch_index == touch.index
			if (
				host.input_locked
				or not host.bonus_manager.has_bonus(&"pile_mover")
				or host.selected_card != null
			):
				return false
			var touched_pile := host._pile_at(touch.position)
			if touched_pile == null:
				return false
			host.moving_pile = touched_pile
			host._pile_touch_index = touch.index
			host._moving_pile_pointer = touch.position
			host._moving_pile_last_valid_position = touched_pile.position
			host._pile_touch_local_grab = (
				touched_pile.get_global_transform().affine_inverse()
				* touch.position
			)
			host.special_rule_manager.moving_pile_pattern.begin_manual_move(
				touched_pile
			)
			touched_pile.move_to_front()
			return true
		if (
			host.moving_pile != null
			and is_instance_valid(host.moving_pile)
			and host._pile_touch_index == touch.index
		):
			host._update_touch_pile_position(touch.position)
			host._finish_pile_move()
			return true
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if (
			host.moving_pile != null
			and is_instance_valid(host.moving_pile)
			and host._pile_touch_index == drag.index
		):
			host._update_touch_pile_position(drag.position)
			return true
	return false


static func update_touch_pile_position(host: GameManager, pointer_position: Vector2) -> void:
	if host.moving_pile == null or not is_instance_valid(host.moving_pile):
		return
	host._moving_pile_pointer = pointer_position
	var parent_item := host.moving_pile.get_parent() as CanvasItem
	if parent_item == null:
		return
	var pointer_in_parent := (
		parent_item.get_global_transform().affine_inverse()
		* pointer_position
	)
	var grab_offset := host.moving_pile.get_transform().basis_xform(
		host._pile_touch_local_grab
	)
	host.moving_pile.position = pointer_in_parent - grab_offset
