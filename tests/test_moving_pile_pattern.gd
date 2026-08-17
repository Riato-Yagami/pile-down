extends SceneTree

const PileScene := preload("res://resources/scenes/gameplay/Pile.tscn")
const PatternScript := preload(
	"res://resources/scripts/special_rules/rules/MovingPilePattern.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var board := Control.new()
	board.size = get_root().size
	root.add_child(board)
	var pile := PileScene.instantiate() as MemoryPile
	board.add_child(pile)
	pile.position = Vector2(100.0, 100.0)
	var second_pile := PileScene.instantiate() as MemoryPile
	board.add_child(second_pile)
	second_pile.position = Vector2(160.0, 100.0)
	var pattern := PatternScript.new() as MovingPilePattern
	root.add_child(pattern)
	await process_frame
	pile.setup(0, 5)
	second_pile.setup(1, 5)
	var test_piles: Array[MemoryPile] = [pile, second_pile]
	pattern.start(test_piles, 1, 1.0, &"wave")
	var start_position := pile.position
	var second_start_position := second_pile.position
	pattern._process(0.25)
	assert(pile.position.distance_to(start_position) > 0.01)
	assert(not is_equal_approx(
		pile.position.y - start_position.y,
		second_pile.position.y - second_start_position.y
	))
	pattern.stop()
	print("Moving pile pattern test passed.")
	board.queue_free()
	pattern.queue_free()
	quit()
