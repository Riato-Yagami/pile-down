extends SceneTree

const HighlightButtonScript := preload(
	"res://resources/scripts/ui/HighlightButton.gd"
)


func _init() -> void:
	var button := Button.new()
	button.set_script(HighlightButtonScript)
	button.size = Vector2(40.0, 24.0)
	root.add_child(button)
	var state := {"press_count": 0}
	button.pressed.connect(
		func() -> void: state.press_count = int(state.press_count) + 1
	)

	var press := InputEventScreenTouch.new()
	press.index = 4
	press.position = Vector2(20.0, 12.0)
	press.pressed = true
	button._gui_input(press)
	assert(button._touch_index == 4)

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
	assert(button._touch_index == -1)

	print("Highlight button touch test passed.")
	button.queue_free()
	quit()
