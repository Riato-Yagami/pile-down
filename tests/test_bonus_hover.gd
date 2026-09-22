extends SceneTree

const GAME_SCENE := preload("res://resources/scenes/Game.tscn")
const CARD_SCENE := preload("res://resources/scenes/gameplay/Card.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GAME_SCENE.instantiate() as GameManager
	root.add_child(game)
	game.bonus_manager.active.clear()
	game.bonus_manager._add_or_upgrade(BonusRegistry.get_bonus(&"deja_vu"))
	await process_frame
	assert(game.active_bonus_bar.get_index() < game.get_node("Gameplay/PilesBoard").get_index())
	var badge := game.active_bonus_bar.get_child(0) as ActiveBonusBadge
	badge.description_requested.emit("Bonus description")
	await process_frame
	await process_frame
	assert(game.bonus_manager.active_description.visible)
	var card := CARD_SCENE.instantiate() as PlayingCard
	game.add_child(card)
	game.selected_card = card
	assert(not game.bonus_manager.active_description.visible)
	badge.description_requested.emit("Blocked description")
	await process_frame
	assert(not game.bonus_manager.active_description.visible)
	game.selected_card = null
	badge.description_requested.emit("Restored description")
	await process_frame
	await process_frame
	assert(game.bonus_manager.active_description.visible)
	# Cancel even when the popup is still waiting for its layout frame.
	badge.description_requested.emit("Pending description")
	game.selected_card = card
	await process_frame
	await process_frame
	assert(not game.bonus_manager.active_description.visible)
	game.selected_card = null
	game.queue_free()
	await process_frame
	print("Bonus hover test passed.")
	quit()
