class_name ProgressionUnreadStore
extends RefCounted


static func load(game: GameManager) -> void:
	var config := SaveConfig.load_current()
	game.unread_progression_pages.clear()
	game.unread_progression_items.clear()
	for value in config.get_value("progression", "unread_pages", []):
		var page := int(value)
		if (
			page > ProgressionMenu.Page.HIGHSCORES
			and page <= ProgressionMenu.Page.FONTS
			and not game.unread_progression_pages.has(page)
		):
			game.unread_progression_pages.append(page)
	var saved_items: Dictionary = config.get_value(
		"progression", "unread_items", {}
	)
	for page_key in saved_items:
		var page := int(page_key)
		if (
			page <= ProgressionMenu.Page.HIGHSCORES
			or page > ProgressionMenu.Page.FONTS
		):
			continue
		var ids: Array[StringName] = []
		for value in saved_items[page_key]:
			var item_id := StringName(value)
			if not item_id.is_empty() and not ids.has(item_id):
				ids.append(item_id)
		if not ids.is_empty():
			game.unread_progression_items[page] = ids
	save(game)
	refresh_notification(game)


static func mark_page(game: GameManager, page: int) -> void:
	if page == ProgressionMenu.Page.HIGHSCORES:
		return
	if game.unread_progression_pages.has(page):
		return
	game.unread_progression_pages.append(page)
	save(game)
	refresh_notification(game)


static func mark_item(
	game: GameManager, page: int, item_id: StringName
) -> void:
	if item_id.is_empty():
		return
	var items: Array[StringName] = []
	items.assign(game.unread_progression_items.get(page, []))
	if not items.has(item_id):
		items.append(item_id)
		game.unread_progression_items[page] = items
	mark_page(game, page)
	# The page may already be unread, in which case mark_page does not save.
	save(game)


static func is_item_unread(
	game: GameManager, page: int, item_id: StringName
) -> bool:
	return (game.unread_progression_items.get(page, []) as Array).has(item_id)


static func mark_page_viewed(game: GameManager, page: int) -> void:
	if (
		not game.unread_progression_pages.has(page)
		and not game.unread_progression_items.has(page)
	):
		return
	game.unread_progression_pages.erase(page)
	game.unread_progression_items.erase(page)
	save(game)
	refresh_notification(game)


static func save(game: GameManager) -> void:
	var config := SaveConfig.load_current()
	config.set_value(
		"progression", "unread_pages", game.unread_progression_pages
	)
	config.set_value(
		"progression", "unread_items", game.unread_progression_items
	)
	config.save(game.AUDIO_CONFIG_PATH)


static func refresh_notification(game: GameManager) -> void:
	if is_instance_valid(game.progression_notification):
		game.progression_notification.visible = (
			not game.unread_progression_pages.is_empty()
		)
