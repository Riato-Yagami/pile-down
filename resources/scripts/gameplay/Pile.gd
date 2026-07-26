class_name MemoryPile
extends Control

const TINY_REGULAR_FONT := preload("res://resources/fonts/Tiny5-Regular.ttf")

signal pile_selected(pile)
signal pile_completed(pile)
signal regenerated(pile, delta)

const Settings := preload("res://resources/scripts/settings/settings.gd")

@onready var glow: Panel = %Glow
@onready var face: Button = %Face
@onready var face_sprite: TextureRect = %FaceSprite
@onready var back_sprite: TextureRect = %BackSprite
@onready var value_label: Label = %ValueLabel
@onready var regeneration_ring: RegenerationRing = $RegenerationRing

var pile_index := 0
var start_value := 5
var current_value := 5
var completed := false
var face_up := true
var history: Array[int] = []
var stack_direction := RoundModifiers.StackDirection.DOWN
var roman_numerals_enabled := false
var regeneration_duration := 0.0
var regeneration_timer: Timer
var regeneration_enabled := false
var _hovered_for_drop := false
var _visual_tween: Tween
var colorblind_enabled := false
var keep_face_up := false
var bonus_highlight := false


func _ready() -> void:
	custom_minimum_size = Vector2(34, 37)
	pivot_offset = custom_minimum_size * 0.5
	face.focus_mode = Control.FOCUS_NONE
	face.pressed.connect(func() -> void: pile_selected.emit(self))
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	_refresh()


func setup(
	index: int,
	value: int,
	direction := RoundModifiers.StackDirection.DOWN,
	use_roman_numerals := false,
	colorblind := false
) -> void:
	pile_index = index
	start_value = value
	stack_direction = direction
	roman_numerals_enabled = use_roman_numerals
	colorblind_enabled = colorblind
	current_value = 0 if stack_direction == RoundModifiers.StackDirection.UP else value
	completed = false
	face_up = true
	history.assign([value])
	visible = true
	face.disabled = false
	modulate = Color.WHITE
	scale = Vector2.ONE
	rotation = 0.0
	keep_face_up = false
	bonus_highlight = false
	_refresh()


func expected_value() -> int:
	return current_value + 1 if stack_direction == RoundModifiers.StackDirection.UP else current_value - 1


func can_accept(value: int) -> bool:
	return not completed and value == expected_value()


func contains_global_point(global_point: Vector2, margin: float = 0.0) -> bool:
	# Test in pile-local coordinates so Mirror Match's pivot and negative axes
	# affect the visual and its drop area identically.
	var local_point := get_global_transform().affine_inverse() * global_point
	return Rect2(Vector2.ZERO, size).grow(margin).has_point(local_point)


func place(value: int) -> void:
	current_value = value
	history.append(value)
	face_up = true
	_refresh()
	impact()
	if regeneration_timer != null:
		regeneration_timer.start(regeneration_duration)


func is_complete_value() -> bool:
	return (
		current_value >= start_value
		if stack_direction == RoundModifiers.StackDirection.UP
		else current_value <= 0
	)


func enable_regeneration(duration: float) -> void:
	regeneration_enabled = true
	regeneration_duration = duration
	regeneration_ring.ratio = 1.0
	_update_regeneration_ring_visibility()
	if regeneration_timer == null:
		regeneration_timer = Timer.new()
		regeneration_timer.one_shot = true
		regeneration_timer.timeout.connect(_regenerate)
		add_child(regeneration_timer)
	regeneration_timer.start(regeneration_duration)


func disable_regeneration() -> void:
	regeneration_enabled = false
	if regeneration_timer != null:
		regeneration_timer.stop()
	regeneration_ring.visible = false
	regeneration_ring.ratio = 1.0


func _process(_delta: float) -> void:
	if regeneration_timer != null and not regeneration_timer.is_stopped() and regeneration_ring != null:
		regeneration_ring.ratio = regeneration_timer.time_left / regeneration_duration


func _regenerate() -> void:
	if completed or not regeneration_enabled or not _can_regenerate():
		_update_regeneration_ring_visibility()
		return
	var delta := -1 if stack_direction == RoundModifiers.StackDirection.UP else 1
	var previous := current_value
	current_value = (
		maxi(current_value - 1, 0)
		if stack_direction == RoundModifiers.StackDirection.UP
		else mini(current_value + 1, start_value)
	)
	if current_value != previous:
		_refresh()
		_show_floating_text("-1" if delta < 0 else "+1")
		regenerated.emit(self, delta)
		await reveal_value_temporarily()
	if _can_regenerate():
		regeneration_timer.start(regeneration_duration)
	_update_regeneration_ring_visibility()


func _can_regenerate() -> bool:
	if stack_direction == RoundModifiers.StackDirection.UP:
		return current_value > 0
	return current_value < start_value


func _update_regeneration_ring_visibility() -> void:
	if regeneration_ring == null:
		return
	regeneration_ring.visible = (
		regeneration_enabled
		and not completed
		and not face_up
		and _can_regenerate()
	)


func reveal_value_temporarily(visible_duration := 0.45) -> void:
	if completed or face_up:
		return
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale:x", 0.02, 0.1)
	tween.tween_callback(func() -> void:
		face_up = true
		_refresh()
	)
	tween.tween_property(self, "scale:x", 1.0, 0.1)
	tween.tween_interval(visible_duration)
	tween.tween_property(self, "scale:x", 0.02, 0.1)
	tween.tween_callback(func() -> void:
		face_up = false
		_refresh()
	)
	tween.tween_property(self, "scale:x", 1.0, 0.1)
	await tween.finished


func _show_floating_text(text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 20)
	label.position = Vector2(7.0, -12.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", -20.0, 0.45)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.45)
	tween.finished.connect(label.queue_free)


func hide_value(animated: bool = true) -> void:
	if completed or keep_face_up:
		return
	if animated:
		var tween := create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "scale:x", 0.02, 0.12)
		tween.tween_callback(func() -> void:
			face_up = false
			_refresh()
		)
		tween.tween_property(self, "scale:x", 1.0, 0.12)
		await tween.finished
	else:
		face_up = false
		_refresh()


func set_bonus_highlight(enabled: bool) -> void:
	bonus_highlight = enabled
	if enabled:
		glow.visible = true
		glow.modulate = Color("#D9A514", 0.4)
	elif not _hovered_for_drop:
		glow.visible = false


func set_bonus_revealed(revealed: bool) -> void:
	if completed or (not revealed and keep_face_up):
		return
	face_up = revealed
	_refresh()


func show_quick_peek_flash() -> void:
	if completed or face_up:
		return
	if _visual_tween != null and _visual_tween.is_valid():
		_visual_tween.kill()
	face_up = true
	_refresh()
	scale = Vector2(0.9, 0.9)
	modulate = Color(1.25, 1.25, 1.25, 0.35)
	glow.visible = bonus_highlight
	_visual_tween = (
		create_tween()
		.set_parallel()
		.set_trans(Tween.TRANS_BACK)
		.set_ease(Tween.EASE_OUT)
	)
	_visual_tween.tween_property(self, "scale", Vector2.ONE, 0.09)
	_visual_tween.tween_property(self, "modulate", Color.WHITE, 0.07)


func hide_quick_peek_flash() -> void:
	if completed or keep_face_up:
		return
	if _visual_tween != null and _visual_tween.is_valid():
		_visual_tween.kill()
	_visual_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
	_visual_tween.tween_property(face_sprite, "modulate:a", 0.0, 0.06)
	_visual_tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.06)
	await _visual_tween.finished
	face_up = false
	face_sprite.modulate = Color.WHITE
	scale = Vector2.ONE
	modulate = Color.WHITE
	_refresh()
	glow.visible = bonus_highlight


func set_drop_feedback(active: bool) -> void:
	if completed or (_hovered_for_drop == active and not active):
		return
	_hovered_for_drop = active
	if _visual_tween != null and _visual_tween.is_valid():
		_visual_tween.kill()
	_visual_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if active:
		glow.visible = true
		glow.modulate = Color(0.31, 0.64, 0.63, 0.24)
		_visual_tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.12)
		_visual_tween.tween_property(face, "position:y", -3.0, 0.12)
	else:
		glow.visible = bonus_highlight
		if bonus_highlight:
			glow.modulate = Color("#D9A514", 0.4)
		_visual_tween.tween_property(self, "scale", Vector2.ONE, 0.12)
		_visual_tween.tween_property(face, "position:y", 0.0, 0.12)


func flash_invalid() -> void:
	set_drop_feedback(false)
	var original_y := position.y
	var tween := create_tween()
	tween.tween_property(self, "position:y", original_y + 4.0, 0.06)
	tween.tween_property(self, "position:y", original_y, 0.1)
	await tween.finished


func impact() -> void:
	glow.visible = true
	glow.modulate = Color(0.31, 0.64, 0.63, 0.22)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.94, 0.94), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.24)
	await tween.finished
	glow.visible = bonus_highlight
	if bonus_highlight:
		glow.modulate = Color("#D9A514", 0.4)


func complete_animation() -> void:
	completed = true
	disable_regeneration()
	face.disabled = true
	face_up = true
	_refresh()
	glow.visible = true
	glow.modulate = Color(0.31, 0.64, 0.63, 0.25)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", position.y - 3.0, 0.18)
	tween.parallel().tween_property(self, "scale", Vector2(1.06, 1.06), 0.18)
	tween.tween_interval(0.28)
	tween.tween_property(self, "scale", Vector2(0.82, 0.82), 0.22)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.22)
	await tween.finished
	visible = false
	pile_completed.emit(self)


func play_entrance(delay: float) -> void:
	var destination := position
	position.y += 3.0
	scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(delay)
	tween.tween_property(self, "position", destination, 0.25)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.25)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.2)


func _refresh() -> void:
	if not is_node_ready():
		return
	var color: Color = Settings.TILE_COLORS[current_value % Settings.TILE_COLORS.size()]
	var visual_color := Color("#8B8B8B") if colorblind_enabled else color
	face_sprite.visible = face_up
	back_sprite.visible = not face_up
	back_sprite.modulate = Color.WHITE
	_update_regeneration_ring_visibility()
	var tile_material := face_sprite.material as ShaderMaterial
	tile_material.set_shader_parameter("tile_color", visual_color)
	var back_tile_material := back_sprite.material as ShaderMaterial
	back_tile_material.set_shader_parameter("tile_color", visual_color)
	value_label.visible = face_up
	value_label.text = RoundModifiers.format_value(current_value, roman_numerals_enabled)
	value_label.add_theme_font_size_override(
		"font_size",
		RoundModifiers.value_font_size(current_value, roman_numerals_enabled)
	)
	if roman_numerals_enabled and current_value in [7, 8]:
		value_label.add_theme_font_override("font", TINY_REGULAR_FONT)
	else:
		value_label.remove_theme_font_override("font")
	value_label.add_theme_color_override(
		"font_color",
		Settings.COLORBLIND_VALUE_COLOR if colorblind_enabled else color.darkened(0.35)
	)


func set_colorblind_enabled(enabled: bool) -> void:
	colorblind_enabled = enabled
	_refresh()
