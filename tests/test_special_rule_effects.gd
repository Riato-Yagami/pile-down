extends SceneTree

const PileScene := preload("res://resources/scenes/Pile.tscn")
const CardScene := preload("res://resources/scenes/Card.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Control.new()
	root.add_child(stage)

	var down_pile := PileScene.instantiate() as MemoryPile
	stage.add_child(down_pile)
	down_pile.setup(0, 5, RoundModifiers.StackDirection.DOWN, false)
	assert(down_pile.current_value == 5)
	assert(down_pile.expected_value() == 4)
	assert(down_pile.can_accept(4))
	down_pile.place(4)
	assert(not down_pile.is_complete_value())
	down_pile.enable_regeneration(1.0)
	assert(down_pile.regeneration_ring != null)
	assert(is_equal_approx(down_pile.regeneration_ring.ratio, 1.0))
	assert(not down_pile.regeneration_ring.visible)
	await down_pile.hide_value(false)
	assert(down_pile.regeneration_ring.visible)
	await down_pile.reveal_value_temporarily(0.01)
	assert(not down_pile.face_up)
	down_pile.current_value = down_pile.start_value
	down_pile._refresh()
	assert(not down_pile.regeneration_ring.visible)
	down_pile.disable_regeneration()

	var up_pile := PileScene.instantiate() as MemoryPile
	stage.add_child(up_pile)
	up_pile.setup(1, 5, RoundModifiers.StackDirection.UP, true)
	assert(up_pile.current_value == 0)
	assert(up_pile.expected_value() == 1)
	assert(up_pile.can_accept(1))
	up_pile.place(1)
	assert(up_pile.value_label.text == "I")
	up_pile.current_value = 5
	assert(up_pile.is_complete_value())

	var peek_card := CardScene.instantiate() as PlayingCard
	stage.add_child(peek_card)
	peek_card.setup(4, true, true, true)
	assert(not peek_card.face_up)
	await peek_card.flip_up(false)
	assert(peek_card.face_up)
	assert(peek_card.value_label.text == "IV")
	var original_y := peek_card.position.y
	for iteration in 4:
		await peek_card.flip_down(true)
		await peek_card.flip_up(true)
		assert(is_equal_approx(peek_card.position.y, original_y))

	stage.queue_free()
	print("Special Rule effect tests passed.")
	quit()
