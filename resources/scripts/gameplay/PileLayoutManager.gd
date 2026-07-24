class_name PileLayoutManager
extends RefCounted

const SPACING_X := 1.9
const SPACING_Z := 1.75


static func positions_for(count: int) -> Array[Vector3]:
	var rows := _rows_for(count)
	var result: Array[Vector3] = []
	var row_count := rows.size()
	for row_index in row_count:
		var columns: int = rows[row_index]
		var z := (row_index - (row_count - 1) * 0.5) * SPACING_Z
		for column in columns:
			var x := (column - (columns - 1) * 0.5) * SPACING_X
			result.append(Vector3(x, 0.0, z - 0.55))
	return result


static func positions_for_2d(count: int, piece_size: float, gap: float = 22.0) -> Array[Vector2]:
	var rows := _rows_for(count)
	var result: Array[Vector2] = []
	var step := piece_size + gap
	for row_index in rows.size():
		var columns: int = rows[row_index]
		var y := (row_index - (rows.size() - 1) * 0.5) * step
		for column in columns:
			var x := (column - (columns - 1) * 0.5) * step
			result.append(Vector2(x, y))
	return result


static func _rows_for(count: int) -> Array[int]:
	match count:
		1: return [1]
		2: return [2]
		3: return [1, 2]
		4: return [2, 2]
		5: return [2, 3]
		6: return [3, 3]
		7: return [3, 4]
		8: return [4, 4]
		9: return [3, 3, 3]

	var columns := ceili(sqrt(float(count)))
	var rows := ceili(float(count) / columns)
	var layout: Array[int] = []
	var remaining := count
	for row in rows:
		var rows_left := rows - row
		var row_size := mini(columns, ceili(float(remaining) / rows_left))
		layout.append(row_size)
		remaining -= row_size
	return layout
