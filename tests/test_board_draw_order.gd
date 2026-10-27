extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := preload("res://resources/scenes/Main.tscn").instantiate()
	root.add_child(main)
	var game := main.get_node("GameCenter/Game") as GameManager
	var background := main.get_node("Background") as ColorRect
	var artwork := game.get_node("Artwork") as Control
	assert(background.z_index < artwork.z_index,
		"The main scene's opaque fill must remain behind the animated artwork")
	for rule in [&"snake", &"free_range_cards"]:
		var modifiers := RoundModifiers.new()
		modifiers.snake_enabled = rule == &"snake"
		modifiers.wandering_hand_cards = rule == &"free_range_cards"
		var card := preload("res://resources/scenes/gameplay/Card.tscn").instantiate() as PlayingCard
		game.drag_layer.add_child(card)
		card.setup(2, true, false, false, modifiers)
		assert(card.z_index > artwork.z_index)
		assert(card.z_index > background.z_index)
		assert(card.z_index < 0, "Resting tiles must stay beneath the piles")
		card.set_selected_visual(true)
		assert(card.z_index > artwork.z_index and card.z_index < 0)
		card.keep_attached_to_pointer()
		assert(card.z_index > 20, "Dragged tiles must pass above the snake head")
		card.finish_drag()
		assert(card.z_index > artwork.z_index and card.z_index < 0)
		card.queue_free()
	main.queue_free()
	await process_frame
	print("Board draw order tests passed: full main scene, background, resting tiles and drags.")
	quit()
