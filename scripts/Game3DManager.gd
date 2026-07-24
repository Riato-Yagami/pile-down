class_name Game3DManager
extends Node3D

const PIECE_SCENE := preload("res://scenes/Piece3D.tscn")
const PILE_SCENE := preload("res://scenes/Pile3D.tscn")
const MAX_HAND := 4
const MAX_START := 9
const MIN_TIME := 2.0

@onready var camera: Camera3D = %Camera3D
@onready var piles_root: Node3D = %Piles
@onready var hand_root: Node3D = %Hand
@onready var timer_manager: CountdownManager = %TimerManager
@onready var soft_audio: SoftAudio = %SoftAudio
@onready var score_label: Label = %ScoreLabel
@onready var best_label: Label = %BestLabel
@onready var round_label: Label = %RoundLabel
@onready var mistakes_label: RoundDots = %MistakesLabel
@onready var timer_label: Label = %TimerLabel
@onready var timer_ring: CountdownRing = %TimerRing
@onready var message_label: Label = %MessageLabel
@onready var overlay: ColorRect = %Overlay
@onready var overlay_title: Label = %OverlayTitle
@onready var overlay_details: Label = %OverlayDetails
@onready var overlay_button: Button = %OverlayButton
@onready var hand_tray: MeshInstance3D = %HandTray

var pile_count := 1
var hand_size := 1
var start_value := 5
var turn_time := 5.0
var round_number := 1
var score := 0
var best_score := 0
var mistakes_left := 3
var selected_piece: PlayingPiece3D
var piles: Array[MemoryPile3D] = []
var hand: Array[PlayingPiece3D] = []
var input_locked := true
var overlay_mode := ""
var rng := RandomNumberGenerator.new()
var dragging_piece: PlayingPiece3D
var hovered_pile: MemoryPile3D


func _ready() -> void:
	rng.randomize()
	hand_tray.mesh = RoundedTileMesh.create(7.8, 2.05, 0.16, 0.34, 8)
	camera.look_at(Vector3.ZERO, Vector3(0.0, 0.0, -1.0))
	timer_manager.time_updated.connect(_on_time_updated)
	timer_manager.time_expired.connect(_on_time_expired)
	overlay_button.pressed.connect(_on_overlay_pressed)
	_load_best_score()
	start_game()


func start_game() -> void:
	pile_count = 1
	hand_size = 1
	start_value = 5
	turn_time = 5.0
	round_number = 1
	score = 0
	overlay.visible = false
	overlay_mode = ""
	start_round()


func start_round() -> void:
	input_locked = true
	selected_piece = null
	mistakes_left = 3
	timer_manager.stop_countdown()
	_clear_node(piles_root)
	_clear_node(hand_root)
	piles.clear()
	hand.clear()
	await get_tree().process_frame

	for index in pile_count:
		var pile := PILE_SCENE.instantiate() as MemoryPile3D
		piles_root.add_child(pile)
		pile.position = PileLayoutManager.positions_for(pile_count)[index]
		pile.setup(index, start_value)
		pile.pile_selected.connect(_on_pile_selected)
		piles.append(pile)

	message_label.text = ""
	_update_hud()
	await get_tree().create_timer(1.2).timeout
	for pile in piles:
		pile.hide_start_piece()
	await get_tree().create_timer(0.4).timeout
	_begin_turn()


func _begin_turn() -> void:
	if _all_piles_complete():
		return
	input_locked = false
	selected_piece = null
	message_label.text = ""
	_generate_hand()
	timer_manager.start_countdown(turn_time)


func _generate_hand() -> void:
	_clear_hand()
	var playable := _playable_values()
	if playable.is_empty():
		return
	var values: Array[int] = []
	for index in hand_size:
		values.append(rng.randi_range(0, start_value - 1))
	values[rng.randi_range(0, hand_size - 1)] = playable.pick_random()

	for index in values.size():
		var piece := PIECE_SCENE.instantiate() as PlayingPiece3D
		hand_root.add_child(piece)
		piece.position = _hand_position(index, values.size())
		piece.setup(values[index], true)
		piece.piece_selected.connect(_on_piece_selected)
		piece.drag_started.connect(_on_drag_started)
		hand.append(piece)


func _on_piece_selected(piece: PlayingPiece3D) -> void:
	if input_locked:
		return
	selected_piece = piece
	for item in hand:
		if is_instance_valid(item):
			item.set_selected_visual(item == piece)
	message_label.text = "TILE %d SELECTED — CHOOSE A PILE" % piece.piece_value


func _on_drag_started(piece: PlayingPiece3D) -> void:
	if input_locked:
		return
	dragging_piece = piece
	selected_piece = piece
	message_label.text = ""
	soft_audio.play_tone(420.0, 0.055, 0.08)


func _input(event: InputEvent) -> void:
	if dragging_piece == null or input_locked:
		return
	if event is InputEventMouseMotion:
		var target := _cursor_on_board(event.position, 0.62)
		dragging_piece.update_drag_target(target)
		_update_hovered_pile(target)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var dropped_piece := dragging_piece
		var target_pile := hovered_pile
		dragging_piece = null
		_clear_pile_highlights()
		if target_pile != null and target_pile.can_accept(dropped_piece.piece_value):
			selected_piece = dropped_piece
			await _place_piece(target_pile)
		else:
			if target_pile != null:
				target_pile.play_reject_effect()
			await dropped_piece.reject_and_return()
			await _handle_mistake(target_pile)


func _on_pile_selected(pile: MemoryPile3D) -> void:
	if input_locked:
		return
	if selected_piece == null or not pile.can_accept(selected_piece.piece_value):
		await _handle_mistake(pile)
		return
	await _place_piece(pile)


func _place_piece(pile: MemoryPile3D) -> void:
	input_locked = true
	timer_manager.stop_countdown()
	var piece := selected_piece
	piece.finish_drag()
	for item in hand:
		if item != piece and is_instance_valid(item):
			item.queue_free()
	hand.clear()
	score += 10 + int(timer_manager.time_left * 2.0)
	_update_best_score()
	message_label.text = ""
	piece.play_correct_effect()
	soft_audio.play_tone(720.0, 0.09, 0.11)
	await pile.place_piece(piece)
	soft_audio.play_tone(510.0, 0.055, 0.07)

	if pile.current_value == 0:
		score += 100
		_update_best_score()
		message_label.text = ""
		soft_audio.play_tone(930.0, 0.14, 0.1)
		await pile.complete_animation()
		if _all_piles_complete():
			await _finish_round()
			return
	_begin_turn()


func _handle_mistake(pile: MemoryPile3D) -> void:
	input_locked = true
	timer_manager.stop_countdown()
	mistakes_left -= 1
	soft_audio.play_error()
	if selected_piece != null:
		selected_piece.flash_error()
	message_label.text = ""
	_update_hud()
	var mistake_tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	mistake_tween.tween_property(mistakes_label, "scale", Vector2.ONE * 0.82, 0.09)
	mistake_tween.tween_property(mistakes_label, "scale", Vector2.ONE, 0.16)
	await get_tree().create_timer(0.9).timeout
	if mistakes_left <= 0:
		_finish_game()
	else:
		_begin_turn()


func _on_time_expired() -> void:
	if not input_locked:
		await _handle_mistake(null)


func _finish_round() -> void:
	input_locked = true
	score += 250 + mistakes_left * 100
	_update_best_score()
	await get_tree().create_timer(0.7).timeout
	var change := _increase_difficulty()
	soft_audio.play_tone(660.0, 0.16, 0.08)
	soft_audio.play_tone(880.0, 0.2, 0.06)
	overlay_title.text = change
	overlay_details.text = ""
	overlay_button.visible = false
	overlay.visible = true
	await get_tree().create_timer(1.15).timeout
	overlay.visible = false
	round_number += 1
	start_round()


func _finish_game() -> void:
	input_locked = true
	overlay_title.text = "GAME OVER"
	overlay_details.text = "Round reached: %d" % round_number
	overlay_button.text = "PLAY AGAIN"
	overlay_button.visible = true
	overlay_mode = "restart"
	overlay.visible = true


func _on_overlay_pressed() -> void:
	if overlay_mode == "next_round":
		round_number += 1
		overlay.visible = false
		start_round()
	elif overlay_mode == "restart":
		start_game()


func _increase_difficulty() -> String:
	var options: Array[String] = ["pile"]
	if hand_size < MAX_HAND:
		options.append("main")
	if start_value < MAX_START:
		options.append("valeur")
	if turn_time > MIN_TIME:
		options.append("temps")
	var weighted: Array[String] = []
	for option in options:
		var count := 55 if option == "pile" else (5 if option == "temps" else 20)
		for index in count:
			weighted.append(option)
	var choice: String = weighted.pick_random()
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


func _hand_position(index: int, count: int) -> Vector3:
	var spacing := 1.62 if count == 4 else 1.78
	return Vector3((index - (count - 1) * 0.5) * spacing, 0.45, 4.25)


func _cursor_on_board(screen_position: Vector2, height: float) -> Vector3:
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var plane := Plane(Vector3.UP, height)
	var intersection = plane.intersects_ray(origin, direction)
	return intersection if intersection != null else Vector3.ZERO


func _update_hovered_pile(target: Vector3) -> void:
	var closest: MemoryPile3D
	var closest_distance := 1.15
	for pile in piles:
		if pile.completed:
			continue
		var distance := Vector2(target.x, target.z).distance_to(Vector2(pile.global_position.x, pile.global_position.z))
		if distance < closest_distance:
			closest_distance = distance
			closest = pile
	if closest == hovered_pile:
		return
	_clear_pile_highlights()
	hovered_pile = closest
	if hovered_pile != null:
		var compatible := hovered_pile.can_accept(dragging_piece.piece_value)
		hovered_pile.set_drop_highlight(true, compatible)
		if compatible:
			soft_audio.play_tone(590.0, 0.045, 0.045)


func _clear_pile_highlights() -> void:
	for pile in piles:
		pile.set_drop_highlight(false)
	hovered_pile = null


func _playable_values() -> Array[int]:
	var values: Array[int] = []
	for pile in piles:
		if not pile.completed and not values.has(pile.expected_value()):
			values.append(pile.expected_value())
	return values


func _all_piles_complete() -> bool:
	for pile in piles:
		if not pile.completed:
			return false
	return not piles.is_empty()


func _clear_hand() -> void:
	hand.clear()
	_clear_node(hand_root)


func _clear_node(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _on_time_updated(time_left: float) -> void:
	timer_label.text = str(ceili(time_left))
	timer_ring.set_ratio(timer_manager.ratio())
	if time_left < 1.0 and timer_manager.running:
		var pulse := (sin(Time.get_ticks_msec() * 0.018) + 1.0) * 0.5
		timer_ring.modulate = Color.WHITE.lerp(Color("#E06455"), pulse * 0.35)
	else:
		timer_ring.modulate = Color.WHITE


func _update_hud() -> void:
	score_label.text = "%06d" % score
	best_label.text = "BEST  %06d" % best_score
	round_label.text = str(round_number)
	mistakes_label.set_remaining(mistakes_left)


func _update_best_score() -> void:
	if score > best_score:
		best_score = score
		var config := ConfigFile.new()
		config.set_value("score", "best", best_score)
		config.save("user://pile_down.cfg")
	_update_hud()


func _load_best_score() -> void:
	var config := ConfigFile.new()
	if config.load("user://pile_down.cfg") == OK:
		best_score = int(config.get_value("score", "best", 0))
