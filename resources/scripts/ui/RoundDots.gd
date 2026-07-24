class_name RoundDots
extends Control

const FULL_TEXTURE := preload("res://resources/sprites/hand/life/life-point-full.png")
const EMPTY_TEXTURE := preload("res://resources/sprites/hand/life/life-point-empty.png")

var remaining := 3

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
	remaining = clampi(value, 0, 3)
	if is_node_ready():
		_update_life_points()


func _update_life_points() -> void:
	for index in life_points.size():
		life_points[index].texture = FULL_TEXTURE if index < remaining else EMPTY_TEXTURE
