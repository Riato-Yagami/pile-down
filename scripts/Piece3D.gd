class_name PlayingPiece3D
extends Area3D

signal piece_selected(piece)
signal drag_started(piece)

@onready var body_mesh: MeshInstance3D = %BodyMesh
@onready var edge_mesh: MeshInstance3D = %EdgeMesh
@onready var top_label: Label3D = %TopLabel
@onready var back_label: Label3D = %BackLabel
@onready var correct_light: OmniLight3D = %CorrectLight

var piece_value := 0
var face_up := true
var selectable := true
var _material: StandardMaterial3D
var _edge_material: StandardMaterial3D
var _value_color := Color.WHITE
var _dragging := false
var _drag_target := Vector3.ZERO
var _home_position := Vector3.ZERO

const VALUE_COLORS: Array[Color] = [
	Color("#ef476f"),
	Color("#118ab2"),
	Color("#f29e4c"),
	Color("#06a77d"),
	Color("#8f5bd7"),
	Color("#e76f51"),
	Color("#277da1"),
	Color("#d4a017"),
	Color("#43aa8b"),
	Color("#c44569"),
]


func _ready() -> void:
	input_event.connect(_on_input_event)
	body_mesh.mesh = RoundedTileMesh.create(1.42, 1.42, 0.18, 0.15, 6)
	edge_mesh.mesh = RoundedTileMesh.create(1.52, 1.52, 0.12, 0.18, 6)
	_material = body_mesh.material_override.duplicate() as StandardMaterial3D
	body_mesh.material_override = _material
	_edge_material = edge_mesh.material_override.duplicate() as StandardMaterial3D
	edge_mesh.material_override = _edge_material


func setup(value: int, can_select: bool = true) -> void:
	piece_value = value
	selectable = can_select
	input_ray_pickable = can_select
	face_up = true
	rotation = Vector3.ZERO
	top_label.text = str(value)
	_value_color = VALUE_COLORS[value % VALUE_COLORS.size()]
	top_label.modulate = _value_color
	top_label.outline_modulate = Color.WHITE
	back_label.modulate = Color("#aab3bd")
	_edge_material.albedo_color = _value_color
	_edge_material.emission = _value_color
	_edge_material.emission_enabled = true
	_edge_material.emission_energy_multiplier = 0.0
	correct_light.light_color = _value_color
	correct_light.light_energy = 0.0
	set_selected_visual(false)
	_home_position = global_position


func _process(delta: float) -> void:
	if not _dragging:
		return
	var previous_x := global_position.x
	global_position = global_position.lerp(_drag_target, minf(delta * 20.0, 1.0))
	var velocity_x := (global_position.x - previous_x) / maxf(delta, 0.001)
	rotation.z = lerpf(rotation.z, clampf(-velocity_x * 0.012, -0.08, 0.08), minf(delta * 12.0, 1.0))


func set_selected_visual(selected: bool) -> void:
	if _edge_material == null:
		return
	_edge_material.emission_energy_multiplier = 0.65 if selected else 0.0
	var target_scale := Vector3(1.08, 1.08, 1.08) if selected else Vector3.ONE
	create_tween().tween_property(self, "scale", target_scale, 0.12)


func set_interactive(enabled: bool) -> void:
	selectable = enabled
	input_ray_pickable = enabled


func begin_drag() -> void:
	if not selectable:
		return
	_dragging = true
	_home_position = global_position
	_drag_target = global_position + Vector3(0.0, 0.35, 0.0)
	set_selected_visual(true)


func update_drag_target(target: Vector3) -> void:
	_drag_target = target


func finish_drag() -> void:
	_dragging = false
	rotation.z = 0.0
	set_selected_visual(false)


func return_to_hand() -> void:
	finish_drag()
	await move_to(_home_position)


func reject_and_return() -> void:
	finish_drag()
	var origin := global_position.x
	var tween := create_tween()
	for offset in [-0.12, 0.12, -0.08, 0.08, 0.0]:
		tween.tween_property(self, "global_position:x", origin + offset, 0.04)
	await tween.finished
	await move_to(_home_position)


func flip_down() -> void:
	if not face_up:
		return
	face_up = false
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation:x", PI, 0.34)
	tween.tween_callback(func() -> void:
		_edge_material.albedo_color = Color("#d6dbe0")
		_edge_material.emission_energy_multiplier = 0.0
	)
	await tween.finished


func flip_up() -> void:
	if face_up:
		return
	face_up = true
	_edge_material.albedo_color = _value_color
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation:x", 0.0, 0.34)
	await tween.finished


func play_correct_effect() -> void:
	# Le contour et une lumière ponctuelle reprennent la couleur de la valeur.
	_edge_material.emission_energy_multiplier = 2.2
	correct_light.light_energy = 3.5
	var tween := create_tween()
	tween.tween_property(correct_light, "light_energy", 0.0, 0.48)
	tween.parallel().tween_property(_edge_material, "emission_energy_multiplier", 0.0, 0.48)


func move_to(target: Vector3, target_rotation: Vector3 = Vector3.ZERO) -> void:
	var arc_height := maxf(global_position.y, target.y) + 1.1
	var midpoint := (global_position + target) * 0.5
	midpoint.y = arc_height
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", midpoint, 0.22)
	tween.parallel().tween_property(self, "global_rotation", target_rotation * 0.5, 0.22)
	tween.tween_property(self, "global_position", target, 0.24)
	tween.parallel().tween_property(self, "global_rotation", target_rotation, 0.24)
	await tween.finished


func flash_error() -> void:
	if _material == null:
		return
	var original := _material.albedo_color
	var tween := create_tween()
	tween.tween_property(_material, "albedo_color", Color("#e7645d"), 0.08)
	tween.tween_property(_material, "albedo_color", original, 0.22)


func _on_input_event(
	_camera: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if selectable and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		piece_selected.emit(self)
		begin_drag()
		drag_started.emit(self)
