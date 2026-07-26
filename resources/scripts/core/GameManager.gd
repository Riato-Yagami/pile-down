class_name GameManager
extends Control

signal card_placed(card, pile)
signal mistake_made()
signal round_completed()
signal game_over()

enum GameMode {
	STANDARD,
	ENDLESS,
}

const PILE_SCENE := preload("res://resources/scenes/Pile.tscn")
const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")
const Debug := preload("res://resources/scripts/settings/debug.gd")
const MUSIC_BUS_NAME := &"Music"
const SFX_BUS_NAME := &"SFX"
const AUDIO_CONFIG_PATH := "user://pile_down.cfg"
const DEATH_POPUP_DELAY := 0.35
const URGENT_TICK_THRESHOLDS: Array[float] = [
	2.0,
	1.6667,
	1.3333,
	1.0,
	0.8333,
	0.6667,
	0.5,
	0.3333,
	0.1667,
	0.0,
]

@onready var piles_board: Control = %PilesBoard
@onready var hand_container: HBoxContainer = %HandContainer
@onready var hand_tray: TextureRect = %HandTray
@onready var drag_layer: Control = %DragLayer
@onready var hand_manager: HandManager = %HandManager
@onready var pile_manager: PileManager = %PileManager
@onready var timer_manager: CountdownManager = %TimerManager
@onready var timer_label: Label = %TimerLabel
@onready var timer_ring: CountdownRing = %TimerRing
@onready var round_panel: TextureRect = %RoundPanel
@onready var round_label: Label = %RoundLabel
@onready var run_time_label: Label = %RunTimeLabel
@onready var mistakes_dots: RoundDots = %MistakesDots
@onready var transient_label: Label = %TransientLabel
@onready var overlay: Control = %Overlay
@onready var overlay_title: RichTextLabel = %OverlayTitle
@onready var overlay_details: RichTextLabel = %OverlayDetails
@onready var overlay_button: Button = %OverlayButton
@onready var overlay_endless_button: Button = %OverlayEndlessButton
@onready var overlay_high_score: RichTextLabel = %OverlayHighScore
@onready var overlay_scrim: ColorRect = $Overlay/Scrim
@onready var overlay_panel: TextureRect = $Overlay/Center/Panel
@onready var splash: Control = %Splash
@onready var splash_button: Button = %SplashButton
@onready var endless_button: Button = %EndlessButton
@onready var splash_high_score: RichTextLabel = %SplashHighScore
@onready var splash_high_score_time: Label = %SplashHighScoreTime
@onready var splash_debug_mode: Label = %SplashDebugMode
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var sound_volume_slider: HSlider = %SoundVolumeSlider
@onready var debug_help: Label = %DebugHelp
@onready var soft_audio: SoftAudio = %SoftAudio
@onready var music_manager: MusicManager = %MusicManager
@onready var special_rule_manager: SpecialRuleManager = %SpecialRuleManager
@onready var bonus_manager: BonusManager = %BonusManager
@onready var lava_rule_controller: LavaRuleController = %LavaRuleController
@onready var sticky_fingers_controller: StickyFingersRuleController = %StickyFingersRuleController
@onready var mirror_match_controller: MirrorMatchRuleController = %MirrorMatchRuleController
@onready var flashlight_overlay: FlashlightOverlay = %FlashlightOverlay
@onready var lava_layer: Control = %LavaLayer
@onready var redraw_button: RedrawBonusButton = %RedrawButton
@onready var active_bonus_bar: HBoxContainer = %ActiveBonusBar

var pile_count: int = Difficulty.START_PILES
var hand_size: int = Difficulty.START_HAND_SIZE
var start_value: int = Difficulty.START_CARD_VALUE
var turn_time: float = Difficulty.START_TURN_TIME
var round_number: int = Difficulty.TOTAL_ROUNDS
var best_rounds_left := -1
var best_score_time_ms := -1
var endless_unlocked := false
var endless_best_round := -1
var endless_best_time_ms := -1
var game_mode := GameMode.STANDARD
var game_started_msec := 0
var round_reached_time_ms := 0
var mistakes_left := 3
var maximum_mistakes := 3
var selected_card: PlayingCard
var piles: Array[MemoryPile] = []
var input_locked := true
var rng := RandomNumberGenerator.new()
var hovered_pile: MemoryPile
var drag_placeholder: Control
var _hand_slot_placeholders: Dictionary = {}
var drag_home_index := -1
var overlay_mode := ""
var _last_clock_second := -1
var _urgent_tick_index := 0
var _clock_flash_tween: Tween
var _menu_exit_tween: Tween
var round_modifiers := RoundModifiers.new()
var tier_reliefs_applied := 0
var _debug_action_in_progress := false
var _debug_help_enabled := true
var _hand_cycle_generation := 0
var _pending_interactive_generation := -1
var _regeneration_hand_check_pending := false
var _music_volume_before_mute := 100.0
var _sound_volume_before_mute := 100.0
var _timer_display_hidden := false
var _timer_visibility_tween: Tween
var _last_reminder_pile: MemoryPile
var drag_companions: Array[PlayingCard] = []
var _companion_offsets: Dictionary = {}
var _companion_home_positions: Dictionary = {}
var _root_action_id := 0
var moving_pile: MemoryPile
var _moving_pile_offset := Vector2.ZERO
var _moving_pile_last_valid_position := Vector2.ZERO
var _moving_pile_pointer := Vector2.ZERO
var _pile_touch_index := -1
var _pile_touch_local_grab := Vector2.ZERO
var _card_touch_index := -1

@export_category("Start Transition")
@export var menu_swipe_duration := 0.62
@export var gameplay_pop_duration := 0.24
@export var gameplay_pop_stagger := 0.1
@export var gameplay_pop_scale := 0.82


func _ready() -> void:
	rng.randomize()
	hand_manager.card_selected.connect(_on_card_selected)
	hand_manager.card_drag_started.connect(_on_card_drag_started)
	hand_manager.card_drag_released.connect(_on_card_drag_released)
	hand_manager.card_entered_screen.connect(_on_card_entered_screen)
	hand_manager.card_forced_return_requested.connect(_on_card_forced_return_requested)
	lava_rule_controller.card_entered_lava.connect(_on_lava_card_entered)
	timer_manager.time_updated.connect(_on_time_updated)
	timer_manager.time_expired.connect(_on_time_expired)
	timer_manager.timer_visibility_requested.connect(_on_timer_visibility_requested)
	overlay_button.pressed.connect(_on_overlay_pressed)
	overlay_endless_button.pressed.connect(_on_overlay_endless_pressed)
	splash_button.pressed.connect(_on_splash_pressed)
	endless_button.pressed.connect(_on_endless_pressed)
	endless_button.mouse_entered.connect(_show_endless_high_score)
	endless_button.mouse_exited.connect(_refresh_high_score)
	endless_button.focus_entered.connect(_show_endless_high_score)
	endless_button.focus_exited.connect(_refresh_high_score)
	special_rule_manager.rules_announcing.connect(_on_special_rules_announcing)
	special_rule_manager.rules_announcement_finished.connect(
		_on_special_rules_announcement_finished
	)
	redraw_button.pressed.connect(_on_redraw_pressed)
	resized.connect(_layout_piles)
	_setup_audio_controls()
	_load_high_score()
	splash_debug_mode.visible = Debug.is_enabled()
	_refresh_debug_help()
	input_locked = true
	splash.visible = true


func _setup_audio_controls() -> void:
	var config := ConfigFile.new()
	config.load(AUDIO_CONFIG_PATH)
	music_volume_slider.set_value_no_signal(
		float(config.get_value("audio", "music_volume", 1.0)) * 100.0
	)
	sound_volume_slider.set_value_no_signal(
		float(config.get_value("audio", "sound_volume", 1.0)) * 100.0
	)
	if music_volume_slider.value > 0.0:
		_music_volume_before_mute = music_volume_slider.value
	if sound_volume_slider.value > 0.0:
		_sound_volume_before_mute = sound_volume_slider.value
	music_volume_slider.value_changed.connect(
		_on_volume_changed.bind(MUSIC_BUS_NAME, "music_volume")
	)
	sound_volume_slider.value_changed.connect(
		_on_volume_changed.bind(SFX_BUS_NAME, "sound_volume")
	)
	_apply_bus_volume(MUSIC_BUS_NAME, music_volume_slider.value / 100.0)
	_apply_bus_volume(SFX_BUS_NAME, sound_volume_slider.value / 100.0)


func _on_volume_changed(value: float, bus_name: StringName, config_key: String) -> void:
	var linear_volume := value / 100.0
	_apply_bus_volume(bus_name, linear_volume)
	var config := ConfigFile.new()
	config.load(AUDIO_CONFIG_PATH)
	config.set_value("audio", config_key, linear_volume)
	config.save(AUDIO_CONFIG_PATH)


func _apply_bus_volume(bus_name: StringName, linear_volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(
		bus_index,
		linear_to_db(maxf(linear_volume, 0.0001))
	)
	AudioServer.set_bus_mute(bus_index, is_zero_approx(linear_volume))


func _process(_delta: float) -> void:
	debug_help.visible = (
		Debug.is_enabled()
		and _debug_help_enabled
		and not splash.visible
		and not overlay.visible
	)
	if run_time_label.visible:
		run_time_label.text = _format_duration(_total_time_milliseconds())
	if _regeneration_hand_check_pending and not input_locked:
		_regeneration_hand_check_pending = false
		_reroll_unplayable_hand()
	if (
		moving_pile != null
		and is_instance_valid(moving_pile)
		and _pile_touch_index < 0
	):
		moving_pile.global_position = (
			_moving_pile_pointer - _moving_pile_offset
		).round()
	if selected_card == null or not is_instance_valid(selected_card) or not selected_card.dragging:
		return
	for companion in drag_companions:
		if is_instance_valid(companion):
			companion.global_position = (
				selected_card.global_position
				+ (_companion_offsets.get(companion, Vector2.ZERO) as Vector2)
			).round()
	if round_modifiers.floor_is_lava_enabled:
		if lava_rule_controller.touches_card(selected_card):
			selected_card.request_forced_return(
				PlayingCard.ForcedReturnReason.LAVA
			)
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
	if _handle_pile_touch_input(event):
		get_viewport().set_input_as_handled()
		return
	if _handle_card_touch_input(event):
		get_viewport().set_input_as_handled()
		return
	if moving_pile != null and is_instance_valid(moving_pile):
		if event is InputEventMouseMotion or event is InputEventScreenDrag:
			_moving_pile_pointer = event.position
			moving_pile.global_position = (event.position - _moving_pile_offset).round()
		elif (
			(event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed)
			or (event is InputEventScreenTouch and not event.pressed)
		):
			_moving_pile_pointer = event.position
			moving_pile.global_position = (
				event.position - _moving_pile_offset
			).round()
			_finish_pile_move()
			get_viewport().set_input_as_handled()
		return
	if selected_card == null or not is_instance_valid(selected_card) or not selected_card.dragging:
		return
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
		and selected_card.drag_state == PlayingCard.DragState.LOCKED_OUT
	):
		var clicked_pile := _pile_at(event.position)
		if clicked_pile != null:
			_on_card_drag_released(selected_card, event.position)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion:
		selected_card.drag_target = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
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
				if not OS.has_feature("web"):
					get_tree().quit()
			else:
				get_tree().reload_current_scene()
			return true
		KEY_SPACE:
			if splash.visible or (overlay.visible and overlay_mode == "restart"):
				start_game(
					game_mode == GameMode.ENDLESS
					if overlay.visible
					else false
				)
				return true
		KEY_M:
			_toggle_audio_sliders()
			return true
		KEY_T:
			if not splash.visible and not overlay.visible:
				run_time_label.visible = not run_time_label.visible
				if run_time_label.visible:
					run_time_label.text = _format_duration(_total_time_milliseconds())
				return true
	return false


func _toggle_audio_sliders() -> void:
	var sliders_are_muted := (
		is_zero_approx(music_volume_slider.value)
		and is_zero_approx(sound_volume_slider.value)
	)
	if sliders_are_muted:
		music_volume_slider.value = _music_volume_before_mute
		sound_volume_slider.value = _sound_volume_before_mute
		return
	_music_volume_before_mute = music_volume_slider.value
	_sound_volume_before_mute = sound_volume_slider.value
	music_volume_slider.value = 0.0
	sound_volume_slider.value = 0.0


func _handle_debug_shortcut(event: InputEvent) -> bool:
	if not Debug.is_enabled() or not event is InputEventKey:
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or _debug_action_in_progress:
		return false
	match key_event.keycode:
		KEY_F1:
			_debug_help_enabled = not _debug_help_enabled
			return true
		KEY_E:
			if splash.visible or overlay.visible or input_locked:
				return false
			_debug_win_round()
			return true
		KEY_S:
			if splash.visible or overlay.visible:
				return false
			music_manager.request_next_section()
			_refresh_debug_help()
			return true
		KEY_G:
			Debug.toggle_god_mode()
			_refresh_debug_help()
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


func _debug_win_round() -> void:
	_debug_action_in_progress = true
	await _finish_round()
	_debug_action_in_progress = false


func _debug_reset_game() -> void:
	_debug_action_in_progress = true
	input_locked = true
	timer_manager.stop_countdown()
	await cleanup_special_rule_state()
	await special_rule_manager.end_round(piles)
	start_game(game_mode == GameMode.ENDLESS)
	_debug_action_in_progress = false


func _debug_reset_high_score() -> void:
	best_rounds_left = -1
	best_score_time_ms = -1
	endless_best_round = -1
	endless_best_time_ms = -1
	var config := ConfigFile.new()
	if config.load("user://pile_down.cfg") == OK:
		for key in [
			"best_rounds_left",
			"best_score_time_ms",
			"best_time_ms",
			"endless_best_round",
			"endless_best_time_ms",
		]:
			if config.has_section_key("progress", key):
				config.erase_section_key("progress", key)
		config.save("user://pile_down.cfg")
	_refresh_high_score()


func _refresh_debug_help() -> void:
	if not Debug.is_enabled():
		debug_help.visible = false
		return
	debug_help.text = (
		"[E] WIN CURRENT ROUND\n"
		+ "[S] NEXT MUSIC SECTION\n"
		+ "[G] GOD MODE: %s\n" % ("ON" if Debug.is_god_mode_enabled() else "OFF")
		+ "[R] RESET GAME\n"
		+ "[H] CLEAR HIGH SCORE\n"
		+ "[T] SHOW RUN TIME\n"
		+ "[M] MUTE AUDIO\n"
		+ "[F1] HIDE DEBUG HELP\n"
		+ "[ESC] BACK TO MENU"
	)


func start_game(endless_mode := false) -> void:
	var animate_menu_exit := splash.visible
	game_mode = GameMode.ENDLESS if endless_mode else GameMode.STANDARD
	soft_audio.play_start()
	music_manager.set_low_pass_enabled(false, true)
	_hand_cycle_generation += 1
	_pending_interactive_generation = -1
	pile_count = Difficulty.START_PILES
	hand_size = Difficulty.START_HAND_SIZE
	start_value = Difficulty.START_CARD_VALUE
	turn_time = Difficulty.START_TURN_TIME
	tier_reliefs_applied = 0
	if game_mode == GameMode.ENDLESS:
		round_number = 1
	else:
		var debug_start_round := Debug.get_start_round(Difficulty.TOTAL_ROUNDS)
		round_number = Difficulty.TOTAL_ROUNDS - debug_start_round + 1
		_apply_debug_progression(debug_start_round)
	music_manager.reset_game_sections(tier_reliefs_applied + 1)
	music_manager.transition_to_game_music()
	game_started_msec = Time.get_ticks_msec()
	round_reached_time_ms = 0
	run_time_label.visible = false
	overlay.visible = false
	overlay_mode = ""
	bonus_manager.begin_run()
	if animate_menu_exit:
		_prepare_gameplay_start_reveal()
		_update_hud()
		_finish_animated_game_start()
	else:
		splash.visible = false
		start_round()


func _finish_animated_game_start() -> void:
	await _play_start_game_transition()
	start_round()


func _prepare_gameplay_start_reveal() -> void:
	for element in _start_transition_elements():
		element.pivot_offset = element.size * 0.5
		element.modulate.a = 0.0
		element.scale = Vector2.ONE * gameplay_pop_scale


func _play_start_game_transition() -> void:
	if _menu_exit_tween != null and _menu_exit_tween.is_valid():
		_menu_exit_tween.kill()
	var splash_origin := splash.position
	_menu_exit_tween = (
		create_tween()
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_IN)
	)
	_menu_exit_tween.tween_property(
		splash,
		"position:y",
		splash_origin.y + size.y + 8.0,
		menu_swipe_duration
	)
	var elements := _start_transition_elements()
	for index in elements.size():
		var element := elements[index]
		var reveal := (
			element.create_tween()
			.set_parallel()
			.set_trans(Tween.TRANS_BACK)
			.set_ease(Tween.EASE_OUT)
		)
		reveal.tween_property(
			element,
			"modulate:a",
			1.0,
			gameplay_pop_duration
		).set_delay(index * gameplay_pop_stagger)
		reveal.tween_property(
			element,
			"scale",
			Vector2.ONE,
			gameplay_pop_duration
		).set_delay(index * gameplay_pop_stagger)
	await _menu_exit_tween.finished
	splash.visible = false
	splash.position = splash_origin


func _start_transition_elements() -> Array[Control]:
	return [timer_ring, round_panel, piles_board, hand_tray]


func start_round() -> void:
	input_locked = true
	sticky_fingers_controller.end_round()
	mirror_match_controller.end_round(self)
	_regeneration_hand_check_pending = false
	selected_card = null
	hovered_pile = null
	maximum_mistakes = 3
	_last_clock_second = -1
	_urgent_tick_index = 0
	timer_manager.stop_countdown()
	hand_manager.clear_hand(hand_container)
	_clear_drag_placeholder()
	for child in drag_layer.get_children():
		child.queue_free()
	for child in piles_board.get_children():
		child.queue_free()
	piles.clear()
	_last_reminder_pile = null
	bonus_manager.begin_round()
	round_modifiers = await special_rule_manager.begin_round(_progression_round())
	var rule_intensity := bonus_manager.adaptation_multiplier()
	if round_modifiers.hot_potatoes_enabled:
		round_modifiers.hot_potato_drag_duration /= rule_intensity
	sticky_fingers_controller.begin_round(
		round_modifiers.sticky_fingers_enabled
	)
	if round_modifiers.mirror_match_enabled:
		mirror_match_controller.begin_round(self, round_modifiers)
	maximum_mistakes = (
		round_modifiers.maximum_mistakes_override
		if round_modifiers.maximum_mistakes_override > 0
		else 3 + bonus_manager.spare_lives()
	)
	mistakes_left = maximum_mistakes
	mistakes_dots.set_maximum(maximum_mistakes)
	mistakes_dots.set_reinforced_count(
		0
		if round_modifiers.sudden_death_enabled
		else bonus_manager.spare_lives()
	)
	mistakes_dots.set_safety_net_active(
		bonus_manager.safety_net_available
	)

	for index in pile_count:
		var pile := PILE_SCENE.instantiate() as MemoryPile
		piles_board.add_child(pile)
		pile.setup(
			index,
			start_value,
			round_modifiers.stack_direction,
			round_modifiers.roman_numerals_enabled,
			round_modifiers.colorblind_enabled
		)
		pile.pile_selected.connect(_on_pile_selected)
		pile.drag_requested.connect(_on_pile_drag_requested)
		pile.drag_released.connect(_on_pile_drag_released)
		pile.regenerated.connect(_on_pile_regenerated)
		piles.append(pile)
	_layout_piles()
	for index in piles.size():
		piles[index].play_entrance(index * 0.055)
	var open_book_count := bonus_manager.level(&"open_book")
	if open_book_count > 0:
		var open_book_candidates := piles.duplicate()
		open_book_candidates.shuffle()
		for index in mini(open_book_count, open_book_candidates.size()):
			open_book_candidates[index].keep_face_up = true
	special_rule_manager.activate_board_effects(piles, _progression_round())
	if round_modifiers.floor_is_lava_enabled:
		lava_rule_controller.generate(
			_progression_round(),
			piles,
			hand_container,
			timer_ring,
			lava_layer,
			rng
		)
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
	var slots: Array[Vector2] = []
	for index in mini(piles.size(), positions.size()):
		var pile := piles[index]
		pile.custom_minimum_size = Vector2(34.0, 37.0)
		pile.size = Vector2(34.0, 37.0)
		pile.position = (center + positions[index] - Vector2(17.0, 18.0)).round()
		slots.append(pile.position)
	pile_manager.configure(piles_board, piles, slots)


func _begin_turn(hand_prepared := false, enter_from_right := false) -> void:
	if _all_piles_complete():
		return
	selected_card = null
	input_locked = true
	if not hand_prepared:
		if enter_from_right:
			_generate_next_hand(_hand_cycle_generation, true, true)
		else:
			await _prepare_next_hand(true, false)
	if bonus_manager.has_bonus(&"quick_peek"):
		return
	if enter_from_right:
		_pending_interactive_generation = _hand_cycle_generation
		# Deferred entrance methods mark themselves running after layout. Wait
		# one frame before deciding that a hand contains retained cards only.
		await get_tree().process_frame
		if _pending_interactive_generation != _hand_cycle_generation:
			return
		if not hand_manager.current_cards.any(
			func(card: PlayingCard) -> bool:
				return (
					is_instance_valid(card)
					and card._entrance_animation_running
				)
		):
			_pending_interactive_generation = -1
			input_locked = false
			hand_manager.unlock_hand()
		return
	input_locked = false
	hand_manager.unlock_hand()


func _prepare_next_hand(clear_existing: bool, enter_from_right: bool) -> void:
	var requested_generation := _hand_cycle_generation
	await music_manager.wait_for_next_hand_beat()
	_generate_next_hand(requested_generation, clear_existing, enter_from_right)


func _generate_next_hand(
	requested_generation: int,
	clear_existing: bool,
	enter_from_right: bool
) -> void:
	if requested_generation != _hand_cycle_generation or _all_piles_complete():
		return
	var wandering_cards := round_modifiers.wandering_hand_cards
	if clear_existing:
		_clear_all_hand_slot_placeholders()
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
		enter_from_right,
		round_modifiers,
		bonus_manager.joker_chance(),
		bonus_manager.consume_forced_joker(),
		bonus_manager.lucky_hand_chance()
	)
	if wandering_cards:
		_draw_wandering_hand()
	redraw_button.visible = bonus_manager.redraws_left > 0 and not wandering_cards
	redraw_button.set_remaining(
		bonus_manager.redraws_left,
		bonus_manager.level(&"redraw") >= 2
	)
	if bonus_manager.has_bonus(&"quick_peek"):
		input_locked = true
		hand_manager.lock_hand()
		call_deferred("_run_quick_peek")
	else:
		_start_turn_countdown(bonus_manager.next_hand_time(turn_time))


func _draw_wandering_hand() -> void:
	var occupied: Array[Rect2] = []
	for pile in piles:
		if is_instance_valid(pile) and not pile.completed:
			occupied.append(pile.get_global_rect().abs().grow(5.0))
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
		occupied.append(card.get_global_rect().abs().grow(5.0))
		card.play_wandering_entrance(
			index,
			position_candidate.round(),
			size,
			index * 0.055
		)


func _on_card_selected(card: PlayingCard) -> void:
	if input_locked:
		return
	if (
		selected_card == card
		and card.drag_state == PlayingCard.DragState.LOCKED_OUT
	):
		return
	if (
		selected_card != null
		and is_instance_valid(selected_card)
		and selected_card != card
		and (
			selected_card.drag_state == PlayingCard.DragState.LOCKED_OUT
			or selected_card.dragging
			or selected_card._drag_starting
			or selected_card.get_parent() == drag_layer
		)
	):
		hand_manager.select_card(selected_card)
		return
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


func _on_card_drag_started(card: PlayingCard) -> void:
	if input_locked:
		return
	# A single hand may only own one drag transition. Without this guard,
	# rapid presses can reparent several cards before the first release and
	# leave them outside the container's layout.
	if card.drag_state != PlayingCard.DragState.IDLE or card._drag_starting:
		return
	if (
		selected_card != null
		and is_instance_valid(selected_card)
		and selected_card != card
		and (
			selected_card.dragging
			or selected_card._drag_starting
			or selected_card.get_parent() == drag_layer
		)
	):
		card.flash_error()
		return
	# A Sticky Fingers card remains under the pointer. Every click therefore
	# reaches its button again, but must not create another hand placeholder.
	if (
		selected_card == card
		and card.drag_state == PlayingCard.DragState.LOCKED_OUT
	):
		return
	if (
		selected_card != null
		and is_instance_valid(selected_card)
		and selected_card != card
		and selected_card.drag_state == PlayingCard.DragState.LOCKED_OUT
	):
		card.flash_error()
		return
	selected_card = card
	if round_modifiers.wandering_hand_cards:
		drag_home_index = -1
		_clear_drag_placeholder()
	else:
		_remove_orphan_drag_placeholders()
		drag_home_index = card.get_index()
		drag_placeholder = _create_hand_slot_placeholder(card)
	hand_manager.lock_all_cards_except(card)
	_prepare_drag_companions(card)
	card.prepare_external_drag()
	var start_position := card.global_position
	if card.get_parent() != drag_layer:
		card.reparent(drag_layer, false)
	card.global_position = start_position
	card.begin_external_drag(card.drag_target)
	soft_audio.play_tone(330.0, 0.045, 0.035)


func _prepare_drag_companions(main_card: PlayingCard) -> void:
	drag_companions.clear()
	_companion_offsets.clear()
	_companion_home_positions.clear()
	var level := bonus_manager.level(&"bring_a_friend")
	if level <= 0 or round_modifiers.wandering_hand_cards:
		return
	var cards := hand_manager.active_cards()
	var main_index := cards.find(main_card)
	if main_index < 0:
		return
	var candidates: Array[PlayingCard] = []
	if level == 1:
		if main_index + 1 < cards.size():
			candidates.append(cards[main_index + 1])
		elif main_index > 0:
			candidates.append(cards[main_index - 1])
	elif level == 2:
		if main_index > 0:
			candidates.append(cards[main_index - 1])
		if main_index + 1 < cards.size():
			candidates.append(cards[main_index + 1])
	else:
		for card in cards:
			if card != main_card:
				candidates.append(card)
	for index in candidates.size():
		var companion := candidates[index]
		_companion_home_positions[companion] = companion.hand_return_position()
		_create_hand_slot_placeholder(companion)
		companion.set_selectable(false)
		companion.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var start_position := companion.global_position
		companion.reparent(drag_layer, false)
		companion.global_position = start_position
		drag_layer.move_child(companion, 0)
		drag_companions.append(companion)
		var centered_x := (float(index) - float(candidates.size() - 1) * 0.5) * 23.0
		_companion_offsets[companion] = Vector2(centered_x, 16.0 + absf(centered_x) * 0.08)


func _resolve_companion_drops(anchor_pile: MemoryPile) -> Array[MemoryPile]:
	var placed_piles: Array[MemoryPile] = []
	var companions := drag_companions.duplicate()
	drag_companions.clear()
	for companion_variant in companions:
		var companion := companion_variant as PlayingCard
		if not is_instance_valid(companion) or companion.placement_confirmed:
			continue
		var target := _find_nearby_companion_pile(
			companion, anchor_pile, placed_piles
		)
		if target != null:
			await _stack_card(
				companion, target,
				PlacementContext.new(PlacementContext.Source.BRING_A_FRIEND, _root_action_id)
			)
			placed_piles.append(target)
		else:
			await _return_companion_to_hand(companion)
	hand_container.queue_sort()
	await get_tree().process_frame
	_record_stable_hand_layout()
	_companion_offsets.clear()
	_companion_home_positions.clear()
	return placed_piles


func _find_nearby_companion_pile(
	companion: PlayingCard,
	anchor_pile: MemoryPile,
	already_used: Array[MemoryPile]
) -> MemoryPile:
	if anchor_pile == null or not is_instance_valid(anchor_pile):
		return null
	var anchor_center := anchor_pile.global_position + anchor_pile.size * 0.5
	var compatible := pile_manager.find_piles_accepting_value(companion.card_value)
	compatible.erase(anchor_pile)
	for used_pile in already_used:
		compatible.erase(used_pile)
	compatible = compatible.filter(
		func(candidate: MemoryPile) -> bool:
			var candidate_center := candidate.global_position + candidate.size * 0.5
			return (
				candidate_center.distance_to(anchor_center)
				<= Difficulty.BRING_A_FRIEND_NEIGHBOR_RADIUS
			)
	)
	compatible.sort_custom(
		func(first: MemoryPile, second: MemoryPile) -> bool:
			var first_center := first.global_position + first.size * 0.5
			var second_center := second.global_position + second.size * 0.5
			var first_distance := first_center.distance_squared_to(anchor_center)
			var second_distance := second_center.distance_squared_to(anchor_center)
			if is_equal_approx(first_distance, second_distance):
				return first.pile_index < second.pile_index
			return first_distance < second_distance
	)
	return compatible.front() if not compatible.is_empty() else null


func _return_drag_companions() -> void:
	var companions := drag_companions.duplicate()
	drag_companions.clear()
	for companion_variant in companions:
		var companion := companion_variant as PlayingCard
		if is_instance_valid(companion):
			await _return_companion_to_hand(companion)
	hand_container.queue_sort()
	await get_tree().process_frame
	_record_stable_hand_layout()
	_companion_offsets.clear()
	_companion_home_positions.clear()


func _return_companion_to_hand(card: PlayingCard) -> void:
	var destination := (
		_companion_home_positions.get(card, card.hand_return_position()) as Vector2
	)
	var placeholder := _valid_hand_slot_placeholder(card)
	var slot_index := (
		placeholder.get_index()
		if is_instance_valid(placeholder) and placeholder.get_parent() == hand_container
		else -1
	)
	await card.animate_return(destination, 0.2)
	_remove_hand_slot_placeholder(card)
	card.reparent(hand_container, false)
	if slot_index >= 0:
		hand_container.move_child(card, mini(slot_index, hand_container.get_child_count() - 1))
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.reset_hand_pose()
	card.set_selectable(not input_locked)


func _on_card_drag_released(card: PlayingCard, release_position: Vector2) -> void:
	if input_locked or card != selected_card or not card.dragging:
		return
	_card_touch_index = -1
	var target := _pile_at(release_position)
	if hovered_pile != null and is_instance_valid(hovered_pile):
		hovered_pile.set_drop_feedback(false)
	hovered_pile = null
	if target == null:
		if round_modifiers.sticky_fingers_enabled:
			card.keep_attached_to_pointer()
			hand_manager.finish_all_card_entrances(card)
			hand_manager.lock_all_cards_except(card)
			return
		card.finish_drag()
		await _return_drag_companions()
		await _return_card_to_hand(card)
		card.set_selectable(true)
		selected_card = null
		hand_manager.clear_selection()
		hand_manager.unlock_hand()
	elif card.is_joker or target.can_accept(card.card_value):
		card.finish_drag()
		await _place_selected_card(target)
	else:
		card.finish_drag()
		await _return_drag_companions()
		await _handle_mistake(target)


func _on_pile_selected(pile: MemoryPile) -> void:
	if (
		input_locked
		or selected_card == null
		or not is_instance_valid(selected_card)
		or selected_card.drag_state != PlayingCard.DragState.LOCKED_OUT
	):
		return
	_on_card_drag_released(
		selected_card,
		pile.global_position + pile.size * 0.5
	)


func _on_pile_drag_requested(pile: MemoryPile, pointer_position: Vector2) -> void:
	if (
		input_locked
		or not bonus_manager.has_bonus(&"pile_mover")
		or selected_card != null
		or pile.completed
		or moving_pile != null
	):
		return
	moving_pile = pile
	_pile_touch_index = -1
	_moving_pile_pointer = pointer_position
	_moving_pile_offset = pointer_position - pile.global_position
	_moving_pile_last_valid_position = pile.position
	special_rule_manager.moving_pile_pattern.begin_manual_move(pile)
	pile.move_to_front()


func _on_pile_drag_released(pile: MemoryPile, pointer_position: Vector2) -> void:
	if pile == moving_pile:
		_moving_pile_pointer = pointer_position
		moving_pile.global_position = (
			pointer_position - _moving_pile_offset
		).round()
		_finish_pile_move()


func _finish_pile_move() -> void:
	if moving_pile == null or not is_instance_valid(moving_pile):
		moving_pile = null
		_pile_touch_index = -1
		return
	var requested_position := moving_pile.position
	moving_pile.position = _nearest_valid_pile_position(
		moving_pile,
		requested_position,
		_moving_pile_last_valid_position
	)
	pile_manager.refresh_slots_from_current_positions()
	special_rule_manager.moving_pile_pattern.finish_manual_move(moving_pile)
	moving_pile = null
	_pile_touch_index = -1


func _nearest_valid_pile_position(
	pile: MemoryPile,
	requested_position: Vector2,
	fallback_position: Vector2
) -> Vector2:
	var movement_bounds := _pile_movement_bounds(pile)
	var minimum := movement_bounds.position
	var maximum := movement_bounds.end
	var clamped_request := Vector2(
		clampf(requested_position.x, minimum.x, maximum.x),
		clampf(requested_position.y, minimum.y, maximum.y)
	)
	pile.position = clamped_request.round()
	if _is_valid_pile_position(pile):
		return pile.position

	# A coarse board-wide pass finds the closest legal region without making
	# release time depend on the distance from an invalid drop. The local
	# pixel pass below then removes the small grid approximation.
	const SEARCH_STEP := 4
	var found := false
	var best_position := fallback_position
	var best_distance_squared := INF
	for y in range(floori(minimum.y), ceili(maximum.y) + 1, SEARCH_STEP):
		for x in range(floori(minimum.x), ceili(maximum.x) + 1, SEARCH_STEP):
			var candidate := Vector2(x, y)
			var distance_squared := candidate.distance_squared_to(clamped_request)
			if distance_squared >= best_distance_squared:
				continue
			pile.position = candidate
			if _is_valid_pile_position(pile):
				found = true
				best_position = candidate
				best_distance_squared = distance_squared

	if found:
		var refine_minimum := (best_position - Vector2.ONE * SEARCH_STEP).max(minimum)
		var refine_maximum := (best_position + Vector2.ONE * SEARCH_STEP).min(maximum)
		for y in range(floori(refine_minimum.y), ceili(refine_maximum.y) + 1):
			for x in range(floori(refine_minimum.x), ceili(refine_maximum.x) + 1):
				var candidate := Vector2(x, y)
				var distance_squared := candidate.distance_squared_to(clamped_request)
				if distance_squared >= best_distance_squared:
					continue
				pile.position = candidate
				if _is_valid_pile_position(pile):
					best_position = candidate
					best_distance_squared = distance_squared
		return best_position

	pile.position = fallback_position
	return fallback_position


func _pile_movement_bounds(pile: MemoryPile) -> Rect2:
	# PilesBoard is a direct child of the game Control and does not clip its
	# children. Negative/local positions therefore safely expose the margins
	# around the original compact board.
	const SCREEN_MARGIN := 2.0
	var minimum := -piles_board.position + Vector2.ONE * SCREEN_MARGIN
	var maximum := (
		size
		- piles_board.position
		- pile.size
		- Vector2.ONE * SCREEN_MARGIN
	)
	return Rect2(minimum, (maximum - minimum).max(Vector2.ZERO))


func _is_valid_pile_position(pile: MemoryPile) -> bool:
	var candidate_rect := _transformed_control_rect(pile)
	var screen_rect := _transformed_control_rect(self).grow(-2.0)
	if not screen_rect.encloses(candidate_rect):
		return false
	var forbidden_controls: Array[Control] = [
		hand_tray,
	]
	for forbidden in forbidden_controls:
		if (
			forbidden.visible
			and candidate_rect.intersects(_transformed_control_rect(forbidden))
		):
			return false
	for other in piles:
		if not is_instance_valid(other) or other == pile or other.completed:
			continue
		var center := candidate_rect.get_center()
		var other_center := _transformed_control_rect(other).get_center()
		if center.distance_to(other_center) < Difficulty.MINIMUM_PILE_DISTANCE:
			return false
	if round_modifiers.floor_is_lava_enabled and lava_rule_controller.touches_rect(candidate_rect):
		return false
	return true


func _handle_pile_touch_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if moving_pile != null:
				return _pile_touch_index == touch.index
			if (
				input_locked
				or not bonus_manager.has_bonus(&"pile_mover")
				or selected_card != null
			):
				return false
			var touched_pile := _pile_at(touch.position)
			if touched_pile == null:
				return false
			moving_pile = touched_pile
			_pile_touch_index = touch.index
			_moving_pile_pointer = touch.position
			_moving_pile_last_valid_position = touched_pile.position
			_pile_touch_local_grab = (
				touched_pile.get_global_transform().affine_inverse()
				* touch.position
			)
			special_rule_manager.moving_pile_pattern.begin_manual_move(
				touched_pile
			)
			touched_pile.move_to_front()
			return true
		if (
			moving_pile != null
			and is_instance_valid(moving_pile)
			and _pile_touch_index == touch.index
		):
			_update_touch_pile_position(touch.position)
			_finish_pile_move()
			return true
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if (
			moving_pile != null
			and is_instance_valid(moving_pile)
			and _pile_touch_index == drag.index
		):
			_update_touch_pile_position(drag.position)
			return true
	return false


func _update_touch_pile_position(pointer_position: Vector2) -> void:
	if moving_pile == null or not is_instance_valid(moving_pile):
		return
	_moving_pile_pointer = pointer_position
	var parent_item := moving_pile.get_parent() as CanvasItem
	if parent_item == null:
		return
	var pointer_in_parent := (
		parent_item.get_global_transform().affine_inverse()
		* pointer_position
	)
	var grab_offset := moving_pile.get_transform().basis_xform(
		_pile_touch_local_grab
	)
	moving_pile.position = pointer_in_parent - grab_offset


func _handle_card_touch_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if selected_card != null and is_instance_valid(selected_card):
				return _card_touch_index == touch.index
			if input_locked:
				return false
			var touched_card := _card_at_touch_position(touch.position)
			if touched_card == null:
				return false
			_card_touch_index = touch.index
			touched_card.drag_target = touch.position
			_on_card_selected(touched_card)
			_on_card_drag_started(touched_card)
			if not touched_card.dragging:
				_card_touch_index = -1
				return false
			return true
		if (
			selected_card != null
			and is_instance_valid(selected_card)
			and selected_card.dragging
			and _card_touch_index == touch.index
		):
			selected_card.update_touch_drag(touch.position)
			_on_card_drag_released(selected_card, touch.position)
			return true
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if (
			selected_card != null
			and is_instance_valid(selected_card)
			and selected_card.dragging
			and _card_touch_index == drag.index
		):
			selected_card.update_touch_drag(drag.position)
			return true
	return false


func _card_at_touch_position(touch_position: Vector2) -> PlayingCard:
	for index in range(hand_manager.current_cards.size() - 1, -1, -1):
		var card := hand_manager.current_cards[index]
		if (
			not is_instance_valid(card)
			or not card.visible
			or not card.selectable
			or card.placement_confirmed
		):
			continue
		var local_point := (
			card.get_global_transform().affine_inverse()
			* touch_position
		)
		if Rect2(Vector2.ZERO, card.size).has_point(local_point):
			return card
	return null


func _transformed_control_rect(control: Control) -> Rect2:
	var transform := control.get_global_transform()
	var corners: Array[Vector2] = [
		transform * Vector2.ZERO,
		transform * Vector2(control.size.x, 0.0),
		transform * control.size,
		transform * Vector2(0.0, control.size.y),
	]
	var minimum := corners[0]
	var maximum := corners[0]
	for corner in corners:
		minimum = minimum.min(corner)
		maximum = maximum.max(corner)
	return Rect2(minimum, maximum - minimum)


func _on_card_forced_return_requested(card: PlayingCard, _reason: int) -> void:
	if (
		input_locked
		or card != selected_card
		or not is_instance_valid(card)
		or card.placement_confirmed
	):
		return
	input_locked = true
	_card_touch_index = -1
	if hovered_pile != null and is_instance_valid(hovered_pile):
		hovered_pile.set_drop_feedback(false)
	hovered_pile = null
	await _return_drag_companions()
	await _return_card_to_hand(card, 0.2)
	card.complete_forced_return()
	card.set_selectable(true)
	selected_card = null
	hand_manager.clear_selection()
	input_locked = false
	hand_manager.unlock_hand()
	if timer_manager.time_left <= 0.0:
		await _handle_mistake(null, true)


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
	_generate_next_hand(_hand_cycle_generation, false, true)


func _place_selected_card(pile: MemoryPile) -> void:
	_hand_cycle_generation += 1
	var placement_generation := _hand_cycle_generation
	input_locked = true
	bonus_manager.bank_remaining_time(timer_manager.time_left)
	timer_manager.stop_countdown()
	hand_manager.lock_hand()
	var card := selected_card
	var placed_value := pile.expected_value() if card.is_joker else card.card_value
	var origin := card.global_position
	_root_action_id += 1
	var context := PlacementContext.new(PlacementContext.Source.PLAYER, _root_action_id)
	var affected_piles: Array[MemoryPile] = []
	await _stack_card(card, pile, context)
	affected_piles.append(pile)
	var companion_piles := await _resolve_companion_drops(pile)
	for companion_pile in companion_piles:
		if not affected_piles.has(companion_pile):
			affected_piles.append(companion_pile)
	if bonus_manager.has_bonus(&"deja_vu"):
		var deja_piles := await _resolve_deja_vu(
			placed_value, pile, bonus_manager.level(&"deja_vu"), origin, context.root_action_id
		)
		for deja_pile in deja_piles:
			if not affected_piles.has(deja_pile):
				affected_piles.append(deja_pile)
	if bonus_manager.has_bonus(&"double_down") and not pile.completed:
		await _resolve_double_down(
			pile, bonus_manager.level(&"double_down"), origin, context.root_action_id
		)
	if not affected_piles.has(pile):
		affected_piles.append(pile)
	await _finalize_placement_action(affected_piles)
	if _all_piles_complete():
		await _finish_round()
		return
	_start_discard_current_hand()
	if placement_generation == _hand_cycle_generation:
		await _begin_turn(false, true)


func _stack_card(
	card: PlayingCard,
	pile: MemoryPile,
	context: PlacementContext
) -> void:
	if not is_instance_valid(card) or not is_instance_valid(pile) or pile.completed:
		return
	if card.get_parent() == hand_container:
		var previous_global_position := card.global_position
		_create_hand_slot_placeholder(card)
		card.reparent(drag_layer, false)
		card.global_position = previous_global_position
	card.confirm_drop()
	var destination := pile.global_position + (pile.size - card.size) * 0.5
	var placement_duration := (
		Difficulty.BONUS_CHAIN_PLACEMENT_DURATION
		if (
			context.source == PlacementContext.Source.DOUBLE_DOWN
			or context.source == PlacementContext.Source.DEJA_VU
		)
		else Difficulty.AUTOMATIC_PLACEMENT_DURATION
	)
	await card.animate_valid_drop(destination, placement_duration)
	var placed_value := pile.expected_value() if card.is_joker else card.card_value
	pile.place(placed_value)
	if bonus_manager.has_bonus(&"last_reminder") and not pile.is_complete_value():
		if (
			_last_reminder_pile != null
			and is_instance_valid(_last_reminder_pile)
			and _last_reminder_pile != pile
			and not _last_reminder_pile.bonus_highlight
		):
			_last_reminder_pile.keep_face_up = false
			_last_reminder_pile.set_bonus_revealed(false)
		pile.keep_face_up = true
		_last_reminder_pile = pile
	card_placed.emit(card, pile)
	soft_audio.play_tone(610.0, 0.075, 0.055)
	card.visible = false
	hand_manager.forget_card(card)
	card.queue_free()


func _resolve_deja_vu(
	played_value: int,
	original_pile: MemoryPile,
	maximum_copies: int,
	origin: Vector2,
	root_action_id: int
) -> Array[MemoryPile]:
	var matching_cards := hand_manager.find_cards_with_value(played_value)
	var compatible_piles := pile_manager.find_piles_accepting_value(played_value)
	compatible_piles.erase(original_pile)
	matching_cards.sort_custom(
		func(first: PlayingCard, second: PlayingCard) -> bool:
			return first.global_position.distance_squared_to(origin) < second.global_position.distance_squared_to(origin)
	)
	var used: Array[MemoryPile] = []
	for card in matching_cards:
		if used.size() >= maximum_copies or compatible_piles.is_empty():
			break
		compatible_piles.sort_custom(
			func(first: MemoryPile, second: MemoryPile) -> bool:
				var card_center := card.global_position + card.size * 0.5
				var first_distance := card_center.distance_squared_to(first.global_position + first.size * 0.5)
				var second_distance := card_center.distance_squared_to(second.global_position + second.size * 0.5)
				if is_equal_approx(first_distance, second_distance):
					return first.pile_index < second.pile_index
				return first_distance < second_distance
		)
		var target := compatible_piles.pop_front() as MemoryPile
		await _stack_card(
			card, target,
			PlacementContext.new(PlacementContext.Source.DEJA_VU, root_action_id)
		)
		used.append(target)
	return used


func _resolve_double_down(
	pile: MemoryPile,
	maximum_bonus_cards: int,
	origin: Vector2,
	root_action_id: int
) -> void:
	var played_count := 0
	while played_count < maximum_bonus_cards and not pile.is_complete_value():
		var matching_card := hand_manager.find_card_with_value(pile.expected_value(), origin)
		if matching_card == null:
			break
		await _stack_card(
			matching_card, pile,
			PlacementContext.new(PlacementContext.Source.DOUBLE_DOWN, root_action_id)
		)
		played_count += 1


func _finalize_placement_action(affected_piles: Array[MemoryPile]) -> void:
	for pile in affected_piles:
		if not is_instance_valid(pile):
			continue
		if pile.is_complete_value() and not pile.completed:
			await _complete_pile(pile)
	for pile in affected_piles:
		if is_instance_valid(pile) and not pile.completed:
			await get_tree().create_timer(0.08).timeout
			await pile.hide_value(true)
	await _after_valid_card_played()


func _complete_pile(pile: MemoryPile) -> void:
	if pile.completed:
		return
	soft_audio.play_tone(760.0, 0.14, 0.06)
	await pile.complete_animation()
	var recovered := bonus_manager.recover_on_completed_pile(
		mistakes_left,
		maximum_mistakes
	)
	if recovered != mistakes_left:
		mistakes_left = recovered
		_update_hud()


func _after_valid_card_played() -> void:
	await special_rule_manager.after_card_played(piles, _progression_round())
	if round_modifiers.musical_stacks_enabled:
		await pile_manager.rotate_active_piles(
			round_modifiers.musical_stacks_direction,
			0.4 / bonus_manager.adaptation_multiplier()
		)


func _handle_mistake(
	pile: MemoryPile = null,
	caused_by_timeout := false
) -> void:
	if input_locked:
		return
	input_locked = true
	timer_manager.stop_countdown()
	hand_manager.lock_hand()
	var protected_by_safety_net := bonus_manager.consume_safety_net()
	if not Debug.is_god_mode_enabled() and not protected_by_safety_net:
		mistakes_left -= 1
	mistake_made.emit()
	if protected_by_safety_net:
		soft_audio.play_safety_net_break()
	elif caused_by_timeout:
		soft_audio.play_timeout_error()
	else:
		soft_audio.play_error()
	if mistakes_left <= 0:
		music_manager.set_low_pass_enabled(true)
	if protected_by_safety_net:
		await mistakes_dots.play_safety_net_break()
	else:
		await mistakes_dots.play_damage(mistakes_left)
	_update_hud()
	await _return_drag_companions()
	if selected_card != null and is_instance_valid(selected_card) and selected_card.get_parent() == drag_layer:
		await _return_card_to_hand(selected_card, 0.14)
	if mistakes_left <= 0:
		await get_tree().create_timer(DEATH_POPUP_DELAY).timeout
		_start_discard_current_hand()
		await _finish_game()
	else:
		selected_card = null
		hand_manager.clear_selection()
		if bonus_manager.has_bonus(&"mistake_reveal"):
			await _run_bonus_pile_flash(
				Difficulty.MISTAKE_REVEAL_DURATIONS[
					bonus_manager.level(&"mistake_reveal")
				]
			)
		input_locked = false
		hand_manager.unlock_hand()
		_start_turn_countdown()
		if pile != null and is_instance_valid(pile) and not pile.completed:
			_reveal_mistake_pile(pile)


func _reveal_mistake_pile(pile: MemoryPile) -> void:
	await pile.flash_invalid()
	if is_instance_valid(pile) and not pile.completed:
		await pile.reveal_value_temporarily(0.65)


func _return_card_to_hand(card: PlayingCard, duration := 0.26) -> void:
	var destination := card.hand_return_position()
	await card.animate_return(destination, duration)
	if round_modifiers.wandering_hand_cards:
		_clear_drag_placeholder()
		card.scale = Vector2.ONE
		card.set_selectable(not input_locked)
		card.enable_wandering(maxi(hand_manager.current_cards.find(card), 0), true)
		return
	# Remove the spacer synchronously before putting the card back. Otherwise
	# both controls occupy the HBox for one frame and rapid drags can capture
	# that transient, shifted layout as a new home position.
	_clear_drag_placeholder()
	card.reparent(hand_container, false)
	_restore_hand_child_order()
	hand_container.queue_sort()
	await get_tree().process_frame
	card.reset_hand_pose()
	card.position.y = 0.0
	card.record_hand_position()
	card.set_selectable(not input_locked)
	if round_modifiers.wandering_hand_cards:
		card.call_deferred("enable_wandering", maxi(card.get_index(), 0))


func _clear_drag_placeholder() -> void:
	if is_instance_valid(drag_placeholder):
		var placeholder_card_id := 0
		for card_id in _hand_slot_placeholders:
			var stored_placeholder: Variant = _hand_slot_placeholders[card_id]
			if (
				is_instance_valid(stored_placeholder)
				and stored_placeholder == drag_placeholder
			):
				placeholder_card_id = int(card_id)
				break
		if placeholder_card_id != 0:
			_hand_slot_placeholders.erase(placeholder_card_id)
		if drag_placeholder.get_parent() != null:
			drag_placeholder.get_parent().remove_child(drag_placeholder)
		drag_placeholder.queue_free()
	drag_placeholder = null
	drag_home_index = -1


func _create_hand_slot_placeholder(card: PlayingCard) -> Control:
	var existing := _valid_hand_slot_placeholder(card)
	if existing != null:
		return existing
	var placeholder := Control.new()
	placeholder.name = "HandSlotPlaceholder"
	placeholder.set_meta(&"hand_drag_placeholder", true)
	placeholder.custom_minimum_size = card.size
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var slot_index := card.get_index()
	hand_container.add_child(placeholder)
	hand_container.move_child(placeholder, slot_index)
	_hand_slot_placeholders[card.get_instance_id()] = placeholder
	return placeholder


func _remove_hand_slot_placeholder(card: PlayingCard) -> void:
	var placeholder := _valid_hand_slot_placeholder(card)
	_hand_slot_placeholders.erase(card.get_instance_id())
	if placeholder == null:
		return
	if placeholder == drag_placeholder:
		drag_placeholder = null
		drag_home_index = -1
	if placeholder.get_parent() != null:
		placeholder.get_parent().remove_child(placeholder)
	placeholder.queue_free()


func _valid_hand_slot_placeholder(card: PlayingCard) -> Control:
	var placeholder_variant: Variant = _hand_slot_placeholders.get(
		card.get_instance_id()
	)
	if not is_instance_valid(placeholder_variant):
		return null
	return placeholder_variant as Control


func _clear_all_hand_slot_placeholders() -> void:
	for placeholder_variant in _hand_slot_placeholders.values():
		if not is_instance_valid(placeholder_variant):
			continue
		var placeholder := placeholder_variant as Control
		if placeholder.get_parent() != null:
			placeholder.get_parent().remove_child(placeholder)
		placeholder.queue_free()
	_hand_slot_placeholders.clear()
	drag_placeholder = null
	drag_home_index = -1


func _remove_orphan_drag_placeholders() -> void:
	for child in hand_container.get_children():
		if (
			child != drag_placeholder
			and child.has_meta(&"hand_drag_placeholder")
		):
			hand_container.remove_child(child)
			child.queue_free()
	_hand_slot_placeholders.clear()
	if is_instance_valid(drag_placeholder) and selected_card != null:
		_hand_slot_placeholders[selected_card.get_instance_id()] = drag_placeholder
	hand_container.queue_sort()


func _restore_hand_child_order() -> void:
	var child_index := 0
	for logical_card in hand_manager.current_cards:
		if not is_instance_valid(logical_card) or not logical_card.visible:
			continue
		if logical_card == selected_card and is_instance_valid(drag_placeholder):
			if drag_placeholder.get_parent() == hand_container:
				hand_container.move_child(drag_placeholder, child_index)
				child_index += 1
			continue
		if logical_card.get_parent() == hand_container:
			hand_container.move_child(logical_card, child_index)
			child_index += 1


func _record_stable_hand_layout() -> void:
	for card in hand_manager.current_cards:
		if (
			is_instance_valid(card)
			and card.visible
			and card.get_parent() == hand_container
			and not card.dragging
		):
			card.record_hand_position()


func _discard_current_hand(preserve_unused_jokers := true) -> void:
	await hand_manager.discard_hand(
		hand_container,
		drag_layer,
		preserve_unused_jokers
	)
	_clear_drag_placeholder()


func _start_discard_current_hand() -> void:
	hand_manager.discard_hand(hand_container, drag_layer)
	_clear_drag_placeholder()


func _pile_at(global_point: Vector2) -> MemoryPile:
	for pile in piles:
		if (
			not pile.completed
			and pile.visible
			and pile.contains_global_point(global_point, 8.0)
		):
			return pile
	return null


func _on_time_expired() -> void:
	if input_locked:
		return
	await _handle_mistake(null, true)


func _on_lava_card_entered(card: PlayingCard) -> void:
	if card == selected_card and not input_locked:
		card.request_forced_return(PlayingCard.ForcedReturnReason.LAVA)


func _on_redraw_pressed() -> void:
	if input_locked or not bonus_manager.consume_redraw():
		return
	input_locked = true
	redraw_button.set_remaining(
		bonus_manager.redraws_left,
		bonus_manager.level(&"redraw") >= 2
	)
	redraw_button.play_used_animation()
	timer_manager.stop_countdown()
	_hand_cycle_generation += 1
	await _discard_current_hand()
	await _begin_turn(false, true)
	redraw_button.visible = bonus_manager.redraws_left > 0


func cleanup_special_rule_state() -> void:
	input_locked = true
	sticky_fingers_controller.end_round()
	mirror_match_controller.end_round(self)
	timer_manager.stop_countdown()
	await _return_drag_companions()
	if moving_pile != null and is_instance_valid(moving_pile):
		moving_pile.position = _moving_pile_last_valid_position
	moving_pile = null
	_pile_touch_index = -1
	_card_touch_index = -1
	if selected_card != null and is_instance_valid(selected_card):
		selected_card.cancel_drag_timers()
		if selected_card.get_parent() == drag_layer:
			await _return_card_to_hand(selected_card, 0.16)
	hand_manager.cancel_all_drags()
	hand_manager.stop_all_card_timers()
	hand_manager.reveal_all_hand_cards()
	hand_manager.refresh_all_card_themes(false)
	pile_manager.stop_all_movements()
	pile_manager.refresh_all_card_themes(false)
	lava_rule_controller.clear(true)
	_on_timer_visibility_requested(true)
	mistakes_dots.set_maximum(3)
	selected_card = null
	hovered_pile = null


func _finish_round() -> void:
	input_locked = true
	var completed_round_number := _progression_round()
	timer_manager.stop_countdown()
	await cleanup_special_rule_state()
	# Clear the remaining hand as part of the victory sequence. Jokers persist
	# between hands, but never carry over into the next round.
	await _discard_current_hand(false)
	_clear_all_hand_slot_placeholders()
	await special_rule_manager.end_round(piles)
	round_completed.emit()
	soft_audio.play_tone(680.0, 0.16, 0.055)
	await _show_round_wave()
	if game_mode == GameMode.ENDLESS:
		round_number += 1
	else:
		round_number -= 1
	round_reached_time_ms = _total_time_milliseconds()
	_update_hud()
	if game_mode == GameMode.STANDARD and round_number <= 0:
		await _finish_game(true)
		return
	await bonus_manager.offer_if_due(completed_round_number)
	var change := _advance_difficulty(_progression_round())
	if change == "TIER RELIEF":
		music_manager.request_next_section()
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
	music_manager.set_low_pass_enabled(true)
	if completed_all_rounds and game_mode == GameMode.STANDARD:
		soft_audio.play_victory()
		_unlock_endless_mode()
	else:
		soft_audio.play_game_over()
	# The death screen represents the whole run, including the round in which
	# the player died. `round_reached_time_ms` only tracks completed rounds.
	var score_time_ms := _total_time_milliseconds()
	var formatted_time := _format_duration(score_time_ms)
	var high_score_kind := (
		_update_endless_high_score(round_number, score_time_ms)
		if game_mode == GameMode.ENDLESS
		else _update_high_score(round_number, score_time_ms)
	)
	game_over.emit()
	overlay_high_score.visible = not high_score_kind.is_empty()
	if completed_all_rounds and game_mode == GameMode.STANDARD:
		overlay_title.text = (
			"[center][color=#FFD700][wave amp=35.0 freq=4.0 connected=1]YOU WIN ![/wave][/color][/center]"
		)
		overlay_details.text = "[center]in %s[/center]" % formatted_time
	elif not high_score_kind.is_empty():
		var rounds_text := (
			"ROUND %d" % round_number
			if game_mode == GameMode.ENDLESS
			else "%d ROUNDS LEFT" % round_number
		)
		var time_text := "in %s" % formatted_time
		if high_score_kind == "ROUND":
			rounds_text = "[color=#4D82C2]%s[/color]" % rounds_text
		else:
			time_text = "[color=#4D82C2]%s[/color]" % time_text
		overlay_title.text = "[center]%s[/center]" % rounds_text
		overlay_details.text = "[center]%s[/center]" % time_text
	elif game_mode == GameMode.ENDLESS:
		overlay_title.text = "[center]ROUND %d[/center]" % round_number
		overlay_details.text = "[center]in %s[/center]" % formatted_time
	else:
		overlay_title.text = "[center]%d ROUNDS LEFT[/center]" % round_number
		overlay_details.text = "[center]in %s[/center]" % formatted_time
	overlay_button.text = "REPLAY"
	overlay_endless_button.visible = (
		completed_all_rounds
		and game_mode == GameMode.STANDARD
	)
	overlay_mode = "restart"
	_show_game_over_overlay(not completed_all_rounds)
	# Cleanup can include rule-specific animations. Run it only after the result
	# is visible so the third mistake always produces immediate feedback.
	await cleanup_special_rule_state()
	await special_rule_manager.end_round(piles)


func _show_game_over_overlay(animate_death: bool) -> void:
	overlay.visible = true
	overlay_scrim.modulate.a = 1.0
	overlay_panel.modulate.a = 1.0
	overlay_panel.scale = Vector2.ONE
	if not animate_death:
		return
	overlay_scrim.modulate.a = 0.0
	overlay_panel.modulate.a = 0.0
	overlay_panel.scale = Vector2(0.42, 0.42)
	overlay_panel.pivot_offset = overlay_panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(overlay_scrim, "modulate:a", 1.0, 0.18)
	tween.tween_property(overlay_panel, "modulate:a", 1.0, 0.12)
	tween.tween_property(
		overlay_panel,
		"scale",
		Vector2.ONE,
		0.3
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_overlay_pressed() -> void:
	if overlay_mode == "restart":
		start_game(game_mode == GameMode.ENDLESS)


func _on_overlay_endless_pressed() -> void:
	start_game(true)


func _on_splash_pressed() -> void:
	start_game()


func _on_endless_pressed() -> void:
	start_game(true)


func _on_special_rules_announcing(_rules: Array[SpecialRuleData]) -> void:
	music_manager.set_low_pass_enabled(true)
	soft_audio.play_special_rule()


func _on_special_rules_announcement_finished() -> void:
	music_manager.set_low_pass_enabled(false, true)


func _increase_difficulty(first_upgrade_override := -1) -> String:
	var first_upgrade := (
		first_upgrade_override == 1
		if first_upgrade_override >= 0
		else _progression_round() == 2
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
	var theoretical_rule_count := 1
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
	var stats: Array[StringName] = []
	if pile_count > Difficulty.START_PILES:
		stats.append(&"piles")
	if hand_size > Difficulty.START_HAND_SIZE:
		stats.append(&"hand")
	if start_value > Difficulty.START_CARD_VALUE:
		stats.append(&"value")
	if turn_time < Difficulty.START_TURN_TIME:
		stats.append(&"time")
	for index in range(stats.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary := stats[index]
		stats[index] = stats[swap_index]
		stats[swap_index] = temporary
	for index in mini(relief_count, stats.size()):
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


func _start_turn_countdown(duration_override := -1.0) -> void:
	var effective_turn_time := (
		duration_override if duration_override > 0.0 else turn_time
	)
	# Le premier tick correspond au passage à la seconde suivante, pas à
	# l'initialisation du chronomètre.
	_last_clock_second = ceili(effective_turn_time)
	_urgent_tick_index = 0
	while (
		_urgent_tick_index < URGENT_TICK_THRESHOLDS.size()
		and URGENT_TICK_THRESHOLDS[_urgent_tick_index] >= effective_turn_time
	):
		_urgent_tick_index += 1
	if _clock_flash_tween != null and _clock_flash_tween.is_valid():
		_clock_flash_tween.kill()
	timer_ring.flash_strength = 0.0
	var grace_duration := 0.0
	if round_modifiers.grace_period_enabled:
		var adapted_reveal_time := (
			Difficulty.GRACE_PERIOD_REVEAL_TIME
			/ maxf(round_modifiers.special_rule_intensity_multiplier, 0.01)
		)
		grace_duration = maxf(
			effective_turn_time - maxf(adapted_reveal_time, 0.0),
			0.0
		)
		round_modifiers.grace_period_duration = grace_duration
	timer_manager.start_countdown(effective_turn_time, grace_duration)


func _reveal_all_piles(duration: float) -> void:
	var revealed: Array[MemoryPile] = []
	for pile in piles:
		if is_instance_valid(pile) and not pile.completed and not pile.face_up:
			pile.set_bonus_revealed(true)
			revealed.append(pile)
	if revealed.is_empty():
		return
	await get_tree().create_timer(duration).timeout
	for pile in revealed:
		if is_instance_valid(pile):
			pile.set_bonus_revealed(false)


func _run_quick_peek() -> void:
	await _run_bonus_pile_flash(
		Difficulty.QUICK_PEEK_DURATIONS[bonus_manager.level(&"quick_peek")]
	)
	if _all_piles_complete():
		return
	_start_turn_countdown(bonus_manager.next_hand_time(turn_time))
	input_locked = false
	hand_manager.unlock_hand()


func _run_bonus_pile_flash(duration: float) -> void:
	var flashed_piles: Array[MemoryPile] = []
	for pile in piles:
		if is_instance_valid(pile) and not pile.completed and not pile.face_up:
			flashed_piles.append(pile)
			pile.show_quick_peek_flash()
	await get_tree().create_timer(duration).timeout
	for pile in flashed_piles:
		if is_instance_valid(pile):
			pile.hide_quick_peek_flash()
	await get_tree().create_timer(0.07).timeout


func _on_time_updated(time_left: float) -> void:
	var displayed_second := ceili(time_left)
	timer_label.text = RoundModifiers.format_value(
		displayed_second,
		round_modifiers.roman_numerals_enabled
	)
	timer_ring.set_ratio(timer_manager.ratio())
	if (
		not _timer_display_hidden
		and time_left > 2.0
		and displayed_second != _last_clock_second
	):
		_last_clock_second = displayed_second
		soft_audio.play_clock_tick()
	elif time_left <= 2.0 and (not _timer_display_hidden or time_left <= 1.0):
		while (
			_urgent_tick_index < URGENT_TICK_THRESHOLDS.size()
			and time_left <= URGENT_TICK_THRESHOLDS[_urgent_tick_index]
		):
			var threshold := URGENT_TICK_THRESHOLDS[_urgent_tick_index]
			var urgency := 1.0 - threshold / 2.0
			soft_audio.play_clock_tick(urgency)
			_flash_clock_tick(urgency)
			_urgent_tick_index += 1


func _on_timer_visibility_requested(visible: bool) -> void:
	var was_hidden := _timer_display_hidden
	_timer_display_hidden = not visible
	if _timer_visibility_tween != null and _timer_visibility_tween.is_valid():
		_timer_visibility_tween.kill()
	if not visible:
		if was_hidden:
			return
		timer_ring.visible = true
		_timer_visibility_tween = create_tween().set_parallel()
		_timer_visibility_tween.set_trans(Tween.TRANS_QUAD)
		_timer_visibility_tween.set_ease(Tween.EASE_IN)
		_timer_visibility_tween.tween_property(timer_ring, "modulate:a", 0.0, 0.15)
		_timer_visibility_tween.tween_property(
			timer_ring,
			"scale",
			Vector2(0.9, 0.9),
			0.15
		)
		_timer_visibility_tween.chain().tween_callback(func() -> void:
			if _timer_display_hidden:
				timer_ring.visible = false
		)
		return
	timer_ring.visible = true
	if not was_hidden:
		timer_ring.scale = Vector2.ONE
		timer_ring.modulate.a = 1.0
		return
	timer_ring.scale = Vector2(0.9, 0.9)
	timer_ring.modulate.a = 0.0
	_timer_visibility_tween = create_tween().set_parallel()
	_timer_visibility_tween.set_trans(Tween.TRANS_QUAD)
	_timer_visibility_tween.set_ease(Tween.EASE_OUT)
	_timer_visibility_tween.tween_property(timer_ring, "modulate:a", 1.0, 0.18)
	_timer_visibility_tween.tween_property(timer_ring, "scale", Vector2.ONE, 0.18)


func _flash_clock_tick(urgency: float) -> void:
	if _clock_flash_tween != null and _clock_flash_tween.is_valid():
		_clock_flash_tween.kill()
	var red_strength := lerpf(0.55, 0.9, clampf(urgency, 0.0, 1.0))
	timer_ring.flash_strength = red_strength
	_clock_flash_tween = create_tween()
	_clock_flash_tween.tween_property(
		timer_ring,
		"flash_strength",
		0.0,
		0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


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


func _update_endless_high_score(reached_round: int, elapsed_time_ms: int) -> String:
	var is_better_progress := (
		endless_best_round < 0 or reached_round > endless_best_round
	)
	var is_faster_tie := (
		reached_round == endless_best_round
		and (
			endless_best_time_ms < 0
			or elapsed_time_ms < endless_best_time_ms
		)
	)
	if not is_better_progress and not is_faster_tie:
		return ""
	endless_best_round = reached_round
	endless_best_time_ms = elapsed_time_ms
	_save_endless_progress()
	return "ROUND" if is_better_progress else "TIME"


func _unlock_endless_mode() -> void:
	if endless_unlocked:
		return
	endless_unlocked = true
	endless_button.visible = true
	_save_endless_progress()


func _save_endless_progress() -> void:
	var config := ConfigFile.new()
	config.load("user://pile_down.cfg")
	config.set_value("progress", "endless_unlocked", endless_unlocked)
	config.set_value("progress", "endless_best_round", endless_best_round)
	config.set_value("progress", "endless_best_time_ms", endless_best_time_ms)
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
		endless_unlocked = bool(
			config.get_value("progress", "endless_unlocked", false)
		)
		endless_best_round = int(
			config.get_value("progress", "endless_best_round", -1)
		)
		endless_best_time_ms = int(
			config.get_value("progress", "endless_best_time_ms", -1)
		)
	endless_unlocked = endless_unlocked or Debug.unlock_endless_mode()
	endless_button.visible = endless_unlocked
	_refresh_high_score()


func _refresh_high_score() -> void:
	if best_rounds_left < 0 or best_score_time_ms < 0:
		splash_high_score.text = "[center]HIGHSCORE\n--[/center]"
		splash_high_score_time.visible = false
		return
	if best_rounds_left == 0:
		splash_high_score.text = (
			"[center]HIGHSCORE\nWIN[/center]"
		)
		splash_high_score_time.text = "in %s" % _format_duration(best_score_time_ms)
		splash_high_score_time.visible = true
		return
	splash_high_score.text = (
		"[center]HIGHSCORE\n%d rounds left[/center]" % best_rounds_left
	)
	splash_high_score_time.text = "in %s" % _format_duration(best_score_time_ms)
	splash_high_score_time.visible = true


func _show_endless_high_score() -> void:
	if endless_best_round < 0 or endless_best_time_ms < 0:
		splash_high_score.text = "[center]ENDLESS HIGHSCORE\n--[/center]"
		splash_high_score_time.visible = false
		return
	splash_high_score.text = (
		"[center]ENDLESS HIGHSCORE\nround %d[/center]" % endless_best_round
	)
	splash_high_score_time.text = (
		"in %s" % _format_duration(endless_best_time_ms)
	)
	splash_high_score_time.visible = true


func _progression_round() -> int:
	if game_mode == GameMode.ENDLESS:
		return round_number
	return Difficulty.TOTAL_ROUNDS - round_number + 1
