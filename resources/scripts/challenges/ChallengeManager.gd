class_name ChallengeManager
extends Node

const SAVE_PATH := "user://pile_down.cfg"

var definitions: Array[ChallengeData] = ChallengeRegistry.create_all()
var completed: Array[StringName] = []
var highscores: Dictionary = {}
var endless_highscores: Dictionary = {}
var best_times_ms: Dictionary = {}
var record_seeds: Dictionary = {}
var endless_record_seeds: Dictionary = {}
var last_record_kind := ""
var debug_unlock_all := false


func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	for value in config.get_value("challenges", "completed", []):
		completed.append(StringName(value))
	highscores = config.get_value("challenges", "highscores", {})
	endless_highscores = config.get_value("challenges", "endless_highscores", {})
	best_times_ms = config.get_value("challenges", "best_times_ms", {})
	record_seeds = config.get_value("challenges", "record_seeds", {})
	endless_record_seeds = config.get_value("challenges", "endless_record_seeds", {})


func find(id: StringName) -> ChallengeData:
	for data in definitions:
		if data.id == id:
			return data
	return null


func modifiers_for(data: ChallengeData) -> ChallengeModifiers:
	var result := ChallengeModifiers.new()
	result.guarantee_playable_hand = data.guarantee_playable_hand
	result.reload_low_time_bonus = data.reload_low_time_bonus
	result.force_single_life = data.force_single_life
	result.disable_life_bonuses = data.disable_life_bonuses
	result.pool_physics_enabled = data.pool_physics_enabled
	result.hide_tile_numbers = data.hide_tile_numbers
	result.shared_round_clock = data.shared_round_clock
	result.shared_clock_seconds_per_hand = data.shared_clock_seconds_per_hand
	result.conveyor_hand = data.conveyor_hand
	result.conveyor_guaranteed_interval = data.conveyor_guaranteed_interval
	result.conveyor_speed = data.conveyor_speed
	result.disable_special_rules_on_first_round = data.disable_special_rules_on_first_round
	result.force_special_rules_every_round = data.force_special_rules_every_round
	result.forced_special_rule_count = data.forced_special_rule_count
	result.commit_selected_cards = data.commit_selected_cards
	result.hide_selected_card_value = data.hide_selected_card_value
	result.disabled_bonuses.assign(data.disabled_bonuses)
	result.disabled_special_rules.assign(data.disabled_rules)
	return result


func is_unlocked(data: ChallengeData, achievements: Array[StringName]) -> bool:
	var required_id := data.required_achievement_id()
	return (
		debug_unlock_all
		or required_id.is_empty()
		or achievements.has(required_id)
	)


func record_result(
	data: ChallengeData, reached_round: int, endless: bool, elapsed_time_ms := -1,
	seed_value := 0, seed_label := ""
) -> bool:
	last_record_kind = ""
	var scores := endless_highscores if endless else highscores
	var previous := int(scores.get(data.id, -1))
	var completed_run := reached_round >= data.target_round
	var new_record := reached_round > previous
	if new_record:
		scores[data.id] = reached_round
		var seeds := endless_record_seeds if endless else record_seeds
		seeds[data.id] = {"seed": seed_value, "seed_label": seed_label}
		last_record_kind = "ROUND"
		if not endless and elapsed_time_ms >= 0:
			best_times_ms[data.id] = elapsed_time_ms
	elif not endless and reached_round == previous and elapsed_time_ms >= 0:
		var previous_time := int(best_times_ms.get(data.id, -1))
		if previous_time < 0 or elapsed_time_ms < previous_time:
			best_times_ms[data.id] = elapsed_time_ms
			new_record = true
			last_record_kind = "TIME"
			record_seeds[data.id] = {
				"seed": seed_value, "seed_label": seed_label
			}
	var newly_completed := false
	if not endless and completed_run and not completed.has(data.id):
		completed.append(data.id)
		newly_completed = true
		if last_record_kind.is_empty():
			last_record_kind = "ROUND"
	_save()
	return newly_completed or new_record


func _save() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("challenges", "completed", completed)
	config.set_value("challenges", "highscores", highscores)
	config.set_value("challenges", "endless_highscores", endless_highscores)
	config.set_value("challenges", "best_times_ms", best_times_ms)
	config.set_value("challenges", "record_seeds", record_seeds)
	config.set_value("challenges", "endless_record_seeds", endless_record_seeds)
	config.save(SAVE_PATH)
