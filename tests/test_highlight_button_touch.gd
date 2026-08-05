extends SceneTree

const HighlightButtonScript := preload(
	"res://resources/scripts/ui/HighlightButton.gd"
)
const TextureHighlightButtonScript := preload(
	"res://resources/scripts/ui/TextureHighlightButton.gd"
)


func _init() -> void:
	var button := Button.new()
	button.set_script(HighlightButtonScript)
	button.size = Vector2(40.0, 24.0)
	root.add_child(button)
	await process_frame
	assert(button.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND)
	var state := {"press_count": 0}
	button.pressed.connect(
		func() -> void: state.press_count = int(state.press_count) + 1
	)

	var press := InputEventScreenTouch.new()
	press.index = 4
	press.position = Vector2(20.0, 12.0)
	press.pressed = true
	button._gui_input(press)
	assert(button._interaction.touch_index == 4)

	var other_release := InputEventScreenTouch.new()
	other_release.index = 5
	other_release.position = Vector2(20.0, 12.0)
	other_release.pressed = false
	button._gui_input(other_release)
	assert(state.press_count == 0)

	var release := InputEventScreenTouch.new()
	release.index = 4
	release.position = Vector2(20.0, 12.0)
	release.pressed = false
	button._gui_input(release)
	assert(state.press_count == 1)
	assert(button._interaction.touch_index == -1)

	var texture_button := TextureButton.new()
	texture_button.set_script(TextureHighlightButtonScript)
	root.add_child(texture_button)
	await process_frame
	assert(texture_button.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND)

	print("Highlight button touch test passed.")
	button.queue_free()
	texture_button.queue_free()
	quit()
