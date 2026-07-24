class_name HandManager
extends Node

signal card_selected(card)
signal card_drag_started(card)
signal card_drag_released(card, release_position)

@export var card_scene: PackedScene
var rng := RandomNumberGenerator.new()
var current_cards: Array[PlayingCard] = []


func _ready() -> void:
	rng.randomize()


func generate_hand(container: Container, hand_size: int, start_value: int, playable_values: Array[int]) -> void:
	clear_hand(container)
	if playable_values.is_empty():
		return

	var guaranteed_value := playable_values[rng.randi_range(0, playable_values.size() - 1)]
	var values: Array[int] = []
	for i in hand_size:
		values.append(rng.randi_range(0, start_value - 1))
	var guaranteed_position := rng.randi_range(0, hand_size - 1)
	values[guaranteed_position] = guaranteed_value

	for value in values:
		var card := card_scene.instantiate() as PlayingCard
		container.add_child(card)
		card.setup(value, true)
		card.card_selected.connect(_on_card_selected)
		card.drag_started.connect(func(dragged_card: PlayingCard) -> void: card_drag_started.emit(dragged_card))
		card.drag_released.connect(
			func(dragged_card: PlayingCard, release_position: Vector2) -> void:
				card_drag_released.emit(dragged_card, release_position)
		)
		current_cards.append(card)
		card.call_deferred("play_draw", (current_cards.size() - 1) * 0.045)


func discard_hand(container: Container) -> void:
	var cards_to_discard: Array[PlayingCard] = []
	for card in current_cards:
		if is_instance_valid(card) and card.get_parent() == container and card.visible:
			cards_to_discard.append(card)
	current_cards.clear()
	if cards_to_discard.is_empty():
		return

	var longest_duration := 0.0
	for index in cards_to_discard.size():
		var card := cards_to_discard[index]
		card.set_selectable(false)
		var delay := index * 0.04
		longest_duration = delay + 0.18
		var tween := card.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_interval(delay)
		tween.tween_property(card, "position:y", card.position.y + 12.0, 0.18)
		tween.parallel().tween_property(card, "modulate:a", 0.0, 0.14)
	await get_tree().create_timer(longest_duration).timeout
	for card in cards_to_discard:
		if is_instance_valid(card):
			card.queue_free()


func clear_hand(container: Container) -> void:
	current_cards.clear()
	for child in container.get_children():
		child.queue_free()


func lock_hand() -> void:
	for card in current_cards:
		if is_instance_valid(card):
			card.set_selectable(false)


func select_card(selected_card: PlayingCard) -> void:
	for card in current_cards:
		if is_instance_valid(card):
			card.set_selected_visual(card == selected_card)


func _on_card_selected(card: PlayingCard) -> void:
	select_card(card)
	card_selected.emit(card)
