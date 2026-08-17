extends SceneTree

const ButtonScene := preload("res://resources/scenes/ui/RegionButton.tscn")
const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	var button := ButtonScene.instantiate() as RegionButton
	root.add_child(button)
	button.size = Vector2(140.0, 42.0)
	await process_frame
	var style := button.get_theme_stylebox("normal") as StyleBoxTexture
	assert(style != null)
	assert(style.texture is AtlasTexture)
	assert((style.texture as AtlasTexture).region == button.region_rect)
	assert(is_equal_approx(style.texture_margin_left, button.patch_margin_left))
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	await process_frame
	assert(game.splash_button is RegionButton)
	assert(game.overlay_button is RegionButton)
	assert(game.quit_restart_button is RegionButton)
	print("Region button tests passed.")
	button.queue_free()
	game.queue_free()
	quit()
