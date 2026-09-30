class_name CardClickController
extends RefCounted

var _pressed_card: PlayingCard
var _press_position := Vector2.ZERO
var _moved := false


func reset(host: GameManager = null) -> void:
	if host != null and is_instance_valid(_pressed_card):
		DiscardPlayController.cancel_claim(host, _pressed_card)
	_pressed_card = null
	_moved = false


func handle_input(host: GameManager, event: InputEvent) -> bool:
	if host.splash.visible or host.overlay.visible or host.quit_popup.visible:
		reset(host)
		return false
	# A selected tile takes priority over the optional pile-moving gesture.
	var press: bool = (
		(event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
		or (event is InputEventScreenTouch and event.pressed)
	)
	if press and host._card_touch_index < 0 and not is_instance_valid(_pressed_card):
		var card := host.selected_card
		if is_instance_valid(card) and card._selected and not card.dragging:
			var pile := host._pile_at(event.position)
			if pile != null:
				host._on_pile_selected(pile)
				return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_instance_valid(host.selected_card) and host.selected_card.dragging:
				return false
			var card := host._card_at_touch_position(event.position)
			if card == null or (host.input_locked and not DiscardPlayController.can_interact(host, card)):
				return false
			if not DiscardPlayController.claim_on_press(host, card):
				return true
			_pressed_card = card
			_press_position = event.position
			_moved = false
			return true
		if is_instance_valid(_pressed_card):
			var card := _pressed_card
			_pressed_card = null
			if host._click_to_place_enabled and not _moved and host._card_at_touch_position(event.position) == card:
				select_on_tap(host, card)
			else:
				DiscardPlayController.cancel_claim(host, card)
			return true
	elif event is InputEventMouseMotion and is_instance_valid(_pressed_card):
		if not event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			reset(host)
			return false
		_moved = _moved or _press_position.distance_to(event.position) >= _pressed_card.touch_drag_distance
		if _moved and host._drag_and_drop_enabled:
			var card := _pressed_card
			_pressed_card = null
			card.drag_target = _press_position
			host._on_card_drag_started(card)
			card.drag_target = event.position
		return true
	return false


static func select_on_tap(host: GameManager, card: PlayingCard) -> void:
	if not host._click_to_place_enabled or not is_instance_valid(card):
		return
	if host.input_locked and not DiscardPlayController.can_interact(host, card):
		return
	host._on_card_selected(card)
	if host.selected_card == card:
		host.hand_manager.select_card(card)


static func place_on_pile(host: GameManager, pile: MemoryPile) -> void:
	var card := host.selected_card
	if not host._click_to_place_enabled or not is_instance_valid(card) or not card._selected:
		return
	# Reuse the drag placement path, including companions, discards and mistakes.
	card.drag_target = card.get_global_rect().get_center()
	host._on_card_drag_started(card)
	if card.dragging:
		host._on_card_drag_released(card, pile.get_global_rect().get_center())
