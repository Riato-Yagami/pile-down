class_name GameManager
extends Control

signal card_placed(card, pile)
signal mistake_made()
signal round_completed()
signal game_over()

const PILE_SCENE := preload("res://scenes/Pile.tscn")
const Difficulty := preload("res://scripts/difficulty.gd")

@onready var piles_board: Control = %PilesBoard
@onready var hand_container: HBoxContainer = %HandContainer
@onready var drag_layer: Control = %DragLayer
@onready var hand_manager: HandManager = %HandManager
@onready var timer_manager: CountdownManager = %TimerManager
@onready var timer_label: Label = %TimerLabel
@onready var timer_ring: CountdownRing = %TimerRing
@onready var round_label: Label = %RoundLabel
@onready var mistakes_dots: RoundDots = %MistakesDots
@onready var transient_label: Label = %TransientLabel
@onready var overlay: Control = %Overlay
@onready var overlay_title: Label = %OverlayTitle
@onready var overlay_details: Label = %OverlayDetails
@onready var overlay_button: Button = %OverlayButton
@onready var splash: Control = %Splash
@onready var splash_button: Button = %SplashButton
@onready var soft_audio: SoftAudio = %SoftAudio

var pile_count: int = Difficulty.START_PILES
var hand_size: int = Difficulty.START_HAND_SIZE
var start_value: int = Difficulty.START_CARD_VALUE
var turn_time: float = Difficulty.START_TURN_TIME
var round_number: int = Difficulty.TOTAL_ROUNDS
var best_time_ms := 0
var game_started_msec := 0
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


func _ready() -> void:
	rng.randomize()
	hand_manager.card_selected.connect(_on_card_selected)
	hand_manager.card_drag_started.connect(_on_card_drag_started)
	hand_manager.card_drag_released.connect(_on_card_drag_released)
	timer_manager.time_updated.connect(_on_time_updated)
	timer_manager.time_expired.connect(_on_time_expired)
	overlay_button.pressed.connect(_on_overlay_pressed)
	splash_button.pressed.connect(_on_splash_pressed)
	resized.connect(_layout_piles)
	_load_best_time()
	input_locked = true
	splash.visible = true


func _process(_delta: float) -> void:
	if selected_card == null or not is_instance_valid(selected_card) or not selected_card.dragging:
		return
	var candidate := _pile_at(selected_card.drag_target)
	if candidate == hovered_pile:
		return
	if hovered_pile != null and is_instance_valid(hovered_pile):
		hovered_pile.set_drop_feedback(false)
	hovered_pile = candidate
	if hovered_pile != null:
		var compatible := hovered_pile.can_accept(selected_card.card_value)
		hovered_pile.set_drop_feedback(true, compatible)
		if compatible:
			soft_audio.play_tone(520.0, 0.035, 0.035)


func _input(event: InputEvent) -> void:
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


func start_game() -> void:
	pile_count = Difficulty.START_PILES
	hand_size = Difficulty.START_HAND_SIZE
	start_value = Difficulty.START_CARD_VALUE
	turn_time = Difficulty.START_TURN_TIME
	round_number = Difficulty.TOTAL_ROUNDS
	game_started_msec = Time.get_ticks_msec()
	splash.visible = false
	overlay.visible = false
	overlay_mode = ""
	start_round()


func start_round() -> void:
	input_locked = true
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

	for index in pile_count:
		var pile := PILE_SCENE.instantiate() as MemoryPile
		piles_board.add_child(pile)
		pile.setup(index, start_value)
		pile.pile_selected.connect(_on_pile_selected)
		piles.append(pile)
	_layout_piles()
	for index in piles.size():
		piles[index].play_entrance(index * 0.055)
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


func _begin_turn() -> void:
	if _all_piles_complete():
		return
	selected_card = null
	input_locked = false
	hand_manager.generate_hand(hand_container, hand_size, start_value, _playable_values())
	timer_manager.start_countdown(turn_time)


func _on_card_selected(card: PlayingCard) -> void:
	if not input_locked:
		selected_card = card


func _on_card_drag_started(card: PlayingCard) -> void:
	if input_locked:
		return
	selected_card = card
	drag_home_index = card.get_index()
	drag_placeholder = Control.new()
	drag_placeholder.custom_minimum_size = card.size
	drag_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_container.add_child(drag_placeholder)
	hand_container.move_child(drag_placeholder, drag_home_index)
	var start_position := card.global_position
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


func _place_selected_card(pile: MemoryPile) -> void:
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

	if pile.current_value == 0:
		soft_audio.play_tone(760.0, 0.14, 0.06)
		await pile.complete_animation()
		await _discard_current_hand()
		if _all_piles_complete():
			await _finish_round()
			return
	else:
		await get_tree().create_timer(0.32).timeout
		await pile.hide_value(true)
		await get_tree().create_timer(0.12).timeout
		await _discard_current_hand()
	_begin_turn()


func _handle_mistake(pile: MemoryPile = null) -> void:
	if input_locked:
		return
	input_locked = true
	timer_manager.stop_countdown()
	hand_manager.lock_hand()
	mistakes_left -= 1
	mistake_made.emit()
	soft_audio.play_error()
	if selected_card != null and is_instance_valid(selected_card):
		await selected_card.flash_error()
	if pile != null and is_instance_valid(pile) and not pile.completed:
		pile.flash_invalid()
	_update_hud()
	if selected_card != null and is_instance_valid(selected_card) and selected_card.get_parent() == drag_layer:
		await _return_card_to_hand(selected_card)
	if mistakes_left <= 0:
		await _discard_current_hand()
		_finish_game()
	else:
		await get_tree().create_timer(0.18).timeout
		await _discard_current_hand()
		_begin_turn()


func _return_card_to_hand(card: PlayingCard) -> void:
	var destination := drag_placeholder.global_position if is_instance_valid(drag_placeholder) else card.home_global_position
	await card.animate_return(destination)
	var old_global := card.global_position
	card.reparent(hand_container, false)
	hand_container.move_child(card, clampi(drag_home_index, 0, hand_container.get_child_count() - 1))
	card.global_position = old_global
	_clear_drag_placeholder()
	card.scale = Vector2.ONE
	card.position.y = 0.0
	card.set_selectable(not input_locked)


func _clear_drag_placeholder() -> void:
	if is_instance_valid(drag_placeholder):
		drag_placeholder.queue_free()
	drag_placeholder = null
	drag_home_index = -1


func _discard_current_hand() -> void:
	await hand_manager.discard_hand(hand_container)
	_clear_drag_placeholder()


func _pile_at(global_point: Vector2) -> MemoryPile:
	for pile in piles:
		if not pile.completed and pile.visible and pile.get_global_rect().grow(8.0).has_point(global_point):
			return pile
	return null


func _on_time_expired() -> void:
	if input_locked:
		return
	selected_card = null
	await _handle_mistake()


func _finish_round() -> void:
	input_locked = true
	timer_manager.stop_countdown()
	round_completed.emit()
	soft_audio.play_tone(680.0, 0.16, 0.055)
	await _show_round_wave()
	round_number -= 1
	_update_hud()
	if round_number <= 0:
		_finish_game(true)
		return
	var change := _increase_difficulty()
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
	var total_time_ms := _total_time_milliseconds()
	var formatted_time := _format_duration(total_time_ms)
	if completed_all_rounds and (best_time_ms == 0 or total_time_ms < best_time_ms):
		best_time_ms = total_time_ms
		_save_best_time()
	game_over.emit()
	if completed_all_rounds:
		overlay_title.text = "YOU WON"
		overlay_details.text = "in %s" % formatted_time
	else:
		overlay_title.text = "%d ROUNDS LEFT" % round_number
		overlay_details.text = "time: %s" % formatted_time
	overlay_button.text = "REPLAY"
	overlay_mode = "restart"
	overlay.visible = true


func _on_overlay_pressed() -> void:
	if overlay_mode == "restart":
		start_game()


func _on_splash_pressed() -> void:
	start_game()


func _increase_difficulty() -> String:
	var first_upgrade := round_number == Difficulty.TOTAL_ROUNDS - 1
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
	if options.is_empty():
		return ""
	var total := 0.0
	for weight in weights:
		total += weight
	if total <= 0.0:
		# Preserve the mandatory first upgrade even if both first weights are zero.
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
	return ""


func _playable_values() -> Array[int]:
	var values: Array[int] = []
	for pile in piles:
		if not pile.completed:
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
	timer_label.text = str(ceili(time_left))
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
	round_label.text = str(round_number)
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
	if hours > 0:
		return "%02d:%02d:%02d:%03d" % [hours, minutes, seconds, milliseconds]
	if total_minutes > 0:
		return "%02d:%02d:%03d" % [minutes, seconds, milliseconds]
	return "%02d:%03d" % [seconds, milliseconds]


func _save_best_time() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "best_time_ms", best_time_ms)
	config.save("user://pile_down.cfg")


func _load_best_time() -> void:
	var config := ConfigFile.new()
	if config.load("user://pile_down.cfg") == OK:
		best_time_ms = int(config.get_value("progress", "best_time_ms", 0))
