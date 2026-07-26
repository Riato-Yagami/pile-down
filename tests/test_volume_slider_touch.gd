extends SceneTree

const VolumeSliderScript := preload("res://resources/scripts/ui/VolumeSlider.gd")


func _init() -> void:
	var slider := HSlider.new()
	slider.set_script(VolumeSliderScript)
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.size = Vector2(100.0, 16.0)
	var bar := TextureRect.new()
	bar.name = "Bar"
	slider.add_child(bar)
	root.add_child(slider)

	var press := InputEventScreenTouch.new()
	press.index = 2
	press.position = Vector2(25.0, 8.0)
	press.pressed = true
	slider._gui_input(press)
	assert(is_equal_approx(slider.value, 25.0))
	assert(slider._touch_index == 2)

	var other_drag := InputEventScreenDrag.new()
	other_drag.index = 3
	other_drag.position = Vector2(80.0, 8.0)
	slider._gui_input(other_drag)
	assert(is_equal_approx(slider.value, 25.0))

	var drag := InputEventScreenDrag.new()
	drag.index = 2
	drag.position = Vector2(75.0, 8.0)
	slider._gui_input(drag)
	assert(is_equal_approx(slider.value, 75.0))

	var release := InputEventScreenTouch.new()
	release.index = 2
	release.position = Vector2(120.0, 8.0)
	release.pressed = false
	slider._gui_input(release)
	assert(is_equal_approx(slider.value, 100.0))
	assert(slider._touch_index == -1)

	print("Volume slider touch test passed.")
	slider.queue_free()
	quit()
