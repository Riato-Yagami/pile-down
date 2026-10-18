extends SceneTree

const HAND_DRAG := preload("res://resources/scripts/gameplay/interaction/HandDragController.gd")

## Real, seeded demonstrations. Only the publishing script runs this tool.
var game: GameManager
var segments: Array[Dictionary] = []
var placements := 0
var friend_placements := 0
var swaps := 0
var frame_directory := ""
var frame_index := 0
var max_companions := 0
var conveyor_placements := 0
var conveyor_distance := 0.0


func _init() -> void:
	_run.call_deferred()


func _time() -> float:
	return float(frame_index) / 30.0


func _capture_frame() -> void:
	var image := root.get_texture().get_image()
	assert(image.save_png(frame_directory.path_join("frame%08d.png" % frame_index)) == OK)
	frame_index += 1


func _wait_ready() -> void:
	while game.input_locked:
		await process_frame
	game.timer_manager.stop_countdown()


func _profile_seed(prefix: String, round_index: int, piles: int, hand: int, value: int) -> String:
	# Replay genuine difficulty upgrades rather than inventing a round's stats.
	for attempt in 4096:
		var candidate := "%s-%d" % [prefix, attempt]
		var streams := RunRNG.new()
		streams.initialize(RunRNG.seed_string_to_int(candidate))
		var progression := DifficultyProgression.new()
		progression.apply_until(streams.get_stream(&"difficulty"), round_index)
		if progression.pile_count == piles and progression.hand_size == hand and progression.start_value == value:
			return candidate
	assert(false, "No reproducible seed matches the requested trailer profile")
	return ""


func _start(
	seed_text: String, bonuses: Dictionary, rules: Array[StringName], round_index: int,
	challenge: ChallengeData = null
) -> void:
	if not game.splash.visible:
		await game._return_to_menu()
	game.start_game(false, challenge, false, seed_text, bonuses, rules, {
		"start_round": round_index,
	})
	# The menu exit defers board setup. Keep each shot's rule set deliberate.
	game.special_rule_manager.suppress_next_announcement = true
	game.special_rule_manager.disable_rules_on_challenge_first_round = rules.is_empty()
	game.special_rule_manager.challenge_start_round = round_index
	await _wait_ready()
	# Record only effects: the edit adds one uninterrupted music track.
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), true)
	assert(game._progression_round() == round_index, "Capture must start at its actual progression round")
	var expected_counter := (
		challenge.target_round - challenge.start_round if challenge != null
		else game.Difficulty.TOTAL_ROUNDS - round_index + 1
	)
	assert(game.round_label.text == str(expected_counter))
	await create_timer(0.3).timeout
	print("Shot: round=%d, counter=%s, piles=%d, hand=%d, value=%d, time=%.1f, seed=%s" % [
		round_index, game.round_label.text, game.pile_count, game.hand_size,
		game.start_value, game.turn_time, seed_text,
	])


func _finish_segment(id: String, begin: float) -> void:
	segments.append({
		"id": id, "start": begin, "end": _time(),
		"progression_round": game._progression_round(), "displayed_round": game.round_label.text,
		"pile_count": game.pile_count, "hand_size": game.hand_size,
		"start_value": game.start_value, "turn_time": game.turn_time,
		"seed": game.run_seed_label,
		"challenge": str(game.current_challenge.id) if game.current_challenge != null else "",
		"hand_mode": "conveyor" if game.challenge_modifiers.conveyor_hand else "draw",
	})


func _run() -> void:
	assert(not DebugSettings.ENABLED, "Disable debug mode for publishing captures")
	create_timer(150.0).timeout.connect(func(): quit(1))
	var args := OS.get_cmdline_user_args()
	assert(args.size() == 3, "Expected metadata path, format and language")
	frame_directory = args[0].get_base_dir().path_join("full")
	DirAccess.make_dir_recursive_absolute(frame_directory)
	RenderingServer.frame_post_draw.connect(_capture_frame)
	root.size = Vector2i(432, 768) if args[1] == "portrait" else Vector2i(768, 432)
	root.gui_embed_subwindows = true
	root.get_node("LanguageSettings").apply_language(args[2], false)
	var main := preload("res://resources/scenes/Main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.5).timeout
	game = main.get_node("GameCenter/Game") as GameManager
	# Late seeded starts are unlocked only inside this disposable capture profile.
	game.best_rounds_left = 1
	game._global_timer_enabled = false
	ScreenSizeOptions.set_screen_size_mode(game, 2)
	await _start(_profile_seed("TRAILER-CLASSIC", 3, 2, 2, 3), {}, [], 3)
	var begin := _time()
	for index in 2:
		await _play_move()
	await create_timer(0.3).timeout
	_finish_segment("gameplay", begin)
	# Select a real seed with several playable neighbors; never change card values.
	for attempt in 24:
		# Try the verified pair first; retain alternatives if the draw policy evolves.
		var seed_attempt := (attempt + 13) % 24
		var seed_text := _profile_seed("TRAILER-FRIENDS-%d" % seed_attempt, 8, 3, 3, 4)
		await _start(seed_text, {&"bring_a_friend": 1}, [], 8)
		if not _find_move(true).is_empty():
			break
	assert(game.bonus_manager.level(&"bring_a_friend") == 1)
	assert(not _find_move(true).is_empty(), "Seed must offer a playable level-one companion")
	begin = _time()
	await _play_move(true)
	await _play_move(true)
	await create_timer(0.35).timeout
	assert(friend_placements >= 1, "Bring a Friend must visibly place a companion")
	_finish_segment("friends", begin)
	await _start(_profile_seed("TRAILER-SHELL-GAME", 15, 5, 4, 5), {}, [&"shell_game"], 15)
	assert(game.round_modifiers.swap_piles_after_play)
	begin = _time()
	for index in 2:
		var previous: Array[Vector2] = []
		for pile in game.piles:
			previous.append(pile.position)
		await _play_move()
		var moved := false
		for pile_index in game.piles.size():
			if game.piles[pile_index].position.distance_to(previous[pile_index]) > 1.0:
				moved = true
		assert(moved, "Shell Game must actually swap piles")
		swaps += 1
	await create_timer(0.35).timeout
	_finish_segment("shell", begin)
	var conveyor := preload("res://resources/data/challenges/05_conveyor_belt.tres") as ChallengeData
	var conveyor_seed := _profile_seed("TRAILER-CONVEYOR", conveyor.start_round, 3, 2, 4)
	await _start(conveyor_seed, {}, [], conveyor.start_round, conveyor)
	assert(game.current_challenge.id == &"conveyor_belt")
	assert(game.challenge_modifiers.conveyor_hand and game._conveyor_active)
	assert(game.hand_tray.conveyor_background.visible and game.hand_tray.conveyor_bottom.visible)
	# Let the real belt fill, then film its natural motion before picking a tile.
	await create_timer(1.4).timeout
	game.timer_manager.stop_countdown()
	begin = _time()
	var observer := game.hand_manager.active_cards()[0]
	var previous_x := observer.global_position.x
	await create_timer(1.0).timeout
	conveyor_distance = previous_x - observer.global_position.x
	assert(conveyor_distance > 20.0, "Conveyor tiles must visibly travel along the belt")
	var placements_before := placements
	for index in 2:
		await _play_move()
	conveyor_placements = placements - placements_before
	assert(conveyor_placements >= 2, "The real conveyor challenge must include successful plays")
	await create_timer(0.6).timeout
	_finish_segment("conveyor", begin)
	var file := FileAccess.open(args[0], FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify({
		"capture_version": 6, "audio": "sfx_only", "friend_level": 1,
		"max_companions": max_companions,
		"conveyor_placements": conveyor_placements, "conveyor_distance": conveyor_distance,
		"segments": segments, "placements": placements,
		"friend_placements": friend_placements, "swaps": swaps,
		"format": args[1], "language": args[2],
	}, "\t"))
	file.close()
	print("Trailer: %d placements, %d companions, %d swaps" % [placements, friend_placements, swaps])
	quit()


func _find_move(require_friend := false) -> Dictionary:
	for candidate in game.hand_manager.active_cards():
		if game.challenge_modifiers.conveyor_hand:
			if candidate.has_meta(&"conveyor_exiting_down"):
				continue
			if not game.get_viewport_rect().encloses(candidate.get_global_rect()):
				continue
		for pile in game.piles:
			if not pile.completed and candidate.card_value == pile.expected_value():
				if require_friend:
					var neighbors := HAND_DRAG.selection_companions(game, candidate)
					if neighbors.is_empty():
						continue
					if game._find_nearby_companion_pile(neighbors[0], pile, []) == null:
						continue
				return {"card": candidate, "pile": pile}
	return {}


func _play_move(with_friends := false) -> void:
	await _wait_ready()
	var move := _find_move(with_friends)
	var deadline := _time() + 8.0
	while move.is_empty() and game.challenge_modifiers.conveyor_hand and _time() < deadline:
		await process_frame
		game.timer_manager.stop_countdown()
		move = _find_move(with_friends)
	if move.is_empty():
		move = _find_move()
	var card := move.get("card") as PlayingCard
	var target := move.get("pile") as MemoryPile
	assert(card != null and target != null)
	var total_before := 0
	for pile in game.piles:
		total_before += pile.current_value
	var origin := card.get_global_rect().get_center()
	var destination := target.get_global_rect().get_center()
	card.drag_target = origin
	game._on_card_drag_started(card, true)
	assert(game.selected_card == card and card.dragging)
	if with_friends:
		assert(game.bonus_manager.level(&"bring_a_friend") == 1)
		assert(game.drag_companions.size() == 1, "Level one carries exactly one neighbor")
		max_companions = maxi(max_companions, game.drag_companions.size())
		print("Friend demo: level=%d, companions=%d, card=%d, piles=%s" % [
			game.bonus_manager.level(&"bring_a_friend"), game.drag_companions.size(),
			card.card_value, game.piles.map(func(pile: MemoryPile): return pile.current_value),
		])
	await create_timer(0.15).timeout
	for frame in 18:
		var weight := float(frame + 1) / 18.0
		weight = weight * weight * (3.0 - 2.0 * weight)
		card.drag_target = origin.lerp(destination, weight)
		await process_frame
	await create_timer(0.15).timeout
	await game._on_card_drag_released(card, destination)
	await _wait_ready()
	var total_after := 0
	for pile in game.piles:
		total_after += pile.current_value
	assert(total_after < total_before, "A filmed drag must actually place its card")
	placements += total_before - total_after
	if with_friends:
		friend_placements += maxi(0, total_before - total_after - 1)
