class_name CheckpointProgressStore
extends RefCounted

## Checkpoint persistence, normalization and debug snapshots.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func normalise_droughts(host: GameManager, value: Dictionary) -> Dictionary:
	var result := host._new_difficulty_droughts()
	for stat: StringName in result.keys():
		result[stat] = clampi(
			int(value.get(stat, value.get(String(stat), 0))),
			0,
			host.Difficulty.MAX_STAT_DROUGHT
		)
	return result


static func save_checkpoint_progress(host: GameManager) -> void:
	var config := SaveConfig.load_current()
	config.set_value("save", "schema_version", host.SAVE_SCHEMA_VERSION)
	config.set_value("checkpoints", "unlocked", host.unlocked_checkpoints)
	config.set_value(
		"checkpoints", "interval", host.Difficulty.CHECKPOINT_INTERVAL
	)
	config.set_value("checkpoints", "snapshots", host.checkpoint_snapshots)
	config.set_value("checkpoints", "highscores", host.checkpoint_highscores)
	config.set_value(
		"checkpoints", "no_mistake_highscores", host.checkpoint_no_mistake_highscores
	)
	config.set_value("checkpoints", "best", host.checkpoint_best_round)
	config.set_value(
		"checkpoints", "best_no_mistake", host.checkpoint_no_mistake_best_round
	)
	config.set_value(
		"checkpoints", "best_rounds_left", host.checkpoint_best_rounds_left
	)
	config.set_value(
		"checkpoints", "endless_best_round", host.checkpoint_endless_best_round
	)
	config.set_value(
		"checkpoints", "no_mistake_rounds_left",
		host.checkpoint_no_mistake_rounds_left
	)
	config.set_value(
		"checkpoints", "endless_no_mistake_round",
		host.checkpoint_endless_no_mistake_round
	)
	config.set_value("checkpoints", "record_seed", host.checkpoint_record_seed)
	config.set_value(
		"checkpoints", "no_mistake_record_seed", host.checkpoint_no_mistake_record_seed
	)
	config.save(host.AUDIO_CONFIG_PATH)


static func load_checkpoint_progress(host: GameManager, config: ConfigFile) -> void:
	host.unlocked_checkpoints.assign(config.get_value("checkpoints", "unlocked", []))
	host.checkpoint_snapshots = Dictionary(
		config.get_value("checkpoints", "snapshots", {})
	).duplicate(true)
	host.checkpoint_highscores = Dictionary(
		config.get_value("checkpoints", "highscores", {})
	).duplicate(true)
	host.checkpoint_no_mistake_highscores = Dictionary(
		config.get_value("checkpoints", "no_mistake_highscores", {})
	).duplicate(true)
	var checkpoint_ids_changed := host._normalise_checkpoint_ids()
	host.checkpoint_best_round = int(config.get_value("checkpoints", "best", -1))
	host.checkpoint_no_mistake_best_round = int(
		config.get_value("checkpoints", "best_no_mistake", -1)
	)
	host.checkpoint_best_rounds_left = int(
		config.get_value("checkpoints", "best_rounds_left", -1)
	)
	host.checkpoint_endless_best_round = int(
		config.get_value("checkpoints", "endless_best_round", -1)
	)
	host.checkpoint_no_mistake_rounds_left = int(
		config.get_value("checkpoints", "no_mistake_rounds_left", -1)
	)
	host.checkpoint_endless_no_mistake_round = int(
		config.get_value("checkpoints", "endless_no_mistake_round", -1)
	)
	host.checkpoint_record_seed = config.get_value("checkpoints", "record_seed", {})
	host.checkpoint_no_mistake_record_seed = config.get_value(
		"checkpoints", "no_mistake_record_seed", {}
	)
	# Migrate the former per-checkpoint leaderboards into one shared score.
	if host.checkpoint_best_round < 0:
		for value in host.checkpoint_highscores.values():
			host.checkpoint_best_round = maxi(host.checkpoint_best_round, int(value))
	if host.checkpoint_no_mistake_best_round < 0:
		for value in host.checkpoint_no_mistake_highscores.values():
			host.checkpoint_no_mistake_best_round = maxi(
				host.checkpoint_no_mistake_best_round, int(value)
			)
	if host.checkpoint_best_rounds_left < 0 and host.checkpoint_best_round >= 0:
		if host.checkpoint_best_round > host.Difficulty.TOTAL_ROUNDS:
			host.checkpoint_endless_best_round = maxi(
				host.checkpoint_endless_best_round, host.checkpoint_best_round
			)
		else:
			host.checkpoint_best_rounds_left = host._checkpoint_rounds_left(
				host.checkpoint_best_round
			)
	if (
		host.checkpoint_no_mistake_rounds_left < 0
		and host.checkpoint_no_mistake_best_round >= 0
	):
		if host.checkpoint_no_mistake_best_round > host.Difficulty.TOTAL_ROUNDS:
			host.checkpoint_endless_no_mistake_round = maxi(
				host.checkpoint_endless_no_mistake_round,
				host.checkpoint_no_mistake_best_round
			)
		else:
			host.checkpoint_no_mistake_rounds_left = host._checkpoint_rounds_left(
				host.checkpoint_no_mistake_best_round
			)
	if checkpoint_ids_changed:
		host._save_checkpoint_progress()


static func normalise_checkpoint_ids(host: GameManager) -> bool:
	var migrated_snapshots: Dictionary = {}
	var migrated_unlocked: Array[int] = []
	var changed := false
	for old_key in host.checkpoint_snapshots.keys():
		var snapshot_value: Variant = host.checkpoint_snapshots[old_key]
		if not snapshot_value is Dictionary:
			changed = true
			continue
		var snapshot := CheckpointSnapshot.from_dictionary(snapshot_value)
		if (
			snapshot.start_round <= 0
			or snapshot.start_round % host.Difficulty.CHECKPOINT_INTERVAL != 0
		):
			# Preserve unusual legacy data under its old key; it remains available
			# for migration inspection but is not presented as a valid checkpoint.
			migrated_snapshots[old_key] = snapshot_value
			changed = true
			continue
		var expected_id := int(
			snapshot.start_round / host.Difficulty.CHECKPOINT_INTERVAL
		)
		if int(old_key) != expected_id or snapshot.checkpoint_id != expected_id:
			changed = true
		snapshot.checkpoint_id = expected_id
		# Never replace the first snapshot already assigned to the same round.
		if not migrated_snapshots.has(expected_id):
			migrated_snapshots[expected_id] = snapshot.to_dictionary()
			migrated_unlocked.append(expected_id)
	migrated_unlocked.sort()
	# A player who reached a later checkpoint necessarily passed every earlier
	# milestone. Old schemas may not contain snapshots for those milestones.
	# Rebuild them with safe permanent defaults so the earliest FROM option is
	# never skipped merely because the checkpoint feature was added later.
	if not migrated_unlocked.is_empty():
		var highest_id: int = migrated_unlocked.back()
		for checkpoint_id in range(1, highest_id + 1):
			if migrated_snapshots.has(checkpoint_id):
				continue
			var fallback := CheckpointSnapshot.new()
			fallback.checkpoint_id = checkpoint_id
			fallback.start_round = checkpoint_id * host.Difficulty.CHECKPOINT_INTERVAL
			fallback.pile_count = host.Difficulty.START_PILES
			fallback.hand_size = host.Difficulty.START_HAND_SIZE
			fallback.start_value = host.Difficulty.START_CARD_VALUE
			fallback.turn_time = host.Difficulty.START_TURN_TIME
			fallback.difficulty_droughts = host._new_difficulty_droughts()
			fallback.unlocked_endless = host.endless_unlocked
			migrated_snapshots[checkpoint_id] = fallback.to_dictionary()
			migrated_unlocked.append(checkpoint_id)
			changed = true
		migrated_unlocked.sort()
	if migrated_unlocked != host.unlocked_checkpoints:
		changed = true
	host.checkpoint_snapshots = migrated_snapshots
	host.unlocked_checkpoints = migrated_unlocked
	return changed


static func checkpoint_value(
	host: GameManager, values: Dictionary, checkpoint_id: int, fallback: Variant
) -> Variant:
	if values.has(checkpoint_id):
		return values[checkpoint_id]
	var string_id := str(checkpoint_id)
	return values.get(string_id, fallback)


static func apply_debug_checkpoints(host: GameManager) -> void:
	var requested_checkpoint := host.Debug.start_from_checkpoint()
	if not host.Debug.unlock_all_checkpoints() and requested_checkpoint <= 0:
		return
	var last_checkpoint := (
		int(host.Difficulty.TOTAL_ROUNDS / host.Difficulty.CHECKPOINT_INTERVAL)
		if host.Debug.unlock_all_checkpoints()
		else requested_checkpoint
	)
	host._generate_debug_checkpoint_snapshots(last_checkpoint)


static func generate_debug_checkpoint_snapshots(host: GameManager, last_checkpoint: int) -> void:
	var saved_difficulty := {
		"pile_count": host.pile_count,
		"hand_size": host.hand_size,
		"start_value": host.start_value,
		"turn_time": host.turn_time,
		"difficulty_droughts": host.difficulty_droughts.duplicate(true),
		"tier_reliefs_applied": host.tier_reliefs_applied,
		"rng_state": host.rng.state,
	}
	host.pile_count = host.Difficulty.START_PILES
	host.hand_size = host.Difficulty.START_HAND_SIZE
	host.start_value = host.Difficulty.START_CARD_VALUE
	host.turn_time = host.Difficulty.START_TURN_TIME
	host.difficulty_droughts = host._new_difficulty_droughts()
	host.tier_reliefs_applied = 0
	# Debug checkpoints must be reproducible and must not consume the gameplay
	# RNG sequence used by the run that follows.
	host.rng.seed = 0x50494C45
	var final_round := last_checkpoint * host.Difficulty.CHECKPOINT_INTERVAL
	for progression_round in range(2, final_round + 1):
		host._advance_difficulty(progression_round, 1 if progression_round == 2 else 0)
		if progression_round % host.Difficulty.CHECKPOINT_INTERVAL != 0:
			continue
		var checkpoint_id := int(progression_round / host.Difficulty.CHECKPOINT_INTERVAL)
		if host.unlocked_checkpoints.has(checkpoint_id):
			continue
		var snapshot := CheckpointSnapshot.new()
		snapshot.checkpoint_id = checkpoint_id
		snapshot.start_round = progression_round
		snapshot.pile_count = host.pile_count
		snapshot.hand_size = host.hand_size
		snapshot.start_value = host.start_value
		snapshot.turn_time = host.turn_time
		snapshot.difficulty_droughts = host.difficulty_droughts.duplicate(true)
		snapshot.unlocked_endless = host.endless_unlocked
		host.unlocked_checkpoints.append(checkpoint_id)
		host.checkpoint_snapshots[checkpoint_id] = snapshot.to_dictionary()
	host.pile_count = int(saved_difficulty.pile_count)
	host.hand_size = int(saved_difficulty.hand_size)
	host.start_value = int(saved_difficulty.start_value)
	host.turn_time = float(saved_difficulty.turn_time)
	host.difficulty_droughts = Dictionary(saved_difficulty.difficulty_droughts)
	host.tier_reliefs_applied = int(saved_difficulty.tier_reliefs_applied)
	host.rng.state = int(saved_difficulty.rng_state)
	host.unlocked_checkpoints.sort()
