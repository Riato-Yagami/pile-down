class_name PlayingCard
extends Control

signal card_selected(card)
signal drag_started(card)
signal drag_released(card, release_position)
signal entrance_became_interactive(card)
signal forced_return_requested(card, reason)

enum DragState {
	IDLE,
	DRAGGING,
	RETURNING,
	LOCKED_OUT,
}

enum TouchState {
	IDLE,
	REVEALED,
	DRAGGING,
}

enum ForcedReturnReason {
	NONE,
	LAVA,
	HOT_POTATO,
	ROUND_END,
	MANUAL_CANCEL,
}

const Settings := preload("res://resources/scripts/settings/settings.gd")
const CardMotionControllerScript := preload(
	"res://resources/scripts/gameplay/card/CardMotionController.gd"
)
const CardAppearanceScript := preload(
	"res://resources/scripts/gameplay/card/CardAppearance.gd"
)

@export var card_value := 0
@export_group("Touch Interaction")
@export_range(0.0, 0.5, 0.01) var touch_drag_delay := 0.12
@export_range(1.0, 32.0, 1.0) var touch_drag_distance := 8.0
@export_range(0.0, 0.5, 0.01) var touch_drag_face_hold := 0.18
@export_range(0.0, 1.0, 0.05) var touch_tap_hide_delay := 0.35

@onready var visual_root: Control = %VisualRoot
@onready var face: Button = %Face
@onready var face_sprite: TextureRect = %FaceSprite
@onready var back_sprite: TextureRect = %BackSprite
@onready var value_label: Label = %ValueLabel
@onready var drag_timer: Timer = %DragTimer
@onready var drag_timer_ring: RegenerationRing = %DragTimerRing
@onready var drag_collision_area: Area2D = %DragCollisionArea

var face_up := true
var selectable := true
var dragging := false
var home_global_position := Vector2.ZERO
var stable_hand_global_position := Vector2.ZERO
var has_stable_hand_position := false
var drag_target := Vector2.ZERO
var _pointer_offset := Vector2.ZERO
var _last_target := Vector2.ZERO
var _selected := false
var _visual_tween: Tween
var hover_reveal_enabled := false
var roman_numerals_enabled := false
var wandering_enabled := false
var free_range_card := false
var wandering_origin := Vector2.ZERO
var wandering_phase := 0.0
var wandering_speed := 1.0
var wandering_radius := Vector2(24.0, 9.0)
var _hide_generation := 0
var _flip_in_progress := false
var _flip_tween: Tween
var _flip_original_y := 0.0
var _drag_starting := false
var _entrance_unlock_pending := false
var _entrance_animation_running := false
var _entrance_tween: Tween
var _entrance_home_positions: Dictionary = {}
var drag_state := DragState.IDLE
var drag_origin := Vector2.ZERO
var placement_confirmed := false
var forced_return_in_progress := false
var pointer_inside := false
var hidden_by_blind_delivery := false
var hidden_by_commit := false
var round_modifiers: RoundModifiers
var colorblind_enabled := false
var is_joker := false
var _joker_phase := 0.0
var _value_font: Font
var _value_font_size := 20
var _value_font_offset := Vector2.ZERO
var _override_hidden_tile_with_font := false
var _tile_colors: Array[Color] = Settings.TILE_COLORS.slice(0, 10)
var touch_state := TouchState.IDLE
var touch_index := -1
var touch_origin := Vector2.ZERO
var touch_position := Vector2.ZERO
var _touch_started_at_msec := 0
var _touch_generation := 0


func _ready() -> void:
	custom_minimum_size = Vector2(34, 37)
	pivot_offset = custom_minimum_size * 0.5
	face.focus_mode = Control.FOCUS_NONE
	face.gui_input.connect(_on_face_input)
	face.mouse_entered.connect(_on_mouse_entered)
	face.mouse_exited.connect(_on_mouse_exited)
	drag_timer.timeout.connect(_on_drag_timer_timeout)
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	_update_appearance()


func set_value_font(
	font: Font, font_size := 20, font_offset := Vector2.ZERO,
	override_hidden_tile_with_font := true
) -> void:
	_value_font = font
	_value_font_size = font_size
	_value_font_offset = font_offset
	_override_hidden_tile_with_font = override_hidden_tile_with_font
	if is_node_ready():
		_update_appearance()


func set_tile_palette(colors: Array[Color]) -> void:
	if colors.size() != 9:
		return
	_tile_colors = colors.duplicate()
	if is_node_ready():
		_update_appearance()


func _process(delta: float) -> void:
	CardMotionControllerScript.process(self, delta)


func setup(
	value: int,
	can_select: bool = true,
	hover_reveal := false,
	use_roman_numerals := false,
	modifiers: RoundModifiers = null
) -> void:
	round_modifiers = modifiers
	card_value = value
	hover_reveal_enabled = hover_reveal
	roman_numerals_enabled = use_roman_numerals
	set_selectable(can_select)
	reset_touch_interaction()
	face_up = not hover_reveal_enabled
	colorblind_enabled = (
		round_modifiers != null and round_modifiers.colorblind_enabled
	)
	_update_appearance()


func set_joker(enabled: bool) -> void:
	is_joker = enabled
	_update_appearance()


func enable_wandering(index: int, keep_current_position := false) -> void:
	free_range_card = true
	wandering_enabled = true
	wandering_phase = float(index) * 1.7
	var movement_intensity := (
		round_modifiers.special_rule_intensity_multiplier
		if round_modifiers != null
		else 1.0
	)
	wandering_speed = (0.65 + index * 0.11) * movement_intensity
	wandering_radius = Vector2(25.0 + index * 3.0, 8.0 + index * 2.0)
	if keep_current_position:
		var initial_offset := (
			Vector2(
				sin(wandering_phase),
				sin(wandering_phase * 1.7 + card_value)
			)
			* wandering_radius
		)
		wandering_origin = global_position - initial_offset
	else:
		wandering_origin = global_position + Vector2(
			(index - 1.5) * 4.0,
			-42.0 - index * 5.0
		)


func disable_wandering() -> void:
	wandering_enabled = false


func set_selectable(can_select: bool) -> void:
	selectable = can_select
	if is_node_ready():
		face.disabled = not can_select


func set_selected_visual(is_selected: bool) -> void:
	_selected = is_selected


func refresh_pointer_hover() -> bool:
	# Godot does not always emit hover signals when this Control moves beneath a
	# stationary pointer, so moving hand modes refresh the state explicitly.
	var is_inside := (
		selectable
		and not dragging
		and face.get_global_rect().abs().has_point(get_global_mouse_position())
	)
	if is_inside and not pointer_inside:
		_on_mouse_entered()
	elif not is_inside and pointer_inside:
		_on_mouse_exited()
	return is_inside


func begin_external_drag(pointer_position: Vector2, preserve_touch_face := false) -> void:
	_materialize_entrance_for_drag()
	wandering_enabled = false
	if (
		hidden_by_commit
	):
		face_up = false
		_update_appearance()
	elif (
		round_modifiers != null
		and round_modifiers.blind_delivery_enabled
		and not preserve_touch_face
	):
		# Mouse press can arrive before the hover flip tween has completed.
		# Hide synchronously so the value is never visible during the drag.
		hidden_by_blind_delivery = true
		face_up = false
		_update_appearance()
	elif hover_reveal_enabled:
		face_up = true
		_update_appearance()
	dragging = true
	_drag_starting = false
	drag_collision_area.monitorable = true
	drag_state = DragState.DRAGGING
	if touch_index >= 0:
		touch_state = TouchState.DRAGGING
	drag_origin = global_position
	placement_confirmed = false
	if not has_stable_hand_position:
		record_hand_position()
	home_global_position = stable_hand_global_position
	drag_target = pointer_position
	_last_target = pointer_position
	_pointer_offset = get_global_transform().affine_inverse() * pointer_position
	z_index = 100
	_animate_pose(Vector2(1.06, 1.06), -2.0)
	if preserve_touch_face and _blind_delivery_enabled():
		_schedule_blind_delivery_touch_hide()
	if (
		round_modifiers != null
		and round_modifiers.hot_potatoes_enabled
		and round_modifiers.hot_potato_drag_duration > 0.0
	):
		drag_timer.start(round_modifiers.hot_potato_drag_duration)
		drag_timer_ring.ratio = 1.0
		drag_timer_ring.visible = true


func prepare_external_drag(preserve_touch_face := false) -> void:
	_drag_starting = true
	# A hover flip animates this Control's local Y position. It must finish
	# before reparenting, otherwise its cleanup writes the old hand-local Y
	# into DragLayer and makes the card jump across a mirrored board.
	_cancel_flip_animation()
	if (
		round_modifiers != null
		and round_modifiers.blind_delivery_enabled
		and not preserve_touch_face
	):
		hidden_by_blind_delivery = true
		face_up = false
		_update_appearance()


func update_touch_drag(pointer_position: Vector2) -> void:
	drag_target = pointer_position
	if not dragging:
		return
	var drag_parent := get_parent() as CanvasItem
	if drag_parent == null:
		return
	var pointer_in_parent := (
		drag_parent.get_global_transform().affine_inverse()
		* pointer_position
	)
	var grab_offset := get_transform().basis_xform(_pointer_offset)
	position = pointer_in_parent - grab_offset
	_last_target = pointer_position


func begin_touch_interaction(index: int, pointer_position: Vector2) -> void:
	_touch_generation += 1
	touch_index = index
	touch_origin = pointer_position
	touch_position = pointer_position
	_touch_started_at_msec = Time.get_ticks_msec()
	touch_state = TouchState.REVEALED
	if hover_reveal_enabled:
		_cancel_flip_animation()
		face_up = true
		hidden_by_blind_delivery = false
		_update_appearance()


func update_touch_interaction(pointer_position: Vector2) -> void:
	touch_position = pointer_position


func touch_drag_is_ready() -> bool:
	if touch_state != TouchState.REVEALED:
		return false
	var elapsed := (Time.get_ticks_msec() - _touch_started_at_msec) / 1000.0
	return (
		elapsed >= touch_drag_delay
		and touch_origin.distance_to(touch_position) >= touch_drag_distance
	)


func finish_touch_tap() -> void:
	var should_hide := hover_reveal_enabled and touch_state == TouchState.REVEALED
	reset_touch_interaction()
	if not should_hide:
		return
	var generation := _touch_generation
	get_tree().create_timer(touch_tap_hide_delay).timeout.connect(func() -> void:
		if (
			generation == _touch_generation
			and not dragging
			and touch_state == TouchState.IDLE
		):
			flip_down(true)
	)


func reset_touch_interaction() -> void:
	_touch_generation += 1
	touch_state = TouchState.IDLE
	touch_index = -1
	touch_origin = Vector2.ZERO
	touch_position = Vector2.ZERO
	_touch_started_at_msec = 0


func _blind_delivery_enabled() -> bool:
	return round_modifiers != null and round_modifiers.blind_delivery_enabled


func _schedule_blind_delivery_touch_hide() -> void:
	var generation := _touch_generation
	get_tree().create_timer(touch_drag_face_hold).timeout.connect(func() -> void:
		if (
			generation != _touch_generation
			or not dragging
			or touch_state != TouchState.DRAGGING
		):
			return
		hidden_by_blind_delivery = true
		flip_down(true)
	)


func finish_drag() -> void:
	dragging = false
	drag_collision_area.monitorable = false
	drag_state = DragState.IDLE
	reset_touch_interaction()
	cancel_drag_timers()
	z_index = 0
	rotation = 0.0


func keep_attached_to_pointer() -> void:
	dragging = true
	drag_state = DragState.LOCKED_OUT
	z_index = 100


func confirm_drop() -> void:
	placement_confirmed = true
	drag_collision_area.monitorable = false
	cancel_drag_timers()


func cancel_drag_timers() -> void:
	drag_timer.stop()
	drag_timer_ring.visible = false


func request_forced_return(reason: ForcedReturnReason) -> void:
	if forced_return_in_progress or placement_confirmed:
		return
	forced_return_in_progress = true
	cancel_drag_timers()
	forced_return_requested.emit(self, reason)


func complete_forced_return() -> void:
	forced_return_in_progress = false
	drag_state = DragState.IDLE
	end_commit()


func begin_commit() -> void:
	hidden_by_commit = true
	_cancel_flip_animation()
	face_up = false
	_update_appearance()


func end_commit() -> void:
	if not hidden_by_commit:
		return
	hidden_by_commit = false
	face_up = not hover_reveal_enabled
	_update_appearance()


func animate_return(destination: Vector2, duration := 0.26) -> void:
	drag_state = DragState.RETURNING
	dragging = false
	drag_collision_area.monitorable = false
	cancel_drag_timers()
	z_index = 0
	rotation = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", destination, duration)
	await tween.finished
	drag_state = DragState.IDLE
	end_commit()
	if hover_reveal_enabled:
		await flip_down(true)
	elif (
		round_modifiers != null
		and round_modifiers.blind_delivery_enabled
	):
		pointer_inside = get_global_rect().abs().has_point(
			get_global_mouse_position()
		)
		hidden_by_blind_delivery = pointer_inside
		if pointer_inside:
			await flip_down(true)
		else:
			await flip_up(true)


func reset_hand_pose() -> void:
	if _visual_tween != null and _visual_tween.is_valid():
		_visual_tween.kill()
	scale = Vector2.ONE
	rotation = 0.0
	face_sprite.position.y = 0.0
	back_sprite.position.y = 0.0
	_apply_value_label_offset()
	drag_timer_ring.visible = false
	z_index = 0


func record_hand_position() -> void:
	stable_hand_global_position = global_position
	home_global_position = stable_hand_global_position
	has_stable_hand_position = true


func hand_return_position() -> Vector2:
	return stable_hand_global_position if has_stable_hand_position else home_global_position


func animate_valid_drop(destination: Vector2, duration := 0.14) -> void:
	finish_drag()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", destination, duration)
	tween.parallel().tween_property(self, "scale", Vector2(0.94, 0.94), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)
	await tween.finished


func play_draw(delay: float) -> void:
	# Capture the HBox slot before the entrance offset is applied. A press
	# during the tween must still return to the stable layout position.
	record_hand_position()
	modulate.a = 0.0
	position.y += 9.0
	var destination_y := position.y - 9.0
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(delay)
	tween.tween_property(self, "position:y", destination_y, 0.18)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.14)


func play_draw_from_right(delay: float) -> void:
	set_selectable(false)
	_entrance_unlock_pending = true
	_entrance_animation_running = true
	# Wait until the hand container has assigned the final slot. Computing the
	# entrance offset earlier can use the previous card's layout position.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	record_hand_position()
	_entrance_home_positions.clear()
	var entrance_offset := get_viewport_rect().size.x + size.x + 12.0 - global_position.x
	var visuals: Array[Control] = [visual_root]
	for visual in visuals:
		_entrance_home_positions[visual] = visual.position
		visual.position.x += entrance_offset
	modulate.a = 0.0
	rotation = 0.1
	_entrance_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_entrance_tween.tween_interval(delay)
	_entrance_tween.set_parallel(true)
	for visual in visuals:
		_entrance_tween.tween_property(
			visual,
			"position",
			_entrance_home_positions[visual],
			0.28
		)
	_entrance_tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_entrance_tween.tween_property(self, "rotation", 0.0, 0.24)
	_entrance_tween.set_parallel(false)
	_entrance_tween.tween_callback(_finish_entrance_animation)


func play_draw_in_place(delay: float) -> void:
	modulate.a = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(delay)
	tween.tween_property(self, "modulate:a", 1.0, 0.14)


func play_wandering_entrance(
	index: int,
	destination: Vector2,
	screen_size: Vector2,
	delay: float
) -> void:
	free_range_card = true
	wandering_enabled = false
	set_selectable(false)
	_entrance_unlock_pending = true
	var destination_center := destination + size * 0.5
	var edge_distances := [
		destination_center.x,
		screen_size.x - destination_center.x,
		destination_center.y,
		screen_size.y - destination_center.y,
	]
	var closest_edge := edge_distances.find(edge_distances.min())
	match closest_edge:
		0:
			global_position = Vector2(-size.x - 12.0, destination.y)
		1:
			global_position = Vector2(screen_size.x + 12.0, destination.y)
		2:
			global_position = Vector2(destination.x, -size.y - 12.0)
		_:
			global_position = Vector2(destination.x, screen_size.y + 12.0)
	modulate.a = 0.0
	rotation = -0.12 if closest_edge == 0 or closest_edge == 3 else 0.12
	_entrance_animation_running = true
	_entrance_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_entrance_tween.tween_interval(delay)
	_entrance_tween.tween_property(self, "global_position", destination, 0.28)
	_entrance_tween.parallel().tween_property(self, "modulate:a", 1.0, 0.18)
	_entrance_tween.parallel().tween_property(self, "rotation", 0.0, 0.24)
	_entrance_tween.tween_callback(func() -> void:
		_entrance_animation_running = false
		enable_wandering(index, true)
		_complete_entrance_interaction()
	)


func _materialize_entrance_for_drag() -> void:
	if not _entrance_animation_running:
		return
	var visual_global_position := visual_root.global_position
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
	if not _entrance_home_positions.is_empty():
		global_position = (
			visual_global_position
			- (_entrance_home_positions[visual_root] as Vector2)
		)
		for visual in _entrance_home_positions:
			(visual as Control).position = _entrance_home_positions[visual]
	_entrance_home_positions.clear()
	_entrance_animation_running = false
	_entrance_unlock_pending = false
	rotation = 0.0
	modulate.a = 1.0


func _finish_entrance_animation() -> void:
	for visual in _entrance_home_positions:
		(visual as Control).position = _entrance_home_positions[visual]
	_entrance_home_positions.clear()
	_entrance_animation_running = false
	_complete_entrance_interaction()


func finish_entrance_immediately() -> void:
	if not _entrance_animation_running:
		return
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
	for visual in _entrance_home_positions:
		(visual as Control).position = _entrance_home_positions[visual]
	_entrance_home_positions.clear()
	_entrance_animation_running = false
	modulate.a = 1.0
	rotation = 0.0
	_complete_entrance_interaction()


func _complete_entrance_interaction() -> void:
	if not _entrance_unlock_pending:
		return
	_entrance_unlock_pending = false
	set_selectable(true)
	entrance_became_interactive.emit(self)


func play_wandering_exit(screen_width: float, delay: float) -> float:
	wandering_enabled = false
	set_selectable(false)
	var exits_left := global_position.x + size.x * 0.5 < screen_width * 0.5
	var destination_x := -size.x - 14.0 if exits_left else screen_width + 14.0
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(delay)
	tween.tween_property(
		self,
		"global_position",
		Vector2(destination_x, global_position.y + 8.0),
		0.26
	)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.18)
	tween.parallel().tween_property(self, "rotation", -0.16 if exits_left else 0.16, 0.22)
	return delay + 0.26


func flip_down(animated: bool = true) -> void:
	if not face_up or _flip_in_progress:
		return
	if animated:
		_flip_in_progress = true
		_flip_original_y = position.y
		_flip_tween = create_tween().set_trans(Tween.TRANS_SINE)
		_flip_tween.tween_property(self, "scale:x", 0.02, 0.07)
		_flip_tween.parallel().tween_property(self, "position:y", _flip_original_y - 3.0, 0.07)
		_flip_tween.tween_callback(func() -> void:
			face_up = false
			_update_appearance()
		)
		_flip_tween.tween_property(self, "scale:x", 1.0, 0.07)
		_flip_tween.parallel().tween_property(self, "position:y", _flip_original_y, 0.07)
		await _flip_tween.finished
		position.y = _flip_original_y
		_flip_in_progress = false
	else:
		face_up = false
		_update_appearance()


func flip_up(animated: bool = true) -> void:
	if face_up or _flip_in_progress:
		return
	if animated:
		_flip_in_progress = true
		_flip_original_y = position.y
		_flip_tween = create_tween().set_trans(Tween.TRANS_SINE)
		_flip_tween.tween_property(self, "scale:x", 0.02, 0.07)
		_flip_tween.tween_callback(func() -> void:
			face_up = true
			_update_appearance()
		)
		_flip_tween.tween_property(self, "scale:x", 1.0, 0.07)
		await _flip_tween.finished
		_flip_in_progress = false
	else:
		face_up = true
		_update_appearance()


func flash_error() -> void:
	if _visual_tween != null and _visual_tween.is_valid():
		_visual_tween.kill()
	var tween := create_tween()
	tween.tween_property(face_sprite, "modulate", Color("#F3B2AA"), 0.08)
	tween.tween_property(face_sprite, "modulate", Color.WHITE, 0.12)
	tween.tween_callback(func() -> void:
		face_sprite.modulate = Color.WHITE
	)
	await tween.finished


func _on_face_input(event: InputEvent) -> void:
	if not selectable:
		return
	var blind_delivery_enabled := (
		round_modifiers != null
		and round_modifiers.blind_delivery_enabled
	)
	if hover_reveal_enabled and not blind_delivery_enabled and not hidden_by_commit and not face_up:
		await flip_up(true)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_target = get_global_mouse_position()
			card_selected.emit(self)
			drag_started.emit(self)
		else:
			drag_released.emit(self, get_global_mouse_position())
		face.accept_event()
	elif event is InputEventMouseMotion and dragging:
		drag_target = get_global_mouse_position()
		face.accept_event()


func _on_mouse_entered() -> void:
	if pointer_inside:
		return
	pointer_inside = true
	if selectable and not dragging:
		_hide_generation += 1
		if hover_reveal_enabled and not hidden_by_commit:
			flip_up(true)
		elif (
			round_modifiers != null
			and round_modifiers.blind_delivery_enabled
		):
			hidden_by_blind_delivery = true
			flip_down(true)
		_animate_pose(Vector2(1.035, 1.035), -1.0)


func _on_mouse_exited() -> void:
	if not pointer_inside:
		return
	pointer_inside = false
	if selectable and not dragging and not _drag_starting:
		if hover_reveal_enabled:
			_hide_generation += 1
			var generation := _hide_generation
			get_tree().create_timer(0.15).timeout.connect(func() -> void:
				if generation == _hide_generation and not dragging:
					flip_down(true)
			)
		elif (
			round_modifiers != null
			and round_modifiers.blind_delivery_enabled
		):
			hidden_by_blind_delivery = false
			flip_up(true)
		_animate_pose(Vector2.ONE, 0.0)


func _cancel_flip_animation() -> void:
	if _flip_tween != null and _flip_tween.is_valid():
		_flip_tween.kill()
	if _flip_in_progress:
		position.y = _flip_original_y
		scale.x = 1.0
	_flip_in_progress = false


func _animate_pose(target_scale: Vector2, y_offset: float) -> void:
	if _visual_tween != null and _visual_tween.is_valid():
		_visual_tween.kill()
	_visual_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_visual_tween.tween_property(self, "scale", target_scale, 0.12)
	_visual_tween.tween_property(face_sprite, "position:y", y_offset, 0.12)
	_visual_tween.tween_property(back_sprite, "position:y", y_offset, 0.12)
	_visual_tween.tween_property(
		value_label, "position:y", _value_font_offset.y + y_offset, 0.12
	)


func _apply_value_label_offset(pose_y := 0.0) -> void:
	value_label.offset_left = _value_font_offset.x
	value_label.offset_right = _value_font_offset.x
	value_label.offset_top = _value_font_offset.y + pose_y
	value_label.offset_bottom = _value_font_offset.y + pose_y - 2.0


func _update_appearance() -> void:
	CardAppearanceScript.update(self)


func set_colorblind_enabled(enabled: bool) -> void:
	colorblind_enabled = enabled
	_update_appearance()


func reveal_for_cleanup() -> void:
	hidden_by_blind_delivery = false
	cancel_drag_timers()
	if not face_up:
		flip_up(false)


func _on_drag_timer_timeout() -> void:
	if placement_confirmed or not dragging:
		return
	request_forced_return(ForcedReturnReason.HOT_POTATO)
