class_name ProgressionSnapshotBuilder
extends RefCounted

const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")


static func build(game: GameManager) -> Dictionary:
	return {
		"max_discovered_tile_value": game.max_discovered_tile_value,
		"highscores": highscores(game),
		"achievements": achievements(game),
		"bonuses": bonuses(game),
		"special_rules": special_rules(game),
		"fonts": fonts(game),
		"palettes": palettes(game),
		"unread_progression_pages": game.unread_progression_pages.duplicate(),
	}


static func highscores(game: GameManager) -> Array[Dictionary]:
	var classic_value := "--"
	if game.best_rounds_left >= 0:
		classic_value = "%d rounds left" % game.best_rounds_left
		if game.best_score_time_ms >= 0:
			classic_value += "\n" + game._format_duration(game.best_score_time_ms)
	var endless_value := "--"
	if game.endless_best_round >= 0:
		endless_value = "round %d" % game.endless_best_round
		if game.endless_best_time_ms >= 0:
			endless_value += "\n" + game._format_duration(game.endless_best_time_ms)
	var checkpoint_lines := PackedStringArray()
	if game.checkpoint_best_rounds_left >= 0:
		checkpoint_lines.append(
			"%d rounds left" % game.checkpoint_best_rounds_left
		)
	if game.checkpoint_endless_best_round >= 0:
		checkpoint_lines.append(
			"round %d reached" % game.checkpoint_endless_best_round
		)
	return [
		{"title": "CLASSIC", "value": classic_value},
		{"title": "ENDLESS", "value": endless_value},
		{
			"title": "CHECKPOINTS",
			"value": (
				"\n".join(checkpoint_lines)
				if not checkpoint_lines.is_empty() else "--"
			),
		},
	]


static func achievements(game: GameManager) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for data in game.achievement_manager.definitions:
		var progress := ""
		var progress_current := 0
		var progress_target := 0
		match data.id:
			&"all_checkpoints":
				progress_current = game.unlocked_checkpoints.size()
				progress_target = AchievementManager.normal_checkpoint_ids().size()
				progress = "Checkpoints unlocked: %d / %d" % [
					progress_current, progress_target,
				]
			&"all_bonuses_discovered":
				progress_current = game.discovered_bonuses.filter(
					func(id: StringName) -> bool:
						return Difficulty.ENABLED_BONUSES.has(id)
				).size()
				progress_target = Difficulty.ENABLED_BONUSES.size()
				progress = "Bonuses discovered: %d / %d" % [
					progress_current, progress_target,
				]
			&"all_bonuses_maxed_once":
				for bonus_id in Difficulty.ENABLED_BONUSES:
					if bool(game.achievement_manager.bonuses_maxed_once.get(
						bonus_id, false
					)):
						progress_current += 1
				progress_target = Difficulty.ENABLED_BONUSES.size()
				progress = "BONUSES MAXED\n%d / %d" % [
					progress_current, progress_target,
				]
			&"beat_all_special_rules":
				progress_current = game.beaten_special_rules.filter(
					func(id: StringName) -> bool:
						return Difficulty.ENABLED_SPECIAL_RULES.has(id)
				).size()
				progress_target = Difficulty.ENABLED_SPECIAL_RULES.size()
				progress = "Special Rules beaten: %d / %d" % [
					progress_current, progress_target,
				]
		result.append({
			"id": data.id,
			"title": data.title,
			"description": data.description,
			"category": data.category,
			"hidden": data.hidden,
			"unlocked": game.achievement_manager.unlocked.has(data.id),
			"date": str(game.achievement_manager.unlock_dates.get(data.id, "")),
			"reward_font": data.reward_font,
			"new": game._is_progression_item_unread(
				ProgressionMenu.Page.ACHIEVEMENTS, data.id
			),
			"progress": progress,
			"progress_current": progress_current,
			"progress_target": progress_target,
		})
	return result


static func bonuses(game: GameManager) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for data in game.bonus_manager.definitions:
		result.append({
			"id": data.id,
			"title": data.title,
			"description": data.description,
			"seen": game.seen_bonuses.has(data.id) or game.discovered_bonuses.has(data.id),
			"discovered": game.discovered_bonuses.has(data.id),
			"highest_level": int(
				game.achievement_manager.bonus_highest_levels.get(data.id, 0)
			),
			"max_level": data.max_level,
			"new": game._is_progression_item_unread(
				ProgressionMenu.Page.BONUSES, data.id
			),
		})
	return result


static func special_rules(game: GameManager) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for data in SpecialRuleRegistry.create_all_rules():
		result.append({
			"id": data.id,
			"title": data.title,
			"description": data.description,
			"discovered": game.encountered_special_rules.has(data.id),
			"obtained": game.beaten_special_rules.has(data.id),
			"new": game._is_progression_item_unread(
				ProgressionMenu.Page.SPECIAL_RULES, data.id
			),
		})
	return result


static func fonts(game: GameManager) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for data in game.font_manager.definitions:
		result.append({
			"id": data.id,
			"title": data.display_name,
			"font": data.font,
			"font_size": data.tile_font_size,
			"font_offset": data.tile_font_offset,
			"title_font_offset": data.title_font_offset,
			"title_font_size": (
				data.title_font_size
				if data.title_font_size > 0 else data.tile_font_size
			),
			"override_hidden_tile_with_font": data.override_hidden_tile_with_font,
			"unlocked": game.font_manager.unlocked.has(data.id),
			"selected": game.font_manager.selected_font == data.id,
		})
	return result


static func palettes(game: GameManager) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for data in game.palette_manager.definitions:
		var theme := game.theme_manager.find(data.id)
		if theme == null:
			theme = ThemePaletteRegistry.from_color_palette(data)
		result.append({
			"id": data.id,
			"title": data.display_name,
			"colors": data.normalized_colors(),
			"ui_button_color": theme.ui_button_color,
			"ui_button_hover_color": theme.ui_button_hover_color,
			"ui_button_text_color": theme.ui_button_text_color,
			"bg_base_color": theme.bg_base_color,
			"bg_secondary_color": theme.bg_secondary_color,
			"unlocked": game.palette_manager.unlocked.has(data.id),
			"selected": game.palette_manager.selected_palette == data.id,
		})
	return result
