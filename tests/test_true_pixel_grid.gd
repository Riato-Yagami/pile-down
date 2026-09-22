extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")
const GameOptionsController := preload(
	"res://resources/scripts/settings/GameOptionsController.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(513, 641)
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	game._adaptive_resolution = true
	game._true_pixel_art_enabled = true
	GameOptionsController.apply_resolution(game)
	await process_frame
	await process_frame
	assert(_is_pixel_rect(game.gameplay_layer))
	assert(_is_pixel_rect(game.screens))
	assert(_is_pixel_rect(game.challenge_selection))
	assert(_is_pixel_rect(game.progression_menu))
	assert(_is_pixel_rect(game.challenge_selection.lock_filter.get_parent() as Control))
	assert(_is_pixel_rect(game.progression_menu.lock_filter.get_parent() as Control))
	game.queue_free()
	quit()


func _is_pixel_rect(control: Control) -> bool:
	var rect := control.get_global_rect()
	return (
		rect.position == rect.position.round()
		and rect.size == rect.size.floor()
		and control.size == control.size.floor()
	)
