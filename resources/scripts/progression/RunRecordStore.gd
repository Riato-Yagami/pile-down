class_name RunRecordStore
extends RefCounted

## Run records, progression discoveries and legacy save migration.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func update_high_score(host: GameManager, rounds_left: int, elapsed_time_ms: int) -> String:
	var is_better_progress := host.best_rounds_left < 0 or rounds_left < host.best_rounds_left
	var is_faster_tie := (
		rounds_left == host.best_rounds_left
		and (host.best_score_time_ms < 0 or elapsed_time_ms < host.best_score_time_ms)
	)
	if not is_better_progress and not is_faster_tie:
		return ""
	host.best_rounds_left = rounds_left
	host.best_score_time_ms = elapsed_time_ms
	host.classic_record_seed = host._current_seed_record()
	host._save_high_score()
	host._refresh_high_score()
	return "ROUND" if is_better_progress else "TIME"


static func save_high_score(host: GameManager) -> void:
	var config := SaveConfig.load_current()
	config.set_value("save", "schema_version", host.SAVE_SCHEMA_VERSION)
	config.set_value("progress", "best_rounds_left", host.best_rounds_left)
	config.set_value("progress", "best_score_time_ms", host.best_score_time_ms)
	config.set_value("highscores", "classic", {
		"rounds_left": host.best_rounds_left, "time_ms": host.best_score_time_ms,
		"seed": host.classic_record_seed.get("seed", 0),
		"seed_label": host.classic_record_seed.get("seed_label", ""),
	})
	config.set_value("highscores", "classic_no_mistake", {
		"rounds_left": host.classic_no_mistake_rounds_left,
		"time_ms": host.classic_no_mistake_time_ms,
		"seed": host.classic_no_mistake_record_seed.get("seed", 0),
		"seed_label": host.classic_no_mistake_record_seed.get("seed_label", ""),
	})
	if host.best_rounds_left == 0:
		config.set_value("progress", "best_time_ms", host.best_score_time_ms)
	config.save(SaveConfig.PATH)


static func update_endless_high_score(
	host: GameManager, reached_round: int, elapsed_time_ms: int
) -> String:
	var is_better_progress := (
		host.endless_best_round < 0 or reached_round > host.endless_best_round
	)
	var is_faster_tie := (
		reached_round == host.endless_best_round
		and (
			host.endless_best_time_ms < 0
			or elapsed_time_ms < host.endless_best_time_ms
		)
	)
	if not is_better_progress and not is_faster_tie:
		return ""
	host.endless_best_round = reached_round
	host.endless_best_time_ms = elapsed_time_ms
	host.endless_record_seed = host._current_seed_record()
	host._save_endless_progress()
	return "ROUND" if is_better_progress else "TIME"


static func unlock_endless_mode(host: GameManager) -> void:
	if host.endless_unlocked:
		return
	host.endless_unlocked = true
	host.endless_button.visible = true
	host._save_endless_progress()


static func save_endless_progress(host: GameManager) -> void:
	var config := SaveConfig.load_current()
	config.set_value("save", "schema_version", host.SAVE_SCHEMA_VERSION)
	config.set_value("progress", "endless_unlocked", host.endless_unlocked)
	config.set_value("progress", "endless_best_round", host.endless_best_round)
	config.set_value("progress", "endless_best_time_ms", host.endless_best_time_ms)
	config.set_value("highscores", "endless", host.endless_best_round)
	config.set_value("highscores", "endless_no_mistake", host.endless_no_mistake_round)
	config.set_value("highscores", "endless_seed", host.endless_record_seed)
	config.set_value(
		"highscores", "endless_no_mistake_seed", host.endless_no_mistake_record_seed
	)
	config.save(SaveConfig.PATH)


static func load_high_score(host: GameManager) -> void:
	var config := ConfigFile.new()
	if config.load(SaveConfig.PATH) == OK:
		if config.has_section_key("progress", "best_rounds_left"):
			host.best_rounds_left = int(config.get_value("progress", "best_rounds_left", -1))
			host.best_score_time_ms = int(config.get_value("progress", "best_score_time_ms", -1))
		else:
			var legacy_best_time := int(config.get_value("progress", "best_time_ms", 0))
			if legacy_best_time > 0:
				host.best_rounds_left = 0
				host.best_score_time_ms = legacy_best_time
		host.endless_unlocked = bool(
			config.get_value("progress", "endless_unlocked", false)
		)
		host.endless_best_round = int(
			config.get_value("progress", "endless_best_round", -1)
		)
		host.endless_best_time_ms = int(
			config.get_value("progress", "endless_best_time_ms", -1)
		)
		var classic_clean: Dictionary = config.get_value(
			"highscores", "classic_no_mistake", {}
		)
		host.classic_no_mistake_rounds_left = int(classic_clean.get("rounds_left", -1))
		host.classic_no_mistake_time_ms = int(classic_clean.get("time_ms", -1))
		host.classic_no_mistake_record_seed = {
			"seed": int(classic_clean.get("seed", 0)),
			"seed_label": str(classic_clean.get("seed_label", "")),
		}
		var classic_record: Dictionary = config.get_value("highscores", "classic", {})
		host.classic_record_seed = {
			"seed": int(classic_record.get("seed", 0)),
			"seed_label": str(classic_record.get("seed_label", "")),
		}
		host.endless_record_seed = config.get_value("highscores", "endless_seed", {})
		host.endless_no_mistake_record_seed = config.get_value(
			"highscores", "endless_no_mistake_seed", {}
		)
		host.endless_no_mistake_round = int(
			config.get_value("highscores", "endless_no_mistake", -1)
		)
		host.discovered_bonuses.assign(
			config.get_value("progression", "discovered_bonuses", [])
		)
		host.max_discovered_tile_value = clampi(
			int(config.get_value(
				"progression", "max_discovered_tile_value",
				host.Difficulty.START_CARD_VALUE
			)),
			host.Difficulty.START_CARD_VALUE,
			host.Difficulty.MAX_CARD_VALUE
		)
		host.max_discovered_pile_count = clampi(
			int(config.get_value(
				"progression", "max_discovered_pile_count",
				host.Difficulty.START_PILES
			)),
			host.Difficulty.START_PILES,
			host.Difficulty.MAX_PILES
		)
		host.max_discovered_hand_size = clampi(
			int(config.get_value(
				"progression", "max_discovered_hand_size",
				host.Difficulty.START_HAND_SIZE
			)),
			host.Difficulty.START_HAND_SIZE,
			host.Difficulty.MAX_HAND_SIZE
		)
		host.min_discovered_turn_time = clampf(
			float(config.get_value(
				"progression", "min_discovered_turn_time",
				host.Difficulty.START_TURN_TIME
			)),
			host.Difficulty.MIN_TURN_TIME,
			host.Difficulty.START_TURN_TIME
		)
		host.seen_bonuses.assign(
			config.get_value("progression", "seen_bonuses", host.discovered_bonuses)
		)
		host.encountered_special_rules.assign(
			config.get_value("progression", "encountered_special_rules", [])
		)
		host.beaten_special_rules.assign(
			config.get_value("progression", "beaten_special_rules", [])
		)
		host._load_checkpoint_progress(config)
		host._refresh_discovered_difficulty_limits_from_progression()
		host._migrate_save(config)
	host.endless_unlocked = host.endless_unlocked or host.Debug.unlock_endless_mode()
	host.endless_button.visible = host.endless_unlocked
	host._refresh_high_score()


static func refresh_high_score(host: GameManager) -> void:
	if host.best_rounds_left < 0 or host.best_score_time_ms < 0:
		host.splash_high_score.text = "[center]HIGHSCORE\n--[/center]"
		host.splash_high_score_time.visible = false
		return
	if host.best_rounds_left == 0:
		host.splash_high_score.text = (
			"[center]HIGHSCORE\nWIN[/center]"
		)
		host.splash_high_score_time.text = "in %s" % host._format_duration(host.best_score_time_ms)
		host.splash_high_score_time.visible = true
		return
	host.splash_high_score.text = (
		"[center]HIGHSCORE\n%d rounds left[/center]" % host.best_rounds_left
	)
	host.splash_high_score_time.text = "in %s" % host._format_duration(host.best_score_time_ms)
	host.splash_high_score_time.visible = true


static func show_endless_high_score(host: GameManager) -> void:
	if host.endless_best_round < 0 or host.endless_best_time_ms < 0:
		host.splash_high_score.text = "[center]ENDLESS HIGHSCORE\n--[/center]"
		host.splash_high_score_time.visible = false
		return
	host.splash_high_score.text = (
		"[center]ENDLESS HIGHSCORE\nround %d[/center]" % host.endless_best_round
	)
	host.splash_high_score_time.text = (
		"in %s" % host._format_duration(host.endless_best_time_ms)
	)
	host.splash_high_score_time.visible = true


static func update_checkpoint_high_score(host: GameManager, reached_round: int) -> String:
	if host.current_checkpoint_id <= 0:
		return ""
	if host.checkpoint_uses_endless_progression:
		if reached_round <= host.checkpoint_endless_best_round:
			return ""
		host.checkpoint_endless_best_round = reached_round
	else:
		var rounds_left := host._checkpoint_rounds_left(reached_round)
		if host.checkpoint_best_rounds_left >= 0 and rounds_left >= host.checkpoint_best_rounds_left:
			return ""
		host.checkpoint_best_rounds_left = rounds_left
	host.checkpoint_record_seed = host._current_seed_record()
	host._save_checkpoint_progress()
	return "ROUND"


static func update_no_mistake_high_score(
	host: GameManager, reached_round: int, elapsed_time_ms: int
) -> void:
	if host.run_mistake_count != 0:
		return
	match host.game_mode:
		host.GameMode.CHECKPOINT:
			if host.checkpoint_uses_endless_progression:
				if reached_round > host.checkpoint_endless_no_mistake_round:
					host.checkpoint_endless_no_mistake_round = reached_round
					host.checkpoint_no_mistake_record_seed = host._current_seed_record()
					host._save_checkpoint_progress()
			else:
				var rounds_left := host._checkpoint_rounds_left(reached_round)
				if (
					host.checkpoint_no_mistake_rounds_left < 0
					or rounds_left < host.checkpoint_no_mistake_rounds_left
				):
					host.checkpoint_no_mistake_rounds_left = rounds_left
					host.checkpoint_no_mistake_record_seed = host._current_seed_record()
				host._save_checkpoint_progress()
		host.GameMode.ENDLESS:
			if reached_round > host.endless_no_mistake_round:
				host.endless_no_mistake_round = reached_round
				host.endless_no_mistake_record_seed = host._current_seed_record()
				host._save_endless_progress()
		_:
			var better := (
				host.classic_no_mistake_rounds_left < 0
				or reached_round < host.classic_no_mistake_rounds_left
				or (
					reached_round == host.classic_no_mistake_rounds_left
					and (
						host.classic_no_mistake_time_ms < 0
						or elapsed_time_ms < host.classic_no_mistake_time_ms
					)
				)
			)
			if better:
				host.classic_no_mistake_rounds_left = reached_round
				host.classic_no_mistake_time_ms = elapsed_time_ms
				host.classic_no_mistake_record_seed = host._current_seed_record()
				host._save_high_score()


static func save_discoveries(host: GameManager) -> void:
	var config := SaveConfig.load_current()
	config.set_value("progression", "discovered_bonuses", host.discovered_bonuses)
	config.set_value(
		"progression", "max_discovered_tile_value", host.max_discovered_tile_value
	)
	config.set_value(
		"progression", "max_discovered_pile_count", host.max_discovered_pile_count
	)
	config.set_value(
		"progression", "max_discovered_hand_size", host.max_discovered_hand_size
	)
	config.set_value(
		"progression", "min_discovered_turn_time", host.min_discovered_turn_time
	)
	config.set_value("progression", "seen_bonuses", host.seen_bonuses)
	config.set_value("progression", "encountered_special_rules", host.encountered_special_rules)
	config.set_value("progression", "beaten_special_rules", host.beaten_special_rules)
	config.save(host.AUDIO_CONFIG_PATH)


static func migrate_save(host: GameManager, config: ConfigFile) -> void:
	var schema_version := int(config.get_value("save", "schema_version", 0))
	if schema_version >= host.SAVE_SCHEMA_VERSION:
		return
	config.set_value("save", "schema_version", host.SAVE_SCHEMA_VERSION)
	config.set_value(
		"progression", "discovered_bonuses",
		config.get_value("progression", "discovered_bonuses", [])
	)
	config.set_value(
		"progression", "max_discovered_tile_value",
		config.get_value(
			"progression", "max_discovered_tile_value",
			host.Difficulty.START_CARD_VALUE
		)
	)
	config.set_value(
		"progression", "max_discovered_pile_count",
		config.get_value(
			"progression", "max_discovered_pile_count",
			host.Difficulty.START_PILES
		)
	)
	config.set_value(
		"progression", "max_discovered_hand_size",
		config.get_value(
			"progression", "max_discovered_hand_size",
			host.Difficulty.START_HAND_SIZE
		)
	)
	config.set_value(
		"progression", "min_discovered_turn_time",
		config.get_value(
			"progression", "min_discovered_turn_time",
			host.Difficulty.START_TURN_TIME
		)
	)
	config.set_value(
		"progression", "seen_bonuses",
		config.get_value(
			"progression", "seen_bonuses",
			config.get_value("progression", "discovered_bonuses", [])
		)
	)
	config.set_value(
		"progression", "encountered_special_rules",
		config.get_value("progression", "encountered_special_rules", [])
	)
	config.set_value(
		"progression", "unlocked_achievements",
		config.get_value("progression", "unlocked_achievements", [])
	)
	config.set_value(
		"progression", "unlocked_fonts",
		config.get_value("progression", "unlocked_fonts", [&"press_start_2p"])
	)
	config.set_value(
		"progression", "beaten_special_rules",
		config.get_value("progression", "beaten_special_rules", [])
	)
	config.set_value(
		"progression", "achievement_unlock_dates",
		config.get_value("progression", "achievement_unlock_dates", {})
	)
	config.set_value(
		"progression", "bonuses_maxed_once",
		config.get_value("progression", "bonuses_maxed_once", {})
	)
	config.set_value(
		"progression", "bonus_highest_levels",
		config.get_value("progression", "bonus_highest_levels", {})
	)
	config.save(host.AUDIO_CONFIG_PATH)
