class_name LavaZone
extends Area2D

const LAVA_FILL := Color(0.914, 0.42, 0.353, 0.28)
const LAVA_BORDER := Color(0.851, 0.306, 0.247, 0.75)
const ANCHOR_COUNT := 7
const CURVE_STEPS := 5

signal card_entered_lava(card: PlayingCard)

var enabled := true
var circular := false
var pulse := 0.0
var shape_seed := 1:
	set(value):
		shape_seed = value
		_build_shape()
var zone_size := Vector2(48, 20):
	set(value):
		zone_size = value
		_build_shape()
var _base_anchors := PackedVector2Array()
var _base_contour := PackedVector2Array()
var _boundary_mode := false
var _boundary_size := Vector2.ZERO
var _protected_rect := Rect2()
var _protrusion_y := -1.0
var _protrusion_on_left := false

@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D


func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 1 << 3
	area_entered.connect(_on_area_entered)
	_build_shape()
	modulate.a = 0.0
	scale = Vector2.ONE if _boundary_mode else Vector2(0.8, 0.8)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	if not _boundary_mode:
		tween.tween_property(self, "scale", Vector2.ONE, 0.25)
	queue_redraw()


func _process(delta: float) -> void:
	pulse = fmod(pulse + delta * 1.8, TAU)
	queue_redraw()


func _draw() -> void:
	var border := LAVA_BORDER
	border.a *= 0.82 + sin(pulse) * 0.18
	var animated_anchors := PackedVector2Array()
	for index in _base_anchors.size():
		var point := _base_anchors[index]
		if _boundary_mode:
			point.y += sin(pulse + float(index) * 1.37) * 1.8
			animated_anchors.append(point)
		else:
			var deformation := 1.0 + sin(pulse + float(index) * 1.37) * 0.035
			animated_anchors.append(point * deformation)
	var animated_contour := (
		_create_boundary_contour(animated_anchors)
		if _boundary_mode
		else _create_bezier_contour(animated_anchors)
	)
	if animated_contour.size() < 3:
		return
	if _boundary_mode:
		var animated_boundary := _create_open_bezier_contour(animated_anchors)
		var top_y := -12.0
		for index in animated_boundary.size() - 1:
			var start := animated_boundary[index]
			var end := animated_boundary[index + 1]
			draw_colored_polygon(
				PackedVector2Array([
					start,
					end,
					Vector2(end.x, top_y),
					Vector2(start.x, top_y),
				]),
				LAVA_FILL
			)
		draw_polyline(animated_boundary, border, 2.0, true)
		return
	draw_colored_polygon(animated_contour, LAVA_FILL)
	var closed_contour := animated_contour.duplicate()
	closed_contour.append(animated_contour[0])
	draw_polyline(closed_contour, border, 2.0, true)


func contains_global_point(point: Vector2) -> bool:
	if not enabled:
		return false
	var local_point := get_global_transform().affine_inverse() * point
	if _boundary_mode:
		return _point_is_above_boundary(local_point)
	return Geometry2D.is_point_in_polygon(local_point, _base_contour)


func disable_and_fade() -> void:
	enabled = false
	monitoring = false
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.18)
	await tween.finished
	queue_free()


func configure_boundary(
	area_size: Vector2,
	protected_rect: Rect2,
	protrusion_y: float,
	seed: int
) -> void:
	_boundary_mode = true
	_boundary_size = area_size
	_protected_rect = protected_rect
	_protrusion_y = protrusion_y
	_protrusion_on_left = seed % 2 == 0
	shape_seed = seed


func _build_shape() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = shape_seed
	_base_anchors.clear()
	if _boundary_mode:
		var width := _boundary_size.x
		var height := _boundary_size.y
		var safe_margin := 12.0
		var safe_left := _protected_rect.position.x - safe_margin
		var safe_right := _protected_rect.end.x + safe_margin
		var safe_top := _protected_rect.position.y - safe_margin
		var example_anchors := PackedVector2Array([
			Vector2(-12.0, height * 0.75),
			Vector2(safe_left - 48.0, height * 0.64),
			Vector2(safe_left - 33.0, safe_top + 30.0),
		])
		var example_waves: Array[float] = [4.0, 28.0, 42.0, 24.0, 12.0, 31.0, 18.0]
		for index in example_waves.size():
			var ratio := float(index) / 6.0
			example_anchors.append(Vector2(
				lerpf(safe_left, safe_right, ratio),
				safe_top - 8.0 - example_waves[index]
			))
		if _protrusion_y > 0.0:
			example_anchors.append(Vector2(safe_right + 4.0, safe_top + 3.0))
			example_anchors.append(Vector2(safe_right + 14.0, _protrusion_y))
			example_anchors.append(Vector2(safe_right + 26.0, safe_top + 5.0))
		example_anchors.append(Vector2(safe_right + 33.0, safe_top + 30.0))
		example_anchors.append(Vector2(safe_right + 48.0, height * 0.64))
		example_anchors.append(Vector2(width + 12.0, height * 0.78))
		if _protrusion_on_left:
			for index in range(example_anchors.size() - 1, -1, -1):
				var point := example_anchors[index]
				_base_anchors.append(Vector2(width - point.x, point.y))
		else:
			_base_anchors = example_anchors
		_base_contour = _create_boundary_contour(_base_anchors)
		_apply_collision_contour()
		return
	var half_size := zone_size * 0.5
	for index in ANCHOR_COUNT:
		var angle := TAU * float(index) / ANCHOR_COUNT
		var irregularity := (
			random.randf_range(0.6, 0.78)
			if random.randf() < 0.35
			else random.randf_range(0.92, 1.1)
		)
		_base_anchors.append(
			Vector2(cos(angle), sin(angle)) * half_size * irregularity
		)
	_base_contour = _create_bezier_contour(_base_anchors)
	_apply_collision_contour()


func _apply_collision_contour() -> void:
	if is_node_ready():
		if _boundary_mode:
			_build_boundary_collisions()
			queue_redraw()
			return
		# BUILD_SOLIDS decomposes the curved outline into convex collision pieces,
		# preserving the concave bays instead of filling them with a convex hull.
		collision_polygon.build_mode = CollisionPolygon2D.BUILD_SOLIDS
		collision_polygon.polygon = _base_contour
		queue_redraw()


func _build_boundary_collisions() -> void:
	for child in get_children():
		if child is CollisionPolygon2D and child != collision_polygon:
			child.queue_free()
	var boundary := _create_open_bezier_contour(_base_anchors)
	var top_y := -12.0
	for index in boundary.size() - 1:
		var polygon_node := collision_polygon
		if index > 0:
			polygon_node = CollisionPolygon2D.new()
			add_child(polygon_node)
		polygon_node.build_mode = CollisionPolygon2D.BUILD_SOLIDS
		var start := boundary[index]
		var end := boundary[index + 1]
		polygon_node.polygon = PackedVector2Array([
			start,
			end,
			Vector2(end.x, top_y),
			Vector2(start.x, top_y),
		])


func _point_is_above_boundary(point: Vector2) -> bool:
	var boundary := _create_open_bezier_contour(_base_anchors)
	if boundary.size() < 2:
		return false
	for index in boundary.size() - 1:
		var start := boundary[index]
		var end := boundary[index + 1]
		if point.x < start.x or point.x > end.x:
			continue
		var ratio := inverse_lerp(start.x, end.x, point.x)
		return point.y <= lerpf(start.y, end.y, ratio)
	return point.y <= -12.0


func _create_boundary_contour(anchors: PackedVector2Array) -> PackedVector2Array:
	var contour := _create_open_bezier_contour(anchors)
	var margin := 12.0
	contour.append(Vector2(_boundary_size.x + margin, -margin))
	contour.append(Vector2(-margin, -margin))
	return contour


func _create_open_bezier_contour(anchors: PackedVector2Array) -> PackedVector2Array:
	var contour := PackedVector2Array()
	if anchors.size() < 2:
		return contour
	for index in anchors.size() - 1:
		var previous := anchors[maxi(index - 1, 0)]
		var start := anchors[index]
		var end := anchors[index + 1]
		var following := anchors[mini(index + 2, anchors.size() - 1)]
		var start_handle := start + (end - previous) * 0.18
		var end_handle := end - (following - start) * 0.18
		# The arena boundary must remain x-monotonic. Pen handles may shape Y,
		# but cannot loop behind their segment and create a self-intersection.
		var minimum_x := minf(start.x, end.x)
		var maximum_x := maxf(start.x, end.x)
		start_handle.x = clampf(start_handle.x, minimum_x, maximum_x)
		end_handle.x = clampf(end_handle.x, minimum_x, maximum_x)
		for step in CURVE_STEPS:
			var weight := float(step) / CURVE_STEPS
			contour.append(
				start.bezier_interpolate(start_handle, end_handle, end, weight)
			)
	contour.append(anchors[anchors.size() - 1])
	return contour


func _create_bezier_contour(anchors: PackedVector2Array) -> PackedVector2Array:
	var contour := PackedVector2Array()
	if anchors.size() < 3:
		return contour
	for index in anchors.size():
		var previous := anchors[(index - 1 + anchors.size()) % anchors.size()]
		var start := anchors[index]
		var end := anchors[(index + 1) % anchors.size()]
		var following := anchors[(index + 2) % anchors.size()]
		# The neighboring anchors define paired handles like a smooth pen-tool node.
		var start_handle := start + (end - previous) * 0.18
		var end_handle := end - (following - start) * 0.18
		for step in CURVE_STEPS:
			var weight := float(step) / CURVE_STEPS
			contour.append(
				start.bezier_interpolate(
					start_handle,
					end_handle,
					end,
					weight
				)
			)
	return contour


func _on_area_entered(area: Area2D) -> void:
	if not enabled:
		return
	var card := area.get_parent() as PlayingCard
	if card == null or not card.dragging:
		return
	card_entered_lava.emit(card)
