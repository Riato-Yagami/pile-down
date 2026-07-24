class_name PlayingCard
extends Control

signal card_selected(card)
signal drag_started(card)
signal drag_released(card, release_position)

const COLORS := [
	Color("#4D82C2"),
	Color("#4EA3A2"),
	Color("#739A62"),
	Color("#D0A13A"),
	Color("#E06455"),
	Color("#8772B5"),
]

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
var wandering_origin := Vector2.ZERO
var wandering_phase := 0.0
var wandering_speed := 1.0
var wandering_radius := Vector2(24.0, 9.0)
var _hide_generation := 0
var _flip_in_progress := false


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
	wandering_enabled = true
	wandering_origin = (
		global_position
		if keep_current_position
		else global_position + Vector2((index - 1.5) * 4.0, -42.0 - index * 5.0)
	)
	wandering_phase = float(index) * 1.7
	wandering_speed = 0.65 + index * 0.11
	wandering_radius = Vector2(25.0 + index * 3.0, 8.0 + index * 2.0)


func disable_wandering() -> void:
	wandering_enabled = false


func set_selectable(can_select: bool) -> void:
	selectable = can_select
	if is_node_ready():
		face.disabled = not can_select


func set_selected_visual(is_selected: bool) -> void:
	_selected = is_selected


func begin_external_drag(pointer_position: Vector2) -> void:
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


func play_draw_in_place(delay: float) -> void:
	modulate.a = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(delay)
	tween.tween_property(self, "modulate:a", 1.0, 0.14)


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
	var color: Color = COLORS[card_value % COLORS.size()]
	face_sprite.visible = face_up
	back_sprite.visible = not face_up
	var tile_material := face_sprite.material as ShaderMaterial
	tile_material.set_shader_parameter("tile_color", color)
	value_label.visible = face_up
	value_label.text = RoundModifiers.format_value(card_value, roman_numerals_enabled)
	value_label.add_theme_color_override("font_color", color.darkened(0.35))
