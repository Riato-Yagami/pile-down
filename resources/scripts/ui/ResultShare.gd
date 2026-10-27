class_name ResultShare
extends RefCounted

const MAX_BOARD_COLUMNS := 10
const MAX_BOARD_ROWS := 12
const HALF_SPACE := "\u00A0"
const EMPTY_TILE := HALF_SPACE + HALF_SPACE

const ITCH_URL := "https://juel-s.itch.io/pile-down"
const GOOGLE_PLAY_URL := "https://play.google.com/store/apps/details?id=dev.juels.piledown"


static func build_message(title: String, details: String, tiles := "") -> String:
	var sections := PackedStringArray([".Pile Down."])
	if not tiles.is_empty():
		sections.append(tiles)
	sections.append(_clean_line(title) + "\n" + _clean_line(details))
	sections.append(ITCH_URL + "\n" + GOOGLE_PLAY_URL)
	return "\n\n".join(sections)


static func _clean_line(value: String) -> String:
	return " ".join(value.replace("\n", " ").replace("\t", " ").split(" ", false))


static func capture_tiles(piles: Array[MemoryPile]) -> String:
	var ordered: Array[MemoryPile] = []
	for pile in piles:
		if is_instance_valid(pile):
			ordered.append(pile)
	return _spatial_board(ordered)


static func _spatial_board(piles: Array[MemoryPile]) -> String:
	if piles.is_empty():
		return "—"
	var points: Array[Vector2] = []
	var tile_size := Vector2.ZERO
	for pile in piles:
		points.append(_layout_center(pile))
		var parent_transform := pile.get_parent().get_global_transform() as Transform2D
		tile_size += Vector2(
			parent_transform.basis_xform(Vector2(pile.size.x, 0)).length(),
			parent_transform.basis_xform(Vector2(0, pile.size.y)).length()
		)
	tile_size /= piles.size()
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	var circular_cells := _circular_cells(points)
	var x_pitch := _axis_pitch(points, tile_size, true)
	var y_pitch := _axis_pitch(points, tile_size, false)
	# Half columns preserve staggered rows (one pile centered over two).
	# Bound the output so widely scattered boards remain usable in a post.
	var half_pitch := maxf(x_pitch * 0.5, bounds.size.x / (MAX_BOARD_COLUMNS * 2 - 2))
	y_pitch = maxf(y_pitch, bounds.size.y / (MAX_BOARD_ROWS - 1))
	var order: Array[int] = []
	for index in piles.size():
		order.append(index)
	order.sort_custom(func(a: int, b: int) -> bool:
		return points[a].x < points[b].x if is_equal_approx(points[a].y, points[b].y) else points[a].y < points[b].y
	)
	var occupied: Dictionary = {}
	var last_row := 0
	var last_column := 0
	for index in order:
		var desired := Vector2((points[index].x - bounds.position.x) / half_pitch, (points[index].y - bounds.position.y) / y_pitch)
		if not circular_cells.is_empty():
			desired = Vector2(circular_cells[index])
		var cell := Vector2i(roundi(desired.x), roundi(desired.y))
		if not _share_cell_free(occupied, cell):
			# Quantization may merge nearby moving piles. Reserve the nearest
			# free slot instead of losing a tile or drawing one over another.
			var best_distance := INF
			for y in MAX_BOARD_ROWS:
				for x in MAX_BOARD_COLUMNS * 2 - 1:
					var candidate := Vector2i(x, y)
					var distance := ((Vector2(candidate) - desired) * Vector2(half_pitch, y_pitch)).length_squared()
					if _share_cell_free(occupied, candidate) and distance < best_distance:
						cell = candidate
						best_distance = distance
		var pile := piles[index]
		occupied[cell] = EMPTY_TILE if pile.completed or pile.is_complete_value() else _number_tile(pile.current_value)
		last_row = maxi(last_row, cell.y)
		last_column = maxi(last_column, cell.x + 2)
	var rows := PackedStringArray()
	for y in last_row + 1:
		var row_end := 0
		for cell: Vector2i in occupied:
			if cell.y == y:
				row_end = maxi(row_end, cell.x + 2)
		if row_end == 0:
			rows.append(HALF_SPACE.repeat(last_column))
			continue
		var row := ""
		var x := 0
		while x < row_end:
			var cell := Vector2i(x, y)
			if occupied.has(cell):
				row += occupied[cell]
				x += 2
			elif occupied.has(cell + Vector2i.RIGHT):
				row += HALF_SPACE
				x += 1
			else:
				row += EMPTY_TILE
				x += 2
		rows.append(row)
	return "\n".join(rows)


static func _circular_cells(points: Array[Vector2]) -> Array[Vector2i]:
	var none: Array[Vector2i] = []
	if points.size() < 6:
		return none
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	var center := bounds.get_center()
	var radii: Array[float] = []
	for point in points:
		radii.append(point.distance_to(center))
	radii.sort()
	var radius := radii[radii.size() / 2]
	if radius < 1.0:
		return none
	var ring: Array[int] = []
	for index in points.size():
		var distance := points[index].distance_to(center)
		if absf(distance - radius) < radius * 0.14:
			ring.append(index)
		elif distance > radius * 0.28:
			return none
	if ring.size() < 6 or points.size() - ring.size() > 2:
		return none
	ring.sort_custom(func(a: int, b: int): return (points[a] - center).angle() < (points[b] - center).angle())
	var step := TAU / ring.size()
	for index in ring.size():
		var a := (points[ring[index]] - center).angle()
		var b := (points[ring[(index + 1) % ring.size()]] - center).angle()
		var gap := fposmod(b - a, TAU)
		if gap < step * 0.55 or gap > step * 1.45:
			return none
	# A nearly regular ring gets a symmetric text lattice, keeping angular order
	# and rounding its phase by at most a half segment. Independent row
	# rounding otherwise pushes pairs into different rows or extra collisions.
	var first_angle := (points[ring[0]] - center).angle()
	var phase := roundf((first_angle + PI * 0.5) / step - 0.5) * step + step * 0.5 - PI * 0.5
	for y_radius in range(clampi(ceili(ring.size() / 4.0), 2, 4), (MAX_BOARD_ROWS - 1) / 2 + 1):
		for x_radius in range(y_radius * 2 - 1, MAX_BOARD_COLUMNS):
			var cells: Array[Vector2i] = []
			cells.resize(points.size())
			for index in points.size():
				cells[index] = Vector2i.ZERO
			for index in ring.size():
				var angle := phase + index * step
				cells[ring[index]] = Vector2i(
					roundi(snappedf(cos(angle) * x_radius, 0.0001)),
					roundi(snappedf(sin(angle) * y_radius, 0.0001))
				)
			var occupied: Dictionary = {}
			var fits := true
			var minimum := Vector2i(100, 100)
			for cell in cells:
				if not _share_cell_free(occupied, cell):
					fits = false
					break
				occupied[cell] = true
				minimum = minimum.min(cell)
			if fits:
				for index in cells.size():
					cells[index] -= minimum
				return cells
	return none


static func _share_cell_free(occupied: Dictionary, cell: Vector2i) -> bool:
	return not occupied.has(cell) and not occupied.has(cell + Vector2i.LEFT) and not occupied.has(cell + Vector2i.RIGHT)


static func _axis_pitch(points: Array[Vector2], tile_size: Vector2, horizontal: bool) -> float:
	var extent := tile_size.x if horizontal else tile_size.y
	var cross_extent := tile_size.y if horizontal else tile_size.x
	var pitch := extent * 1.8
	for a in points:
		for b in points:
			var gap := absf(a.x - b.x) if horizontal else absf(a.y - b.y)
			var cross_gap := absf(a.y - b.y) if horizontal else absf(a.x - b.x)
			# Diagonal gaps include wave offsets and can split a single row.
			# Measure pitch only between approximately aligned neighbours.
			if gap >= extent * 0.8 and cross_gap < cross_extent * 0.4:
				pitch = minf(pitch, gap)
	return maxf(pitch, 1.0)


static func _layout_center(tile: Control) -> Vector2:
	return tile.get_parent().get_global_transform() * (tile.position + tile.size * 0.5)


static func _number_tile(value: int) -> String:
	return str(value) + "\uFE0F\u20E3" if value >= 0 and value <= 9 else "[%d]" % value
