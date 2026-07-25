class_name PlayingCard
extends Control

signal card_selected(card)
signal drag_started(card)
signal drag_released(card, release_position)
signal entrance_became_interactive(card)

const TINY_REGULAR_FONT := preload("res://resources/fonts/Tiny5-Regular.ttf")
const Settings := preload("res://resources/scripts/settings/settings.gd")

@export var card_value := 0

@onready var face: Button = %Face
@onready var face_sprite: TextureRect = %FaceSprite
@onready var back_sprite: TextureRect = %BackSprite
@onready var value_label: Label = %ValueLabel

var face_up := true
var selectable := true
var dragging := false
var home_global_position := Vector2.ZERO
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
var _entrance_unlock_pending := false
var _entrance_animation_running := false
var _entrance_tween: Tween
var _entrance_home_positions: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(34, 37)
	pivot_offset = custom_minimum_size * 0.5
	face.focus_mode = Control.FOCUS_NONE
	face.gui_input.connect(_on_face_input)
	face.mouse_entered.connect(_on_mouse_entered)
	face.mouse_exited.connect(_on_mouse_exited)
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	_update_appearance()


func _process(delta: float) -> void:
	if (
		_entrance_unlock_pending
		and Rect2(Vector2.ZERO, get_viewport_rect().size).intersects(face.get_global_rect())
	):
		_entrance_unlock_pending = false
		set_selectable(true)
		entrance_became_interactive.emit(self)
	if wandering_enabled and not dragging:
		wandering_phase += delta * wandering_speed
		global_position = (
			wandering_origin
			+ Vector2(sin(wandering_phase), sin(wandering_phase * 1.7 + card_value)) * wandering_radius
		).round()
	if not dragging:
		return
	var previous := global_position
	global_position = global_position.lerp(drag_target - _pointer_offset, minf(delta * 20.0, 1.0))
	var velocity := (drag_target - _last_target) / maxf(delta, 0.001)
	rotation = lerpf(rotation, clampf(velocity.x * 0.00004, -0.07, 0.07), minf(delta * 12.0, 1.0))
	_last_target = drag_target
	if previous.distance_to(global_position) > 0.1:
		move_to_front()


func setup(
	value: int,
	can_select: bool = true,
	hover_reveal := false,
	use_roman_numerals := false
) -> void:
	card_value = value
	hover_reveal_enabled = hover_reveal
	roman_numerals_enabled = use_roman_numerals
	set_selectable(can_select)
	face_up = not hover_reveal_enabled
	_update_appearance()


func enable_wandering(index: int, keep_current_position := false) -> void:
	free_range_card = true
	wandering_enabled = true
	wandering_phase = float(index) * 1.7
	wandering_speed = 0.65 + index * 0.11
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


func begin_external_drag(pointer_position: Vector2) -> void:
	_materialize_entrance_for_drag()
	wandering_enabled = false
	if hover_reveal_enabled:
		face_up = true
		_update_appearance()
	dragging = true
	home_global_position = global_position
	drag_target = pointer_position
	_last_target = pointer_position
	_pointer_offset = pointer_position - global_position
	z_index = 100
	_animate_pose(Vector2(1.06, 1.06), -2.0)


func finish_drag() -> void:
	dragging = false
	z_index = 0
	rotation = 0.0


func animate_return(destination: Vector2, duration := 0.26) -> void:
	finish_drag()
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", destination, duration)
	await tween.finished


func animate_valid_drop(destination: Vector2) -> void:
	finish_drag()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", destination, 0.14)
	tween.parallel().tween_property(self, "scale", Vector2(0.94, 0.94), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)
	await tween.finished


func play_draw(delay: float) -> void:
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
	_entrance_home_positions.clear()
	var entrance_offset := get_viewport_rect().size.x + size.x + 12.0 - global_position.x
	var visuals: Array[Control] = [face, face_sprite, back_sprite, value_label]
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
		set_selectable(true)
	)


func _materialize_entrance_for_drag() -> void:
	if not _entrance_animation_running:
		return
	var visual_global_position := face.global_position
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
	if not _entrance_home_positions.is_empty():
		global_position = visual_global_position - (_entrance_home_positions[face] as Vector2)
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
		var original_y := position.y
		var tween := create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "scale:x", 0.02, 0.07)
		tween.parallel().tween_property(self, "position:y", original_y - 3.0, 0.07)
		tween.tween_callback(func() -> void:
			face_up = false
			_update_appearance()
		)
		tween.tween_property(self, "scale:x", 1.0, 0.07)
		tween.parallel().tween_property(self, "position:y", original_y, 0.07)
		await tween.finished
		position.y = original_y
		_flip_in_progress = false
	else:
		face_up = false
		_update_appearance()


func flip_up(animated: bool = true) -> void:
	if face_up or _flip_in_progress:
		return
	if animated:
		_flip_in_progress = true
		var tween := create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "scale:x", 0.02, 0.07)
		tween.tween_callback(func() -> void:
			face_up = true
			_update_appearance()
		)
		tween.tween_property(self, "scale:x", 1.0, 0.07)
		await tween.finished
		_flip_in_progress = false
	else:
		face_up = true
		_update_appearance()


func flash_error() -> void:
	var original_x := position.x
	var tween := create_tween()
	face_sprite.modulate = Color("#F3B2AA")
	for offset in [-6.0, 6.0, -4.0, 4.0, 0.0]:
		tween.tween_property(self, "position:x", original_x + offset, 0.04)
	tween.tween_callback(func() -> void: face_sprite.modulate = Color.WHITE)
	await tween.finished


func _on_face_input(event: InputEvent) -> void:
	if not selectable:
		return
	if hover_reveal_enabled and not face_up:
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
	elif event is InputEventScreenTouch:
		if event.pressed:
			drag_target = event.position
			card_selected.emit(self)
			drag_started.emit(self)
		else:
			drag_released.emit(self, event.position)
		face.accept_event()
	elif event is InputEventScreenDrag and dragging:
		drag_target = event.position
		face.accept_event()


func _on_mouse_entered() -> void:
	if selectable and not dragging:
		_hide_generation += 1
		if hover_reveal_enabled:
			flip_up(true)
		_animate_pose(Vector2(1.035, 1.035), -1.0)


func _on_mouse_exited() -> void:
	if selectable and not dragging:
		if hover_reveal_enabled:
			_hide_generation += 1
			var generation := _hide_generation
			get_tree().create_timer(0.15).timeout.connect(func() -> void:
				if generation == _hide_generation and not dragging:
					flip_down(true)
			)
		_animate_pose(Vector2.ONE, 0.0)


func _animate_pose(target_scale: Vector2, y_offset: float) -> void:
	if _visual_tween != null and _visual_tween.is_valid():
		_visual_tween.kill()
	_visual_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_visual_tween.tween_property(self, "scale", target_scale, 0.12)
	_visual_tween.tween_property(face_sprite, "position:y", y_offset, 0.12)
	_visual_tween.tween_property(back_sprite, "position:y", y_offset, 0.12)
	_visual_tween.tween_property(value_label, "position:y", y_offset, 0.12)


func _update_appearance() -> void:
	if not is_node_ready():
		return
	var color: Color = Settings.TILE_COLORS[card_value % Settings.TILE_COLORS.size()]
	face_sprite.visible = face_up
	back_sprite.visible = not face_up
	var tile_material := face_sprite.material as ShaderMaterial
	tile_material.set_shader_parameter("tile_color", color)
	value_label.visible = face_up
	value_label.text = RoundModifiers.format_value(card_value, roman_numerals_enabled)
	value_label.add_theme_font_size_override(
		"font_size",
		RoundModifiers.value_font_size(card_value, roman_numerals_enabled)
	)
	if roman_numerals_enabled and card_value in [7, 8]:
		value_label.add_theme_font_override("font", TINY_REGULAR_FONT)
	else:
		value_label.remove_theme_font_override("font")
	value_label.add_theme_color_override("font_color", color.darkened(0.35))
