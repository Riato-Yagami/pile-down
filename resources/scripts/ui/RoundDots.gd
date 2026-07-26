class_name RoundDots
extends Control

const FULL_TEXTURE := preload("res://resources/sprites/hand/life/life-point-full.png")
const EMPTY_TEXTURE := preload("res://resources/sprites/hand/life/life-point-empty.png")

var remaining := 3
var maximum := 3

@onready var life_points: Array[TextureRect] = [
	%LifePoint1,
	%LifePoint2,
	%LifePoint3,
]


func _ready() -> void:
	custom_minimum_size = Vector2(10, 32)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_life_points()


func set_remaining(value: int) -> void:
	remaining = clampi(value, 0, maximum)
	if is_node_ready():
		_update_life_points()


func set_maximum(value: int) -> void:
	maximum = clampi(value, 1, 3)
	remaining = mini(remaining, maximum)
	if is_node_ready():
		_update_life_points()


func play_damage(remaining_after_hit: int) -> void:
	if not is_node_ready():
		return
	var damaged_index := clampi(remaining_after_hit, 0, maximum - 1)
	var life_point := life_points[damaged_index]
	life_point.texture = FULL_TEXTURE
	life_point.visible = true
	life_point.pivot_offset = life_point.size * 0.5
	life_point.modulate = Color.WHITE
	life_point.scale = Vector2.ONE
	var tween := create_tween().set_trans(Tween.TRANS_BACK)
	tween.tween_property(life_point, "scale", Vector2(1.22, 0.82), 0.12)
	tween.parallel().tween_property(
		life_point,
		"modulate",
		Color("#E2554F"),
		0.12
	)
	tween.tween_property(life_point, "scale", Vector2.ZERO, 0.24)
	tween.parallel().tween_property(life_point, "modulate:a", 0.0, 0.2)
	await tween.finished
	life_point.scale = Vector2.ONE
	life_point.modulate = Color.WHITE


func _update_life_points() -> void:
	for index in life_points.size():
		life_points[index].visible = index < maximum
		life_points[index].texture = FULL_TEXTURE if index < remaining else EMPTY_TEXTURE
