class_name HandDragController
extends RefCounted

## Companion drags, touch input and stable hand-slot restoration.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func prepare_drag_companions(host: GameManager, main_card: PlayingCard) -> void:
	host.drag_companions.clear()
	host._companion_offsets.clear()
	host._companion_home_positions.clear()
	var level := host.bonus_manager.level(&"bring_a_friend")
	if level <= 0 or host.round_modifiers.wandering_hand_cards:
		return
	var cards := host.hand_manager.active_cards()
	var main_index := cards.find(main_card)
	if main_index < 0:
		return
	var candidates: Array[PlayingCard] = []
	if level == 1:
		if main_index + 1 < cards.size():
			candidates.append(cards[main_index + 1])
		elif main_index > 0:
			candidates.append(cards[main_index - 1])
	elif level == 2:
		if main_index > 0:
			candidates.append(cards[main_index - 1])
		if main_index + 1 < cards.size():
			candidates.append(cards[main_index + 1])
	else:
		for card in cards:
			if card != main_card:
				candidates.append(card)
	for index in candidates.size():
		var companion := candidates[index]
		host._companion_home_positions[companion] = companion.hand_return_position()
		host._create_hand_slot_placeholder(companion)
		companion.set_selectable(false)
		companion.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var start_position := companion.global_position
		companion.reparent(host.drag_layer, false)
		companion.global_position = start_position
		host.drag_layer.move_child(companion, 0)
		host.drag_companions.append(companion)
		var centered_x := (float(index) - float(candidates.size() - 1) * 0.5) * 23.0
		host._companion_offsets[companion] = Vector2(centered_x, 16.0 + absf(centered_x) * 0.08)


static func resolve_companion_drops(
	host: GameManager, anchor_pile: MemoryPile
) -> Array[MemoryPile]:
	var placed_piles: Array[MemoryPile] = []
	var companions := host.drag_companions.duplicate()
	host.drag_companions.clear()
	for companion_variant in companions:
		var companion := companion_variant as PlayingCard
		if not is_instance_valid(companion) or companion.placement_confirmed:
			continue
		var target := host._find_nearby_companion_pile(
			companion, anchor_pile, placed_piles
		)
		if target != null:
			await host._stack_card(
				companion, target,
				PlacementContext.new(PlacementContext.Source.BRING_A_FRIEND, host._root_action_id)
			)
			placed_piles.append(target)
		else:
			await host._return_companion_to_hand(companion)
	host.hand_container.queue_sort()
	await host.get_tree().process_frame
	host._record_stable_hand_layout()
	host._companion_offsets.clear()
	host._companion_home_positions.clear()
	return placed_piles


static func find_nearby_companion_pile(
	host: GameManager,
	companion: PlayingCard,
	anchor_pile: MemoryPile,
	already_used: Array[MemoryPile]
) -> MemoryPile:
	if anchor_pile == null or not is_instance_valid(anchor_pile):
		return null
	var anchor_center := anchor_pile.global_position + anchor_pile.size * 0.5
	var compatible := host.pile_manager.find_piles_accepting_value(companion.card_value)
	compatible.erase(anchor_pile)
	for used_pile in already_used:
		compatible.erase(used_pile)
	compatible = compatible.filter(
		func(candidate: MemoryPile) -> bool:
			var candidate_center := candidate.global_position + candidate.size * 0.5
			return (
				candidate_center.distance_to(anchor_center)
				<= host.Difficulty.BRING_A_FRIEND_NEIGHBOR_RADIUS
			)
	)
	compatible.sort_custom(
		func(first: MemoryPile, second: MemoryPile) -> bool:
			var first_center := first.global_position + first.size * 0.5
			var second_center := second.global_position + second.size * 0.5
			var first_distance := first_center.distance_squared_to(anchor_center)
			var second_distance := second_center.distance_squared_to(anchor_center)
			if is_equal_approx(first_distance, second_distance):
				return first.pile_index < second.pile_index
			return first_distance < second_distance
	)
	return compatible.front() if not compatible.is_empty() else null


static func return_drag_companions(host: GameManager) -> void:
	var companions := host.drag_companions.duplicate()
	host.drag_companions.clear()
	for companion_variant in companions:
		var companion := companion_variant as PlayingCard
		if is_instance_valid(companion):
			await host._return_companion_to_hand(companion)
	host.hand_container.queue_sort()
	await host.get_tree().process_frame
	host._record_stable_hand_layout()
	host._companion_offsets.clear()
	host._companion_home_positions.clear()


static func return_companion_to_hand(host: GameManager, card: PlayingCard) -> void:
	var destination := (
		host._companion_home_positions.get(card, card.hand_return_position()) as Vector2
	)
	var placeholder := host._valid_hand_slot_placeholder(card)
	var slot_index := (
		placeholder.get_index()
		if is_instance_valid(placeholder) and placeholder.get_parent() == host.hand_container
		else -1
	)
	await card.animate_return(destination, 0.2)
	host._remove_hand_slot_placeholder(card)
	card.reparent(host.hand_container, false)
	if slot_index >= 0:
		host.hand_container.move_child(card, mini(slot_index, host.hand_container.get_child_count() - 1))
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.reset_hand_pose()
	card.set_selectable(not host.input_locked)


static func handle_card_touch_input(host: GameManager, event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if host.selected_card != null and is_instance_valid(host.selected_card):
				if (
					host.challenge_modifiers.commit_selected_cards
					and host.selected_card.drag_state == PlayingCard.DragState.LOCKED_OUT
				):
					host._card_touch_index = touch.index
					host.selected_card.touch_index = touch.index
					host.selected_card.drag_state = PlayingCard.DragState.DRAGGING
					host.selected_card.update_touch_drag(touch.position)
					return true
				return host._card_touch_index == touch.index
			if host.input_locked:
				return false
			var touched_card := host._card_at_touch_position(touch.position)
			if touched_card == null:
				return false
			host._card_touch_index = touch.index
			touched_card.drag_target = touch.position
			host._on_card_selected(touched_card)
			touched_card.begin_touch_interaction(touch.index, touch.position)
			return true
		if (
			host.selected_card != null
			and is_instance_valid(host.selected_card)
			and host._card_touch_index == touch.index
		):
			if host.selected_card.dragging:
				host.selected_card.update_touch_drag(touch.position)
				host._on_card_drag_released(host.selected_card, touch.position)
			else:
				host.selected_card.update_touch_interaction(touch.position)
				host.selected_card.finish_touch_tap()
				host._card_touch_index = -1
				host.selected_card = null
				host.hand_manager.clear_selection()
			return true
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if (
			host.selected_card != null
			and is_instance_valid(host.selected_card)
			and host._card_touch_index == drag.index
		):
			if host.selected_card.dragging:
				host.selected_card.update_touch_drag(drag.position)
			else:
				host.selected_card.update_touch_interaction(drag.position)
				host._try_start_touch_card_drag()
			return true
	return false


static func try_start_touch_card_drag(host: GameManager) -> void:
	if (
		host._card_touch_index < 0
		or host.selected_card == null
		or not is_instance_valid(host.selected_card)
		or host.selected_card.dragging
		or not host.selected_card.touch_drag_is_ready()
	):
		return
	host.selected_card.drag_target = host.selected_card.touch_position
	host._on_card_drag_started(host.selected_card, true)
	if host.selected_card.dragging:
		host.selected_card.update_touch_drag(host.selected_card.touch_position)


static func card_at_touch_position(host: GameManager, touch_position: Vector2) -> PlayingCard:
	for index in range(host.hand_manager.current_cards.size() - 1, -1, -1):
		var card := host.hand_manager.current_cards[index]
		if (
			not is_instance_valid(card)
			or not card.visible
			or not card.selectable
			or card.placement_confirmed
		):
			continue
		var local_point := (
			card.get_global_transform().affine_inverse()
			* touch_position
		)
		if Rect2(Vector2.ZERO, card.size).has_point(local_point):
			return card
	return null


static func transformed_control_rect(host: GameManager, control: Control) -> Rect2:
	var transform := control.get_global_transform()
	var corners: Array[Vector2] = [
		transform * Vector2.ZERO,
		transform * Vector2(control.size.x, 0.0),
		transform * control.size,
		transform * Vector2(0.0, control.size.y),
	]
	var minimum := corners[0]
	var maximum := corners[0]
	for corner in corners:
		minimum = minimum.min(corner)
		maximum = maximum.max(corner)
	return Rect2(minimum, maximum - minimum)


static func return_card_to_hand(host: GameManager, card: PlayingCard, duration := 0.26) -> void:
	if host.challenge_modifiers.conveyor_hand:
		card.end_commit()
		host._return_card_to_conveyor(card)
		card.set_selectable(not host.input_locked)
		return
	var destination := card.hand_return_position()
	await card.animate_return(destination, duration)
	if host.round_modifiers.wandering_hand_cards:
		host._clear_drag_placeholder()
		card.scale = Vector2.ONE
		card.set_selectable(not host.input_locked)
		card.enable_wandering(maxi(host.hand_manager.current_cards.find(card), 0), true)
		return
	# Remove the spacer synchronously before putting the card back. Otherwise
	# both controls occupy the HBox for one frame and rapid drags can capture
	# that transient, shifted layout as a new home position.
	host._clear_drag_placeholder()
	card.reparent(host.hand_container, false)
	host._restore_hand_child_order()
	host.hand_container.queue_sort()
	await host.get_tree().process_frame
	card.reset_hand_pose()
	card.position.y = 0.0
	card.record_hand_position()
	card.set_selectable(not host.input_locked)
	if host.round_modifiers.wandering_hand_cards:
		card.call_deferred("enable_wandering", maxi(card.get_index(), 0))


static func clear_drag_placeholder(host: GameManager) -> void:
	if is_instance_valid(host.drag_placeholder):
		var placeholder_card_id := 0
		for card_id in host._hand_slot_placeholders:
			var stored_placeholder: Variant = host._hand_slot_placeholders[card_id]
			if (
				is_instance_valid(stored_placeholder)
				and stored_placeholder == host.drag_placeholder
			):
				placeholder_card_id = int(card_id)
				break
		if placeholder_card_id != 0:
			host._hand_slot_placeholders.erase(placeholder_card_id)
		if host.drag_placeholder.get_parent() != null:
			host.drag_placeholder.get_parent().remove_child(host.drag_placeholder)
		host.drag_placeholder.queue_free()
	host.drag_placeholder = null
	host.drag_home_index = -1


static func create_hand_slot_placeholder(host: GameManager, card: PlayingCard) -> Control:
	var existing := host._valid_hand_slot_placeholder(card)
	if existing != null:
		return existing
	var placeholder := Control.new()
	placeholder.name = "HandSlotPlaceholder"
	placeholder.set_meta(&"hand_drag_placeholder", true)
	placeholder.custom_minimum_size = card.size
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var slot_index := card.get_index()
	host.hand_container.add_child(placeholder)
	host.hand_container.move_child(placeholder, slot_index)
	host._hand_slot_placeholders[card.get_instance_id()] = placeholder
	return placeholder


static func remove_hand_slot_placeholder(host: GameManager, card: PlayingCard) -> void:
	var placeholder := host._valid_hand_slot_placeholder(card)
	host._hand_slot_placeholders.erase(card.get_instance_id())
	if placeholder == null:
		return
	if placeholder == host.drag_placeholder:
		host.drag_placeholder = null
		host.drag_home_index = -1
	if placeholder.get_parent() != null:
		placeholder.get_parent().remove_child(placeholder)
	placeholder.queue_free()


static func valid_hand_slot_placeholder(host: GameManager, card: PlayingCard) -> Control:
	var placeholder_variant: Variant = host._hand_slot_placeholders.get(
		card.get_instance_id()
	)
	if not is_instance_valid(placeholder_variant):
		return null
	return placeholder_variant as Control


static func clear_all_hand_slot_placeholders(host: GameManager) -> void:
	for placeholder_variant in host._hand_slot_placeholders.values():
		if not is_instance_valid(placeholder_variant):
			continue
		var placeholder := placeholder_variant as Control
		if placeholder.get_parent() != null:
			placeholder.get_parent().remove_child(placeholder)
		placeholder.queue_free()
	host._hand_slot_placeholders.clear()
	host.drag_placeholder = null
	host.drag_home_index = -1


static func remove_orphan_drag_placeholders(host: GameManager) -> void:
	for child in host.hand_container.get_children():
		if (
			child != host.drag_placeholder
			and child.has_meta(&"hand_drag_placeholder")
		):
			host.hand_container.remove_child(child)
			child.queue_free()
	host._hand_slot_placeholders.clear()
	if is_instance_valid(host.drag_placeholder) and host.selected_card != null:
		host._hand_slot_placeholders[host.selected_card.get_instance_id()] = host.drag_placeholder
	host.hand_container.queue_sort()


static func restore_hand_child_order(host: GameManager) -> void:
	var child_index := 0
	for logical_card in host.hand_manager.current_cards:
		if not is_instance_valid(logical_card) or not logical_card.visible:
			continue
		if logical_card == host.selected_card and is_instance_valid(host.drag_placeholder):
			if host.drag_placeholder.get_parent() == host.hand_container:
				host.hand_container.move_child(host.drag_placeholder, child_index)
				child_index += 1
			continue
		if logical_card.get_parent() == host.hand_container:
			host.hand_container.move_child(logical_card, child_index)
			child_index += 1


static func record_stable_hand_layout(host: GameManager) -> void:
	for card in host.hand_manager.current_cards:
		if (
			is_instance_valid(card)
			and card.visible
			and card.get_parent() == host.hand_container
			and not card.dragging
		):
			card.record_hand_position()
