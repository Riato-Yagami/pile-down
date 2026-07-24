class_name RoundedTileMesh
extends RefCounted


static func create(width: float, depth: float, height: float, radius: float, corner_segments := 5) -> ArrayMesh:
	var perimeter := _perimeter(width, depth, radius, corner_segments)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var half_height := height * 0.5

	# Face supérieure.
	vertices.append(Vector3(0, half_height, 0))
	normals.append(Vector3.UP)
	for point in perimeter:
		vertices.append(Vector3(point.x, half_height, point.y))
		normals.append(Vector3.UP)
	for index in perimeter.size():
		indices.append(0)
		indices.append(index + 1)
		indices.append((index + 1) % perimeter.size() + 1)

	# Face inférieure.
	var bottom_center := vertices.size()
	vertices.append(Vector3(0, -half_height, 0))
	normals.append(Vector3.DOWN)
	var bottom_start := vertices.size()
	for point in perimeter:
		vertices.append(Vector3(point.x, -half_height, point.y))
		normals.append(Vector3.DOWN)
	for index in perimeter.size():
		indices.append(bottom_center)
		indices.append(bottom_start + (index + 1) % perimeter.size())
		indices.append(bottom_start + index)

	# Tranche extérieure.
	for index in perimeter.size():
		var next := (index + 1) % perimeter.size()
		var a := perimeter[index]
		var b := perimeter[next]
		var normal := Vector3(a.x + b.x, 0, a.y + b.y).normalized()
		var start := vertices.size()
		vertices.append(Vector3(a.x, half_height, a.y))
		vertices.append(Vector3(b.x, half_height, b.y))
		vertices.append(Vector3(b.x, -half_height, b.y))
		vertices.append(Vector3(a.x, -half_height, a.y))
		for vertex in 4:
			normals.append(normal)
		indices.append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 3]))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _perimeter(width: float, depth: float, radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var half_width := width * 0.5
	var half_depth := depth * 0.5
	var centers := [
		Vector2(half_width - radius, half_depth - radius),
		Vector2(-half_width + radius, half_depth - radius),
		Vector2(-half_width + radius, -half_depth + radius),
		Vector2(half_width - radius, -half_depth + radius),
	]
	var start_angles := [0.0, PI * 0.5, PI, PI * 1.5]
	for corner in 4:
		for segment in segments + 1:
			var angle: float = start_angles[corner] + PI * 0.5 * float(segment) / segments
			points.append(centers[corner] + Vector2(cos(angle), sin(angle)) * radius)
	return points

