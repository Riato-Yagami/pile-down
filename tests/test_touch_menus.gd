extends SceneTree

const PopupTouch := preload("res://resources/scripts/ui/PopupTouchInput.gd")
const TouchScroll := preload("res://resources/scripts/ui/MenuTouchScroll.gd")
var _activations := 0


func _init() -> void:
	call_deferred("_run")


func _touch(window: Viewport, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = point
	event.pressed = pressed
	window.push_input(event, true)


func _run() -> void:
	create_timer(15.0).timeout.connect(func() -> void: quit(1))
	root.gui_embed_subwindows = true
	var holder := Control.new()
	root.add_child(holder)
	holder.size = Vector2(256, 320)
	var selector := OptionButton.new()
	holder.add_child(selector)
	selector.position = Vector2(20, 20)
	selector.size = Vector2(180, 30)
	for title in ["CLASSIC", "SEMI ADAPTIVE", "ADAPTIVE"]:
		selector.add_item(title)
	PopupTouch.install(selector.get_popup())
	await process_frame
	_touch(root, selector.get_global_rect().get_center(), true)
	_touch(root, selector.get_global_rect().get_center(), false)
	await process_frame
	var popup := selector.get_popup()
	assert(popup.visible, "Touch must open the selector")
	# Tap the final row through the actual popup viewport.
	var point := Vector2(30, popup.size.y - 12)
	_touch(root, Vector2(popup.position) + point, true)
	_touch(root, Vector2(popup.position) + point, false)
	await process_frame
	assert(selector.selected == 2, "Touch must select a popup row")
	assert(not popup.visible)
	selector.show_popup()
	await process_frame
	root.window_input.emit(_press(Vector2(245, 300)))
	await process_frame
	assert(not popup.visible, "Outside tap must close popup")
	popup.content_scale_factor = 1.5
	selector.show_popup()
	await process_frame
	point = Vector2(popup.position) + Vector2(25, 12) * popup.content_scale_factor
	_touch(root, point, true)
	_touch(root, point, false)
	await process_frame
	assert(selector.selected == 0, "Popup selection must respect its display scale")
	assert(not popup.visible)
	selector.hide()
	var scroll := ScrollContainer.new()
	holder.add_child(scroll)
	scroll.size = Vector2(200, 100)
	scroll.position = Vector2(10, 80)
	var column := VBoxContainer.new()
	scroll.add_child(column)
	for index in 12:
		var button := RegionButton.new()
		button.custom_minimum_size = Vector2(170, 30)
		button.text = str(index)
		button.pressed.connect(func() -> void: _activations += 1)
		column.add_child(button)
	holder.add_child(TouchScroll.new())
	await process_frame
	await process_frame
	_touch(root, Vector2(40, 140), true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(40, 95)
	drag.relative = Vector2(0, -45)
	root.push_input(drag, true)
	_touch(root, drag.position, false)
	assert(scroll.scroll_vertical >= 40, "Swipe must scroll over buttons")
	assert(_activations == 0, "Swipe must not activate a button")
	await process_frame
	await process_frame
	_touch(root, Vector2(40, 110), true)
	_touch(root, Vector2(40, 110), false)
	assert(_activations == 1, "Tap after swipe must still work")
	holder.queue_free()
	await process_frame
	await _check_game_menus()
	print("Touch menu tests passed.")
	quit()


func _press(point: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = true
	return event


func _check_game_menus() -> void:
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	await process_frame
	game.options_menu.show()
	game._show_options_page(GameManager.OPTION_GRAPHICS)
	await process_frame
	var choices := game.adaptive_resolution_button.get_parent().get_node("ScreenSizeModeSelector") as OptionButton
	for index in [2, 0, 1]:
		choices.show_popup()
		await process_frame
		var popup := choices.get_popup()
		var panel := popup.get_theme_stylebox("panel")
		var top := panel.get_margin(SIDE_TOP)
		var rows_height := float(popup.size.y) / popup.content_scale_factor - top - panel.get_margin(SIDE_BOTTOM)
		var point := Vector2(popup.position) + Vector2(25, top + rows_height * (index + 0.5) / 3.0) * popup.content_scale_factor
		_touch(root, point, true)
		_touch(root, point, false)
		await process_frame
		assert(choices.selected == index)
		assert(game._screen_size_mode == [&"classic", &"semi_adaptive", &"adaptive"][index])
		assert(not popup.visible)
	game._show_options_page(GameManager.OPTION_LINKS)
	var titles: Array[String] = []
	for child in game.links_options.get_children():
		if child is Button:
			titles.append(child.text)
			assert(child is RegionButton)
	assert(titles == ["JUELS.DEV", "ITCH.IO", "KO-FI"])
	game.queue_free()
	await process_frame
