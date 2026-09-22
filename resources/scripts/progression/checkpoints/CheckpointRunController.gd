class_name CheckpointRunController
extends RefCounted

## Checkpoint capture, unlocking and run restoration.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func get_checkpoint_bonus_choice_count(host: GameManager, start_round: int) -> int:
	return int(floor(float(start_round - 1) / host.Difficulty.BONUS_INTERVAL))


static func offer_checkpoint_backlog_bonus(host: GameManager, completed_round_number: int) -> void:
	if host.game_mode != host.GameMode.CHECKPOINT or host.checkpoint_bonus_backlog <= 0:
		return
	if await host.bonus_manager.offer_bonus_choice(completed_round_number):
		host.checkpoint_bonus_backlog -= 1
		if host.checkpoint_bonus_backlog <= 0:
			host.flawless_since_last_bonus = true
			host._update_hud()


static func capture_checkpoint_candidate(host: GameManager) -> void:
	if not host.Difficulty.ENABLE_CHECKPOINTS:
		return
	var internal_round := host._progression_round()
	if internal_round <= 0 or internal_round % host.Difficulty.CHECKPOINT_INTERVAL != 0:
		host._pending_checkpoint_snapshot = null
		return
	var checkpoint_id := int(internal_round / host.Difficulty.CHECKPOINT_INTERVAL)
	if host.unlocked_checkpoints.has(checkpoint_id):
		host._pending_checkpoint_snapshot = null
		return
	var snapshot := CheckpointSnapshot.new()
	snapshot.checkpoint_id = checkpoint_id
	snapshot.start_round = internal_round
	snapshot.pile_count = host.pile_count
	snapshot.hand_size = host.hand_size
	snapshot.start_value = host.start_value
	snapshot.turn_time = host.turn_time
	snapshot.difficulty_droughts = host.difficulty_droughts.duplicate(true)
	snapshot.unlocked_endless = host.endless_unlocked
	host._pending_checkpoint_snapshot = snapshot


static func unlock_completed_checkpoint(host: GameManager, completed_round: int) -> bool:
	if (
		not host.Difficulty.ENABLE_CHECKPOINTS
		or completed_round % host.Difficulty.CHECKPOINT_INTERVAL != 0
	):
		return false
	var checkpoint_id := int(completed_round / host.Difficulty.CHECKPOINT_INTERVAL)
	if host.unlocked_checkpoints.has(checkpoint_id):
		# Crossing an already unlocked milestone starts a fresh flawless section.
		host.checkpoint_segment_damage_count = 0
		host._pending_checkpoint_snapshot = null
		return false
	if checkpoint_id > 1 and not host.unlocked_checkpoints.has(checkpoint_id - 1):
		# Checkpoints form a strict chain. A later milestone cannot fill a gap,
		# even after a flawless section.
		return false
	if host.checkpoint_segment_damage_count > 0 or host._pending_checkpoint_snapshot == null:
		return false
	host.unlocked_checkpoints.append(checkpoint_id)
	host.unlocked_checkpoints.sort()
	host.checkpoint_snapshots[checkpoint_id] = host._pending_checkpoint_snapshot.to_dictionary()
	host.newly_unlocked_checkpoints.append(checkpoint_id)
	host._save_checkpoint_progress()
	host._pending_checkpoint_snapshot = null
	host.checkpoint_segment_damage_count = 0
	host._refresh_checkpoint_button()
	return true


static func start_from_checkpoint(
	host: GameManager,
	checkpoint_id: int,
	restored_bonuses: Dictionary = {},
	skip_bonus_choices := false,
	requested_seed := ""
) -> bool:
	var snapshot_value: Variant = host._checkpoint_value(host.checkpoint_snapshots, checkpoint_id, null)
	if not snapshot_value is Dictionary:
		return false
	var effective_seed := requested_seed.strip_edges()
	if effective_seed.is_empty() and host.Debug.ENABLED:
		effective_seed = host.Debug.FORCE_RUN_SEED.strip_edges()
	host.run_uses_requested_seed = not effective_seed.is_empty()
	if effective_seed.is_empty():
		host._initialize_run_rng(host.RunRNGScript.generate_run_seed())
	else:
		host._initialize_run_rng(
			host.RunRNGScript.seed_string_to_int(effective_seed), effective_seed
		)
	host._gameplay_generation += 1
	var snapshot := CheckpointSnapshot.from_dictionary(snapshot_value)
	host.soft_audio.play_start()
	host.music_manager.set_low_pass_enabled(false, true)
	host._hand_cycle_generation += 1
	host._pending_interactive_generation = -1
	host.game_mode = host.GameMode.CHECKPOINT
	host.current_challenge = null
	host.challenge_endless = false
	host.challenge_modifiers = ChallengeModifiers.new()
	host._configure_challenge_hand_tray()
	host.bonus_manager.disabled_bonus_ids.clear()
	host.special_rule_manager.disabled_rule_ids.clear()
	host.special_rule_manager.forced_rule_ids.clear()
	host.special_rule_manager.force_rules_every_round = false
	host.special_rule_manager.forced_rule_count = 0
	host.special_rule_manager.disable_rules_on_challenge_first_round = false
	host.current_checkpoint_id = checkpoint_id
	host.checkpoint_bonus_backlog = (
		0 if skip_bonus_choices else host.get_checkpoint_bonus_choice_count(snapshot.start_round)
	)
	host.checkpoint_uses_endless_progression = (
		snapshot.start_round > host.Difficulty.TOTAL_ROUNDS
	)
	host.round_number = snapshot.start_round
	host.pile_count = snapshot.pile_count
	host.hand_size = snapshot.hand_size
	host.start_value = snapshot.start_value
	host.turn_time = snapshot.turn_time
	host.difficulty_droughts = host._normalise_droughts(snapshot.difficulty_droughts)
	host.endless_unlocked = host.endless_unlocked or snapshot.unlocked_endless
	host.run_mistake_count = 0
	host.run_lives_lost = 0
	host.run_completed_rounds = 0
	host.flawless_since_last_bonus = true
	host.run_start_round = snapshot.start_round
	host.started_from_checkpoint = true
	host.checkpoint_segment_damage_count = 0
	host.newly_discovered_bonuses.clear()
	host.newly_encountered_rules.clear()
	host.newly_unlocked_achievements.clear()
	host.newly_unlocked_fonts.clear()
	host.newly_unlocked_checkpoints.clear()
	host.tier_reliefs_applied = 0
	host.music_manager.reset_game_sections(1)
	host.background_manager.start_run(host.cosmetic_rng)
	host.music_manager.transition_to_game_music()
	host.game_started_msec = Time.get_ticks_msec()
	host.run_paused_msec = 0
	host.run_pause_started_msec = host.game_started_msec
	host.round_reached_time_ms = 0
	host.run_time_label.visible = host._global_timer_enabled
	host.overlay.visible = false
	host.overlay_mode = ""
	host._restore_gameplay_transition_elements()
	host.gameplay_layer.visible = true
	host.splash.visible = false
	host.back_button.visible = true
	host.bonus_manager.begin_run()
	if skip_bonus_choices:
		host.bonus_manager.grant_starting_bonuses(restored_bonuses)
	host.start_round()
	return true


