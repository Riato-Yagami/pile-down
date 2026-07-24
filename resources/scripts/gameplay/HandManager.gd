class_name HandManager
extends Node

signal card_selected(card)
signal card_drag_started(card)
signal card_drag_released(card, release_position)
signal card_entered_screen(card)

@export var card_scene: PackedScene
var rng := RandomNumberGenerator.new()
var current_cards: Array[PlayingCard] = []


func _ready() -> void:
	rng.randomize()


func generate_hand(
	container: Control,
	hand_size: int,
	start_value: int,
	playable_values: Array[int],
	pile_up := false,
	hover_reveal := false,
	use_roman_numerals := false,
	animate_draw := true,
	clear_existing := true,
	enter_from_right := false
) -> void:
	if clear_existing:
		clear_hand(container)
	if playable_values.is_empty():
		return

	var guaranteed_value := playable_values[rng.randi_range(0, playable_values.size() - 1)]
	var values: Array[int] = []
	for i in hand_size:
		values.append(rng.randi_range(1 if pile_up else 0, start_value if pile_up else start_value - 1))
	var guaranteed_position := rng.randi_range(0, hand_size - 1)
	values[guaranteed_position] = guaranteed_value

	for value in values:
		var card := card_scene.instantiate() as PlayingCard
		container.add_child(card)
		card.setup(value, true, hover_reveal, use_roman_numerals)
		card.card_selected.connect(_on_card_selected)
		card.drag_started.connect(func(dragged_card: PlayingCard) -> void: card_drag_started.emit(dragged_card))
		card.drag_released.connect(
			func(dragged_card: PlayingCard, release_position: Vector2) -> void:
				card_drag_released.emit(dragged_card, release_position)
		)
		card.entrance_became_interactive.connect(
			func(entered_card: PlayingCard) -> void:
				card_entered_screen.emit(entered_card)
		)
		current_cards.append(card)
		if animate_draw:
			if enter_from_right:
				card.call_deferred("play_draw_from_right", (current_cards.size() - 1) * 0.045)
			else:
				card.call_deferred("play_draw", (current_cards.size() - 1) * 0.045)


func discard_hand(_container: Control, exit_layer: Control = null) -> void:
	var cards_to_discard: Array[PlayingCard] = []
	for card in current_cards:
		if is_instance_valid(card) and card.visible:
			card.disable_wandering()
			if exit_layer != null and card.get_parent() != exit_layer:
				var previous_global_position := card.global_position
				card.reparent(exit_layer, false)
				card.global_position = previous_global_position
			cards_to_discard.append(card)
	current_cards.clear()
	if cards_to_discard.is_empty():
		return

	var longest_duration := 0.0
	for index in cards_to_discard.size():
		var card := cards_to_discard[index]
		card.finish_drag()
		card.set_selectable(false)
		var delay := index * 0.04
		if card.free_range_card:
			longest_duration = maxf(
				longest_duration,
				card.play_wandering_exit(card.get_viewport_rect().size.x, delay)
			)
			continue
		longest_duration = delay + 0.26
		var tween := card.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_interval(delay)
		tween.tween_property(
			card,
			"global_position:y",
			card.get_viewport_rect().size.y + card.size.y + 12.0,
			0.26
		)
		tween.parallel().tween_property(card, "modulate:a", 0.0, 0.2)
	await get_tree().create_timer(longest_duration).timeout
	for card in cards_to_discard:
		if is_instance_valid(card):
			card.queue_free()


func clear_hand(container: Control) -> void:
	current_cards.clear()
	for child in container.get_children():
		child.queue_free()


func lock_hand() -> void:
	for card in current_cards:
		if is_instance_valid(card):
			card.set_selectable(false)


func unlock_hand() -> void:
	for card in current_cards:
		if is_instance_valid(card) and card.visible:
			card.set_selectable(true)


func clear_selection() -> void:
	for card in current_cards:
		if is_instance_valid(card):
			card.set_selected_visual(false)


func select_card(selected_card: PlayingCard) -> void:
	for card in current_cards:
		if is_instance_valid(card):
			card.set_selected_visual(card == selected_card)


func _on_card_selected(card: PlayingCard) -> void:
	select_card(card)
	card_selected.emit(card)
