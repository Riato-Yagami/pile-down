extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(25).timeout.connect(func(): quit(1))
	var menu := preload("res://resources/scenes/progression/ProgressionMenu.tscn").instantiate() as ProgressionMenu
	root.add_child(menu)
	menu.open({"fonts": [], "palettes": []})
	menu._show_page(ProgressionMenu.Page.FONTS)
	await process_frame
	var customisation := menu.cosmetic_lists as CustomisationTabs
	assert(menu.title_label.text == "CUSTOMISATION")
	assert(customisation.tabs.tab_count == 3)
	assert(menu.fonts_scroll.visible and not menu.palettes_scroll.visible)
	customisation.tabs.current_tab = 1
	assert(not menu.fonts_scroll.visible and menu.palettes_scroll.visible)
	assert(menu.palettes_scroll.modulate.a < 1.0)
	await customisation._tween.finished
	assert(is_equal_approx(menu.palettes_scroll.modulate.a, 1.0))
	assert(menu.font_preview_scroll.visible)
	menu.refresh({"fonts": [], "palettes": []})
	assert(customisation.current_tab == 1 and menu.palettes_scroll.visible)
	customisation.select_tab(2, false)
	assert(menu.values_scroll.visible and not menu.palettes_scroll.visible and not menu.fonts_scroll.visible)
	# Rapid changes must leave a single, fully visible page.
	for index in [0, 1, 0, 1]:
		customisation.select_tab(index)
	await customisation._tween.finished
	assert(not menu.fonts_scroll.visible and menu.palettes_scroll.visible)
	assert(is_equal_approx(menu.palettes_scroll.modulate.a, 1.0))
	customisation.tabs.grab_focus()
	var left := InputEventAction.new()
	left.action = &"ui_left"
	left.pressed = true
	root.push_input(left)
	await process_frame
	assert(customisation.current_tab == 0)
	# A third page needs only another title/path, without changing the script.
	var extra := CustomisationTabs.new()
	extra.tab_titles = ["ONE", "TWO", "THREE"]
	extra.tab_pages.assign([NodePath("One"), NodePath("Two"), NodePath("Three")])
	var bar := TabBar.new()
	bar.name = "Tabs"
	extra.add_child(bar)
	for label in ["One", "Two", "Three"]:
		var page := Control.new()
		page.name = label
		extra.add_child(page)
	root.add_child(extra)
	extra.select_tab(2, false)
	assert(extra.tabs.tab_count == 3)
	assert(extra.get_node("Three").visible)
	assert(not extra.get_node("One").visible and not extra.get_node("Two").visible)
	extra.queue_free()
	menu.queue_free()
	await process_frame
	print("Customisation tabs tests passed: title, pages, animation, rapid changes, refresh, keyboard and extensibility.")
	quit()
