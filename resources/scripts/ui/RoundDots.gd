class_name RoundDots
extends Control

const FULL_TEXTURE := preload(
	"res://resources/materials/textures/hand/life/life-point-full.tres"
)
const EMPTY_TEXTURE := preload(
	"res://resources/materials/textures/hand/life/life-point-empty.tres"
)
const REINFORCED_SHADER := preload("res://resources/shaders/ui/GoldStatus.gdshader")
const SAFETY_NET_SHADER := preload("res://resources/shaders/ui/SafetyNet.gdshader")

var remaining := 3
var maximum := 3
var reinforced_count := 0
var safety_net_active := false

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
	maximum = clampi(value, 1, 6)
	remaining = mini(remaining, maximum)
	if is_node_ready():
		_update_life_points()


func set_reinforced_count(value: int) -> void:
	reinforced_count = clampi(value, 0, 3)
	if is_node_ready():
		_update_life_points()


func set_safety_net_active(active: bool) -> void:
	safety_net_active = active
	if is_node_ready():
		_update_life_points()


func play_safety_net_break() -> void:
	if not is_node_ready():
		return
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_BACK)
	for index in mini(maximum, life_points.size()):
		var point := life_points[index]
		tween.tween_property(point, "scale", Vector2(1.3, 0.72), 0.11)
		tween.tween_property(
			point,
			"modulate",
			Color(1.35, 1.35, 1.35, 1.0),
			0.08
		)
	await tween.finished
	safety_net_active = false
	_update_life_points()
	var recovery := create_tween().set_parallel().set_trans(Tween.TRANS_BACK)
	for index in mini(maximum, life_points.size()):
		var point := life_points[index]
		recovery.tween_property(point, "scale", Vector2.ONE, 0.16)
		recovery.tween_property(point, "modulate", Color.WHITE, 0.12)
	await recovery.finished


func play_damage(remaining_after_hit: int) -> void:
	if not is_node_ready():
		return
	var reinforced_hit := maximum > 3 and remaining_after_hit >= 3
	var damaged_index := 0
	if reinforced_hit:
		var reinforced_after_hit := maxi(remaining_after_hit - 3, 0)
		damaged_index = (
			mini(maximum, life_points.size())
			- reinforced_after_hit
			- 1
		)
	else:
		damaged_index = remaining_after_hit
	damaged_index = clampi(damaged_index, 0, life_points.size() - 1)
	var life_point := life_points[damaged_index]
	life_point.texture = FULL_TEXTURE
	life_point.visible = true
	life_point.pivot_offset = life_point.size * 0.5
	life_point.modulate = Color.WHITE
	life_point.scale = Vector2.ONE
	if reinforced_hit:
		var reinforcement_tween := (
			create_tween()
			.set_trans(Tween.TRANS_BACK)
			.set_ease(Tween.EASE_OUT)
		)
		reinforcement_tween.tween_property(
			life_point,
			"scale",
			Vector2(1.28, 0.82),
			0.12
		)
		reinforcement_tween.tween_callback(
			func() -> void:
				life_point.material = null
		)
		reinforcement_tween.tween_property(
			life_point,
			"scale",
			Vector2.ONE,
			0.18
		)
		await reinforcement_tween.finished
		return
	life_point.material = null
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
	var visible_maximum := mini(maximum, life_points.size())
	var visible_remaining := mini(remaining, life_points.size())
	var reinforced_remaining := mini(maxi(remaining - 3, 0), reinforced_count)
	for index in life_points.size():
		var point := life_points[index]
		point.visible = index < visible_maximum
		point.texture = FULL_TEXTURE if index < visible_remaining else EMPTY_TEXTURE
		point.modulate = Color.WHITE
		if safety_net_active:
			var safety_material := ShaderMaterial.new()
			var safety_shader: Shader = SAFETY_NET_SHADER
			safety_material.shader = safety_shader
			point.material = safety_material
		elif reinforced_remaining > 0 and index >= visible_maximum - reinforced_remaining:
			var reinforced_material := ShaderMaterial.new()
			var shader: Shader = REINFORCED_SHADER
			reinforced_material.shader = shader
			point.material = reinforced_material
		else:
			point.material = null
