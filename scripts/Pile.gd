class_name MemoryPile
extends Control

signal pile_selected(pile)
signal pile_completed(pile)

const COLORS := PlayingCard.COLORS

@onready var glow: Panel = %Glow
@onready var face: Button = %Face
@onready var face_sprite: TextureRect = %FaceSprite
@onready var back_sprite: TextureRect = %BackSprite
@onready var value_label: Label = %ValueLabel

var pile_index := 0
var start_value := 5
var current_value := 5
var completed := false
var face_up := true
var history: Array[int] = []
var _hovered_for_drop := false
var _visual_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(34, 37)
	pivot_offset = custom_minimum_size * 0.5
	face.focus_mode = Control.FOCUS_NONE
	face.pressed.connect(func() -> void: pile_selected.emit(self))
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	_refresh()


func setup(index: int, value: int) -> void:
	pile_index = index
	start_value = value
	current_value = value
	completed = false
	face_up = true
	history.assign([value])
	visible = true
	face.disabled = false
	modulate = Color.WHITE
	scale = Vector2.ONE
	rotation = 0.0
	_refresh()


func expected_value() -> int:
	return current_value - 1


func can_accept(value: int) -> bool:
	return not completed and value == expected_value()


func place(value: int) -> void:
	current_value = value
	history.append(value)
	face_up = true
	_refresh()
	impact()


func hide_value(animated: bool = true) -> void:
	if completed:
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


func set_drop_feedback(active: bool, compatible: bool = false) -> void:
	if completed or (_hovered_for_drop == active and not active):
		return
	_hovered_for_drop = active
	if _visual_tween != null and _visual_tween.is_valid():
		_visual_tween.kill()
	_visual_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if active and compatible:
		glow.visible = true
		glow.modulate = Color(0.31, 0.64, 0.63, 0.24)
		_visual_tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.12)
		_visual_tween.tween_property(face, "position:y", -3.0, 0.12)
	elif active:
		glow.visible = true
		glow.modulate = Color(0.88, 0.39, 0.33, 0.09)
		_visual_tween.tween_property(self, "scale", Vector2(0.99, 0.99), 0.12)
	else:
		glow.visible = false
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
	glow.visible = false


func complete_animation() -> void:
	completed = true
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
	var color: Color = COLORS[current_value % COLORS.size()]
	face_sprite.visible = face_up
	back_sprite.visible = not face_up
	var tile_material := face_sprite.material as ShaderMaterial
	tile_material.set_shader_parameter("tile_color", color)
	value_label.visible = face_up
	value_label.text = str(current_value)
	value_label.add_theme_color_override("font_color", color.darkened(0.35))
