class_name MemoryPile3D
extends Node3D

signal pile_selected(pile)
signal pile_completed(pile)

const PIECE_SCENE := preload("res://scenes/Piece3D.tscn")

@onready var click_area: Area3D = %ClickArea
@onready var hint_label: Label3D = %HintLabel
@onready var ring_mesh: MeshInstance3D = %RingMesh
@onready var stack_back: MeshInstance3D = %StackBack
@onready var stack_middle: MeshInstance3D = %StackMiddle

var pile_index := 0
var current_value := 5
var completed := false
var pieces: Array[PlayingPiece3D] = []
var _base_scale := Vector3.ONE
var _ring_material: StandardMaterial3D


func _ready() -> void:
	click_area.input_event.connect(_on_input_event)
	stack_back.mesh = RoundedTileMesh.create(1.5, 1.5, 0.09, 0.17, 6)
	stack_middle.mesh = RoundedTileMesh.create(1.5, 1.5, 0.09, 0.17, 6)
	ring_mesh.mesh = RoundedTileMesh.create(1.72, 1.72, 0.035, 0.21, 6)
	_ring_material = ring_mesh.material_override.duplicate() as StandardMaterial3D
	ring_mesh.material_override = _ring_material


func setup(index: int, start_value: int) -> void:
	pile_index = index
	current_value = start_value
	completed = false
	hint_label.text = ""
	var piece := PIECE_SCENE.instantiate() as PlayingPiece3D
	add_child(piece)
	piece.position = _piece_position(0)
	piece.setup(start_value, false)
	pieces.append(piece)
	scale = Vector3.ONE * 0.85
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(index * 0.055)
	tween.tween_property(self, "scale", Vector3.ONE, 0.28)


func expected_value() -> int:
	return current_value - 1


func can_accept(value: int) -> bool:
	return not completed and value == expected_value()


func set_drop_highlight(active: bool, compatible: bool = false) -> void:
	if completed:
		return
	var target_scale := Vector3.ONE * 1.04 if active else Vector3.ONE
	create_tween().tween_property(self, "scale", target_scale, 0.1)
	if not active:
		_ring_material.emission = Color("#9da4aa")
		_ring_material.emission_energy_multiplier = 0.08
	elif compatible:
		_ring_material.emission = Color("#4D82C2")
		_ring_material.emission_energy_multiplier = 1.2
	else:
		_ring_material.emission = Color("#E06455")
		_ring_material.emission_energy_multiplier = 0.28


func play_reject_effect() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "position:y", -0.08, 0.08)
	tween.tween_property(self, "position:y", 0.0, 0.12)


func hide_start_piece() -> void:
	if not pieces.is_empty():
		await pieces[0].flip_down()


func place_piece(piece: PlayingPiece3D) -> void:
	piece.set_interactive(false)
	piece.reparent(self, true)
	var target := to_global(_piece_position(pieces.size()))
	await piece.move_to(target)
	current_value = piece.piece_value
	pieces.append(piece)
	var impact := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	impact.tween_property(piece, "scale", Vector3.ONE * 0.94, 0.08)
	impact.tween_property(piece, "scale", Vector3.ONE, 0.08)
	await impact.finished
	await get_tree().create_timer(0.5).timeout
	await piece.flip_down()


func reveal_expected_briefly() -> void:
	hint_label.text = "EXPECTED: %d" % expected_value()
	hint_label.modulate = Color("#ef6b62")
	var origin := position.x
	var tween := create_tween()
	for offset in [-0.16, 0.16, -0.1, 0.1, 0.0]:
		tween.tween_property(self, "position:x", origin + offset, 0.055)
	await get_tree().create_timer(0.55).timeout
	if not completed:
		hint_label.text = "PILE %d" % (pile_index + 1)
		hint_label.modulate = Color("#d0b27d")


func complete_animation() -> void:
	completed = true
	click_area.input_ray_pickable = false
	hint_label.text = ""
	hint_label.modulate = Color("#56d6ca")
	for piece in pieces:
		piece.flip_up()
		await get_tree().create_timer(0.05).timeout
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3(1.12, 1.12, 1.12), 0.2)
	tween.tween_property(self, "scale", Vector3.ONE, 0.18)
	tween.tween_interval(0.55)
	# Une échelle strictement nulle produit une base singulière pour Jolt.
	tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.3)
	await tween.finished
	visible = false
	pile_completed.emit(self)


func _piece_position(level: int) -> Vector3:
	return Vector3(0.0, 0.18 + level * 0.115, 0.0)


func _on_input_event(
	_camera: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pile_selected.emit(self)
