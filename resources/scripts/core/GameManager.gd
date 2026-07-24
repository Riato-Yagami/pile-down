class_name GameManager
extends Control

signal card_placed(card, pile)
signal mistake_made()
signal round_completed()
signal game_over()

const PILE_SCENE := preload("res://resources/scenes/Pile.tscn")
const Difficulty := preload("res://resources/scripts/core/difficulty.gd")
const Debug := preload("res://resources/scripts/core/debug.gd")

@onready var piles_board: Control = %PilesBoard
@onready var hand_container: HBoxContainer = %HandContainer
@onready var drag_layer: Control = %DragLayer
@onready var hand_manager: HandManager = %HandManager
@onready var timer_manager: CountdownManager = %TimerManager
@onready var timer_label: Label = %TimerLabel
@onready var timer_ring: CountdownRing = %TimerRing
@onready var round_label: Label = %RoundLabel
@onready var run_time_label: Label = %RunTimeLabel
@onready var mistakes_dots: RoundDots = %MistakesDots
@onready var transient_label: Label = %TransientLabel
@onready var overlay: Control = %Overlay
@onready var overlay_title: RichTextLabel = %OverlayTitle
@onready var overlay_details: RichTextLabel = %OverlayDetails
@onready var overlay_button: Button = %OverlayButton
@onready var overlay_high_score: RichTextLabel = %OverlayHighScore
@onready var splash: Control = %Splash
@onready var splash_button: Button = %SplashButton
@onready var splash_high_score: Label = %SplashHighScore
@onready var splash_debug_mode: Label = %SplashDebugMode
@onready var soft_audio: SoftAudio = %SoftAudio
@onready var special_rule_manager: SpecialRuleManager = %SpecialRuleManager
@onready var flashlight_overlay: FlashlightOverlay = %FlashlightOverlay

var pile_count: int = Difficulty.START_PILES
var hand_size: int = Difficulty.START_HAND_SIZE
var start_value: int = Difficulty.START_CARD_VALUE
var turn_time: float = Difficulty.START_TURN_TIME
var round_number: int = Difficulty.TOTAL_ROUNDS
var best_rounds_left := -1
var best_score_time_ms := -1
var game_started_msec := 0
var round_reached_time_ms := 0
var mistakes_left := 3
var selected_card: PlayingCard
var piles: Array[MemoryPile] = []
var input_locked := true
var rng := RandomNumberGenerator.new()
var hovered_pile: MemoryPile
var drag_placeholder: Control
var drag_home_index := -1
var overlay_mode := ""
var _last_urgent_second := -1
var round_modifiers := RoundModifiers.new()
var tier_reliefs_applied := 0
var _debug_action_in_progress := false
var _hand_cycle_generation := 0
var _pending_interactive_generation := -1
var _regeneration_hand_check_pending := false


func _ready() -> void:
	rng.randomize()
	hand_manager.card_selected.connect(_on_card_selected)
	hand_manager.card_drag_started.connect(_on_card_drag_started)
	hand_manager.card_drag_released.connect(_on_card_drag_released)
	hand_manager.card_entered_screen.connect(_on_card_entered_screen)
	timer_manager.time_updated.connect(_on_time_updated)
	timer_manager.time_expired.connect(_on_time_expired)
	overlay_button.pressed.connect(_on_overlay_pressed)
	splash_button.pressed.connect(_on_splash_pressed)
	special_rule_manager.rules_announcing.connect(_on_special_rules_announcing)
	resized.connect(_layout_piles)
	_load_high_score()
	splash_debug_mode.visible = Debug.is_enabled()
	input_locked = true
	splash.visible = true


func _process(_delta: float) -> void:
	if run_time_label.visible:
		run_time_label.text = _format_duration(_total_time_milliseconds())
	if _regeneration_hand_check_pending and not input_locked:
		_regeneration_hand_check_pending = false
		_reroll_unplayable_hand()
	if selected_card == null or not is_instance_valid(selected_card) or not selected_card.dragging:
		return
	var candidate := _pile_at(selected_card.drag_target)
	if candidate == hovered_pile:
		return
	if hovered_pile != null and is_instance_valid(hovered_pile):
		hovered_pile.set_drop_feedback(false)
	hovered_pile = candidate
	if hovered_pile != null:
		hovered_pile.set_drop_feedback(true)
		soft_audio.play_tone(520.0, 0.035, 0.035)


func _input(event: InputEvent) -> void:
	if _handle_global_shortcut(event):
		return
	if _handle_debug_shortcut(event):
		get_viewport().set_input_as_handled()
		return
	if round_modifiers.flashlight_enabled:
		if event is InputEventScreenTouch or event is InputEventScreenDrag:
			flashlight_overlay.follow_touch(event.position)
	if selected_card == null or not is_instance_valid(selected_card) or not selected_card.dragging:
		return
	if event is InputEventMouseMotion:
		selected_card.drag_target = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_on_card_drag_released(selected_card, event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		selected_card.drag_target = event.position
	elif event is InputEventScreenTouch and not event.pressed:
		_on_card_drag_released(selected_card, event.position)
		get_viewport().set_input_as_handled()


func _handle_global_shortcut(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	match key_event.keycode:
		KEY_ESCAPE:
			if splash.visible:
				get_tree().quit()
			else:
				get_tree().reload_current_scene()
			return true
		KEY_SPACE:
			if splash.visible or (overlay.visible and overlay_mode == "restart"):
				start_game()
				return true
		KEY_M:
			soft_audio.toggle_mute()
			return true
		KEY_T:
			if not splash.visible and not overlay.visible:
				run_time_label.visible = not run_time_label.visible
				if run_time_label.visible:
					run_time_label.text = _format_duration(_total_time_milliseconds())
				return true
	return false


func _handle_debug_shortcut(event: InputEvent) -> bool:
	if not Debug.is_enabled() or not event is InputEventKey:
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or _debug_action_in_progress:
		return false
	match key_event.keycode:
		KEY_S:
			if input_locked or splash.visible or overlay.visible:
				return false
			_debug_skip_round()
			return true
		KEY_R:
			if input_locked and not splash.visible and not overlay.visible:
				return false
			_debug_reset_game()
			return true
		KEY_H:
			_debug_reset_high_score()
			return true
	return false


func _debug_skip_round() -> void:
	_debug_action_in_progress = true
	input_locked = true
	timer_manager.stop_countdown()
	await _discard_current_hand()
	await _finish_round()
	_debug_action_in_progress = false


func _debug_reset_game() -> void:
	_debug_action_in_progress = true
	input_locked = true
	timer_manager.stop_countdown()
	await special_rule_manager.end_round(piles)
	start_game()
	_debug_action_in_progress = false


func _debug_reset_high_score() -> void:
	best_rounds_left = -1
	best_score_time_ms = -1
	var config := ConfigFile.new()
	if config.load("user://pile_down.cfg") == OK:
		for key in ["best_rounds_left", "best_score_time_ms", "best_time_ms"]:
			if config.has_section_key("progress", key):
				config.erase_section_key("progress", key)
		config.save("user://pile_down.cfg")
	_refresh_high_score()


func start_game() -> void:
	soft_audio.play_start()
	_hand_cycle_generation += 1
	_pending_interactive_generation = -1
	pile_count = Difficulty.START_PILES
	hand_size = Difficulty.START_HAND_SIZE
	start_value = Difficulty.START_CARD_VALUE
	turn_time = Difficulty.START_TURN_TIME
	tier_reliefs_applied = 0
	round_number = (
		Difficulty.TOTAL_ROUNDS
		- Debug.get_start_round(Difficulty.TOTAL_ROUNDS)
		+ 1
	)
	_apply_debug_progression(Debug.get_start_round(Difficulty.TOTAL_ROUNDS))
	game_started_msec = Time.get_ticks_msec()
	round_reached_time_ms = 0
	run_time_label.visible = false
	splash.visible = false
	overlay.visible = false
	overlay_mode = ""
	start_round()


func start_round() -> void:
	input_locked = true
	_regeneration_hand_check_pending = false
	selected_card = null
	hovered_pile = null
	mistakes_left = 3
	_last_urgent_second = -1
	timer_manager.stop_countdown()
	hand_manager.clear_hand(hand_container)
	_clear_drag_placeholder()
	for child in drag_layer.get_children():
		child.queue_free()
	for child in piles_board.get_children():
		child.queue_free()
	piles.clear()
	round_modifiers = await special_rule_manager.begin_round(_progression_round())

	for index in pile_count:
		var pile := PILE_SCENE.instantiate() as MemoryPile
		piles_board.add_child(pile)
		pile.setup(
			index,
			start_value,
			round_modifiers.stack_direction,
			round_modifiers.roman_numerals_enabled
		)
		pile.pile_selected.connect(_on_pile_selected)
		pile.regenerated.connect(_on_pile_regenerated)
		piles.append(pile)
	_layout_piles()
	for index in piles.size():
		piles[index].play_entrance(index * 0.055)
	special_rule_manager.activate_board_effects(piles, _progression_round())
	_update_hud()
	await get_tree().create_timer(0.75 + piles.size() * 0.055).timeout
	for pile in piles:
		if is_instance_valid(pile):
			pile.hide_value(true)
	await get_tree().create_timer(0.26).timeout
	_begin_turn()


func _layout_piles() -> void:
	if piles.is_empty() or piles_board.size.x <= 0.0:
		return
	var piece_size := 37.0
	var gap := 7.0
	var positions := PileLayoutManager.positions_for_2d(pile_count, piece_size, gap)
	var center := piles_board.size * 0.5
	for index in mini(piles.size(), positions.size()):
		var pile := piles[index]
		pile.custom_minimum_size = Vector2(34.0, 37.0)
		pile.size = Vector2(34.0, 37.0)
		pile.position = (center + positions[index] - Vector2(17.0, 18.0)).round()


func _begin_turn(hand_prepared := false) -> void:
	if _all_piles_complete():
		return
	selected_card = null
	input_locked = false
	if not hand_prepared:
		_prepare_next_hand(true, false)
	timer_manager.start_countdown(turn_time)


func _prepare_next_hand(clear_existing: bool, enter_from_right: bool) -> void:
	var wandering_cards := round_modifiers.wandering_hand_cards
	hand_manager.generate_hand(
		drag_layer if wandering_cards else hand_container,
		hand_size,
		start_value,
		_playable_values(),
		round_modifiers.stack_direction == RoundModifiers.StackDirection.UP,
		round_modifiers.hover_reveal_enabled,
		round_modifiers.roman_numerals_enabled,
		not wandering_cards,
		clear_existing,
		enter_from_right
	)
	if wandering_cards:
		_draw_wandering_hand()


func _draw_wandering_hand() -> void:
	var occupied: Array[Rect2] = []
	for pile in piles:
		if is_instance_valid(pile) and not pile.completed:
			occupied.append(pile.get_global_rect().grow(5.0))
	for index in hand_manager.current_cards.size():
		var card := hand_manager.current_cards[index]
		if not is_instance_valid(card):
			continue
		var position_candidate := Vector2.ZERO
		for attempt in 24:
			position_candidate = Vector2(
				rng.randi_range(38, 184),
				rng.randi_range(58, 190)
			)
			var card_rect := Rect2(position_candidate, Vector2(34.0, 37.0))
			if not occupied.any(func(rect: Rect2) -> bool: return rect.intersects(card_rect)):
				break
		card.global_position = position_candidate.round()
		occupied.append(card.get_global_rect().grow(5.0))
		card.play_wandering_entrance(
			index,
			position_candidate.round(),
			size,
			index * 0.055
		)


func _on_card_selected(card: PlayingCard) -> void:
	if not input_locked:
		selected_card = card


func _on_card_entered_screen(card: PlayingCard) -> void:
	if (
		_pending_interactive_generation != _hand_cycle_generation
		or not hand_manager.current_cards.has(card)
	):
		return
	_pending_interactive_generation = -1
	selected_card = null
	input_locked = false
	hand_manager.unlock_hand()
	timer_manager.start_countdown(turn_time)


func _on_card_drag_started(card: PlayingCard) -> void:
	if input_locked:
		return
	selected_card = card
	if round_modifiers.wandering_hand_cards:
		drag_home_index = -1
		_clear_drag_placeholder()
	else:
		drag_home_index = card.get_index()
		drag_placeholder = Control.new()
		drag_placeholder.custom_minimum_size = card.size
		drag_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hand_container.add_child(drag_placeholder)
		hand_container.move_child(drag_placeholder, drag_home_index)
	var start_position := card.global_position
	if card.get_parent() != drag_layer:
		card.reparent(drag_layer, false)
	card.global_position = start_position
	card.begin_external_drag(get_viewport().get_mouse_position())
	soft_audio.play_tone(330.0, 0.045, 0.035)


func _on_card_drag_released(card: PlayingCard, release_position: Vector2) -> void:
	if input_locked or card != selected_card or not card.dragging:
		return
	card.finish_drag()
	var target := _pile_at(release_position)
	if hovered_pile != null and is_instance_valid(hovered_pile):
		hovered_pile.set_drop_feedback(false)
	hovered_pile = null
	if target == null:
		await _return_card_to_hand(card)
		card.set_selectable(true)
	elif target.can_accept(card.card_value):
		await _place_selected_card(target)
	else:
		await _handle_mistake(target)


func _on_pile_selected(_pile: MemoryPile) -> void:
	pass


func _on_pile_regenerated(_pile: MemoryPile, _delta: int) -> void:
	_regeneration_hand_check_pending = true


func _reroll_unplayable_hand() -> void:
	if hand_manager.current_cards.is_empty():
		return
	var playable_values := _playable_values()
	if playable_values.is_empty():
		return
	for card in hand_manager.current_cards:
		if is_instance_valid(card) and card.visible and playable_values.has(card.card_value):
			return

	_hand_cycle_generation += 1
	_pending_interactive_generation = _hand_cycle_generation
	selected_card = null
	input_locked = true
	timer_manager.stop_countdown()
	_start_discard_current_hand()
	_prepare_next_hand(false, true)


func _place_selected_card(pile: MemoryPile) -> void:
	_hand_cycle_generation += 1
	var placement_generation := _hand_cycle_generation
	input_locked = true
	timer_manager.stop_countdown()
	hand_manager.lock_hand()
	var card := selected_card
	var destination := pile.global_position + (pile.size - card.size) * 0.5
	await card.animate_valid_drop(destination)
	pile.place(card.card_value)
	card_placed.emit(card, pile)
	soft_audio.play_tone(610.0, 0.075, 0.055)
	card.visible = false
	card.queue_free()
	_start_discard_current_hand()
	var next_hand_prepared := not _playable_values().is_empty()
	if next_hand_prepared:
		_pending_interactive_generation = placement_generation
		_prepare_next_hand(false, true)

	if pile.is_complete_value():
		soft_audio.play_tone(760.0, 0.14, 0.06)
		await pile.complete_animation()
		await special_rule_manager.after_card_played(piles, _progression_round())
		if _all_piles_complete():
			await _finish_round()
			return
	else:
		await get_tree().create_timer(0.32).timeout
		await pile.hide_value(true)
		await special_rule_manager.after_card_played(piles, _progression_round())
		await get_tree().create_timer(0.12).timeout
	if not next_hand_prepared and placement_generation == _hand_cycle_generation:
		_begin_turn(false)


func _handle_mistake(pile: MemoryPile = null) -> void:
	if input_locked:
		return
	input_locked = true
	timer_manager.stop_countdown()
	hand_manager.lock_hand()
	if not Debug.is_god_mode_enabled():
		mistakes_left -= 1
	mistake_made.emit()
	soft_audio.play_error()
	_update_hud()
	if selected_card != null and is_instance_valid(selected_card) and selected_card.get_parent() == drag_layer:
		await _return_card_to_hand(selected_card, 0.14)
	if mistakes_left <= 0:
		if pile != null and is_instance_valid(pile) and not pile.completed:
			await _reveal_mistake_pile(pile)
		await _discard_current_hand()
		await _finish_game()
	else:
		selected_card = null
		hand_manager.clear_selection()
		input_locked = false
		hand_manager.unlock_hand()
		timer_manager.start_countdown(turn_time)
		if pile != null and is_instance_valid(pile) and not pile.completed:
			_reveal_mistake_pile(pile)


func _reveal_mistake_pile(pile: MemoryPile) -> void:
	await pile.flash_invalid()
	if is_instance_valid(pile) and not pile.completed:
		await pile.reveal_value_temporarily(0.65)


func _return_card_to_hand(card: PlayingCard, duration := 0.26) -> void:
	var destination := drag_placeholder.global_position if is_instance_valid(drag_placeholder) else card.home_global_position
	await card.animate_return(destination, duration)
	if round_modifiers.wandering_hand_cards:
		_clear_drag_placeholder()
		card.scale = Vector2.ONE
		card.set_selectable(not input_locked)
		card.enable_wandering(maxi(hand_manager.current_cards.find(card), 0), true)
		return
	var old_global := card.global_position
	card.reparent(hand_container, false)
	hand_container.move_child(card, clampi(drag_home_index, 0, hand_container.get_child_count() - 1))
	card.global_position = old_global
	_clear_drag_placeholder()
	card.scale = Vector2.ONE
	card.position.y = 0.0
	card.set_selectable(not input_locked)
	if round_modifiers.wandering_hand_cards:
		card.call_deferred("enable_wandering", maxi(card.get_index(), 0))


func _clear_drag_placeholder() -> void:
	if is_instance_valid(drag_placeholder):
		drag_placeholder.queue_free()
	drag_placeholder = null
	drag_home_index = -1


func _discard_current_hand() -> void:
	await hand_manager.discard_hand(hand_container, drag_layer)
	_clear_drag_placeholder()


func _start_discard_current_hand() -> void:
	hand_manager.discard_hand(hand_container, drag_layer)
	_clear_drag_placeholder()


func _pile_at(global_point: Vector2) -> MemoryPile:
	for pile in piles:
		if not pile.completed and pile.visible and pile.get_global_rect().grow(8.0).has_point(global_point):
			return pile
	return null


func _on_time_expired() -> void:
	if input_locked:
		return
	await _handle_mistake()


func _finish_round() -> void:
	input_locked = true
	timer_manager.stop_countdown()
	await special_rule_manager.end_round(piles)
	round_completed.emit()
	soft_audio.play_tone(680.0, 0.16, 0.055)
	await _show_round_wave()
	round_number -= 1
	round_reached_time_ms = _total_time_milliseconds()
	_update_hud()
	if round_number <= 0:
		await _finish_game(true)
		return
	var change := _advance_difficulty(_progression_round())
	if change.is_empty():
		start_round()
		return
	transient_label.text = change
	transient_label.visible = true
	transient_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(transient_label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(0.75)
	tween.tween_property(transient_label, "modulate:a", 0.0, 0.2)
	await tween.finished
	transient_label.visible = false
	start_round()


func _show_round_wave() -> void:
	var wave := %RoundWave as Control
	wave.visible = true
	wave.scale = Vector2(0.2, 0.2)
	wave.modulate.a = 0.45
	var tween := create_tween().set_parallel()
	tween.tween_property(wave, "scale", Vector2(2.4, 2.4), 0.55)
	tween.tween_property(wave, "modulate:a", 0.0, 0.55)
	await tween.finished
	wave.visible = false


func _finish_game(completed_all_rounds := false) -> void:
	input_locked = true
	timer_manager.stop_countdown()
	await special_rule_manager.end_round(piles)
	if completed_all_rounds:
		soft_audio.play_victory()
	else:
		soft_audio.play_game_over()
	var formatted_time := _format_duration(round_reached_time_ms)
	var high_score_kind := _update_high_score(round_number, round_reached_time_ms)
	game_over.emit()
	overlay_high_score.visible = not high_score_kind.is_empty()
	if not high_score_kind.is_empty():
		var rounds_text := "%d ROUNDS LEFT" % round_number
		var time_text := "in %s" % formatted_time
		if high_score_kind == "ROUND":
			rounds_text = "[color=#4D82C2]%s[/color]" % rounds_text
		else:
			time_text = "[color=#4D82C2]%s[/color]" % time_text
		overlay_title.text = "[center]%s[/center]" % rounds_text
		overlay_details.text = "[center]%s[/center]" % time_text
	elif completed_all_rounds:
		overlay_title.text = "[center]YOU WON[/center]"
		overlay_details.text = "[center]in %s[/center]" % formatted_time
	else:
		overlay_title.text = "[center]%d ROUNDS LEFT[/center]" % round_number
		overlay_details.text = "[center]in %s[/center]" % formatted_time
	overlay_button.text = "REPLAY"
	overlay_mode = "restart"
	overlay.visible = true


func _on_overlay_pressed() -> void:
	if overlay_mode == "restart":
		start_game()


func _on_splash_pressed() -> void:
	start_game()


func _on_special_rules_announcing(_rules: Array[SpecialRuleData]) -> void:
	soft_audio.play_special_rule()


func _increase_difficulty(first_upgrade_override := -1) -> String:
	var first_upgrade := (
		first_upgrade_override == 1
		if first_upgrade_override >= 0
		else round_number == Difficulty.TOTAL_ROUNDS - 1
	)
	var options: Array[String] = []
	var weights: Array[float] = []
	var pile_weight := (
		Difficulty.FIRST_ADD_PILE_WEIGHT
		if first_upgrade
		else Difficulty.ADD_PILE_WEIGHT
	)
	var card_weight := (
		Difficulty.FIRST_ADD_CARD_WEIGHT
		if first_upgrade
		else Difficulty.ADD_CARD_WEIGHT
	)
	if pile_count < Difficulty.MAX_PILES and (first_upgrade or pile_weight > 0.0):
		options.append("pile")
		weights.append(maxf(pile_weight, 0.0))
	if hand_size < Difficulty.MAX_HAND_SIZE and (first_upgrade or card_weight > 0.0):
		options.append("main")
		weights.append(maxf(card_weight, 0.0))
	if (
		not first_upgrade
		and start_value < Difficulty.MAX_CARD_VALUE
		and Difficulty.ADD_START_VALUE_WEIGHT > 0.0
	):
		options.append("valeur")
		weights.append(Difficulty.ADD_START_VALUE_WEIGHT)
	if (
		not first_upgrade
		and turn_time > Difficulty.MIN_TURN_TIME
		and Difficulty.REDUCE_TURN_TIME_WEIGHT > 0.0
	):
		options.append("temps")
		weights.append(Difficulty.REDUCE_TURN_TIME_WEIGHT)
	if Difficulty.NO_DIFFICULTY_CHANGE_WEIGHT > 0.0:
		options.append("none")
		weights.append(Difficulty.NO_DIFFICULTY_CHANGE_WEIGHT)
	if options.is_empty():
		return ""
	var total := 0.0
	for weight in weights:
		total += weight
	if total <= 0.0:
		weights.fill(1.0)
		total = float(weights.size())
	var roll := rng.randf_range(0.0, total)
	var choice := options[0]
	for index in options.size():
		roll -= weights[index]
		if roll <= 0.0:
			choice = options[index]
			break
	match choice:
		"pile":
			pile_count += 1
			return "+1 PILE"
		"main":
			hand_size += 1
			return "+1 CARD"
		"valeur":
			start_value += 1
			return "+1 START VALUE"
		"temps":
			turn_time -= 1.0
			return "-1 SECOND"
		"none":
			return ""
	return ""


func _advance_difficulty(next_progression_round: int, first_upgrade_override := -1) -> String:
	if not _is_special_tier_relief_round(next_progression_round):
		return _increase_difficulty(first_upgrade_override)
	_apply_special_tier_relief()
	return "TIER RELIEF"


func _is_special_tier_relief_round(progression_round: int) -> bool:
	# Reliefs keep following the combo milestone curve after the five-rule cap.
	var theoretical_rule_count := 2
	while true:
		var milestone := Difficulty.special_rule_milestone(
			theoretical_rule_count
		)
		if milestone >= progression_round:
			return milestone == progression_round
		theoretical_rule_count += 1
	return false


func _apply_special_tier_relief() -> void:
	var relief_count := mini(tier_reliefs_applied + 1, 4)
	var stats: Array[StringName] = [&"piles", &"hand", &"value", &"time"]
	for index in range(stats.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary := stats[index]
		stats[index] = stats[swap_index]
		stats[swap_index] = temporary
	for index in relief_count:
		match stats[index]:
			&"piles":
				pile_count = maxi(pile_count - 1, Difficulty.START_PILES)
			&"hand":
				hand_size = maxi(hand_size - 1, Difficulty.START_HAND_SIZE)
			&"value":
				start_value = maxi(start_value - 1, Difficulty.START_CARD_VALUE)
			&"time":
				turn_time = minf(turn_time + 1.0, Difficulty.START_TURN_TIME)
	tier_reliefs_applied += 1


func _apply_debug_progression(start_round: int) -> void:
	for completed_round in range(1, start_round):
		_advance_difficulty(
			completed_round + 1,
			1 if completed_round == 1 else 0
		)


func _playable_values() -> Array[int]:
	var values: Array[int] = []
	for pile in piles:
		if not pile.completed and not pile.is_complete_value():
			var expected := pile.expected_value()
			if not values.has(expected):
				values.append(expected)
	return values


func _all_piles_complete() -> bool:
	for pile in piles:
		if not pile.completed:
			return false
	return not piles.is_empty()


func _on_time_updated(time_left: float) -> void:
	timer_label.text = RoundModifiers.format_value(
		ceili(time_left),
		round_modifiers.roman_numerals_enabled
	)
	timer_ring.set_ratio(timer_manager.ratio())
	var urgent := time_left <= 1.0 and time_left > 0.0
	if urgent:
		var pulse := (sin(Time.get_ticks_msec() * 0.018) + 1.0) * 0.5
		timer_ring.modulate = Color.WHITE.lerp(Color("#E06455"), pulse * 0.35)
		var second := ceili(time_left * 4.0)
		if second != _last_urgent_second:
			_last_urgent_second = second
			soft_audio.play_tone(420.0, 0.025, 0.018)
	else:
		timer_ring.modulate = Color.WHITE


func _update_hud() -> void:
	round_label.text = RoundModifiers.format_value(
		round_number,
		round_modifiers.roman_numerals_enabled
	)
	mistakes_dots.set_remaining(mistakes_left)


func _total_time_milliseconds() -> int:
	return maxi(Time.get_ticks_msec() - game_started_msec, 0)


func _format_duration(total_msec: int) -> String:
	var milliseconds := total_msec % 1000
	var total_seconds := total_msec / 1000
	var seconds := total_seconds % 60
	var total_minutes := total_seconds / 60
	var minutes := total_minutes % 60
	var hours := total_minutes / 60
	var parts := PackedStringArray()
	if hours > 0:
		parts.append("%d h" % hours)
	if total_minutes > 0:
		parts.append("%d min" % minutes)
	parts.append("%d s" % seconds)
	parts.append("%03d ms" % milliseconds)
	return " ".join(parts)


func _update_high_score(rounds_left: int, elapsed_time_ms: int) -> String:
	var is_better_progress := best_rounds_left < 0 or rounds_left < best_rounds_left
	var is_faster_tie := (
		rounds_left == best_rounds_left
		and (best_score_time_ms < 0 or elapsed_time_ms < best_score_time_ms)
	)
	if not is_better_progress and not is_faster_tie:
		return ""
	best_rounds_left = rounds_left
	best_score_time_ms = elapsed_time_ms
	_save_high_score()
	_refresh_high_score()
	return "ROUND" if is_better_progress else "TIME"


func _save_high_score() -> void:
	var config := ConfigFile.new()
	config.load("user://pile_down.cfg")
	config.set_value("progress", "best_rounds_left", best_rounds_left)
	config.set_value("progress", "best_score_time_ms", best_score_time_ms)
	if best_rounds_left == 0:
		config.set_value("progress", "best_time_ms", best_score_time_ms)
	config.save("user://pile_down.cfg")


func _load_high_score() -> void:
	var config := ConfigFile.new()
	if config.load("user://pile_down.cfg") == OK:
		if config.has_section_key("progress", "best_rounds_left"):
			best_rounds_left = int(config.get_value("progress", "best_rounds_left", -1))
			best_score_time_ms = int(config.get_value("progress", "best_score_time_ms", -1))
		else:
			var legacy_best_time := int(config.get_value("progress", "best_time_ms", 0))
			if legacy_best_time > 0:
				best_rounds_left = 0
				best_score_time_ms = legacy_best_time
	_refresh_high_score()


func _refresh_high_score() -> void:
	if best_rounds_left < 0 or best_score_time_ms < 0:
		splash_high_score.text = "HIGH SCORE\n--"
		return
	splash_high_score.text = "HIGH SCORE\n%d ROUNDS LEFT\nIN %s" % [
		best_rounds_left,
		_format_duration(best_score_time_ms),
	]


func _progression_round() -> int:
	return Difficulty.TOTAL_ROUNDS - round_number + 1
