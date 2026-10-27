extends SceneTree

const PileScene := preload("res://resources/scenes/gameplay/Pile.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Control.new()
	root.add_child(stage)
	var piles: Array[MemoryPile] = []
	for index in 25:
		var pile := PileScene.instantiate() as MemoryPile
		stage.add_child(pile)
		pile.setup(index, 5)
		pile.current_value = 3
		piles.append(pile)
	var three: Array[MemoryPile] = [piles[0], piles[1], piles[2]]
	var layout := PileLayoutManager.positions_for_2d(3, 34)
	for index in 3:
		three[index].position = layout[index]
	assert(ResultShare._spatial_board(three) == ResultShare.HALF_SPACE + "3️⃣\n3️⃣3️⃣", "Keep the centered triangle")
	var four: Array[MemoryPile] = [piles[0], piles[1], piles[2], piles[3]]
	for index in 4:
		four[index].position = Vector2((index % 2) * 44, (index / 2) * 44)
	assert(ResultShare._spatial_board(four) == "3️⃣3️⃣\n3️⃣3️⃣")
	# A bent snake retains its empty cells and its bend.
	four[0].position = Vector2(0, 0)
	four[1].position = Vector2(44, 0)
	four[2].position = Vector2(44, 44)
	four[3].position = Vector2(88, 44)
	four[0].current_value = 1
	four[3].completed = true
	assert(ResultShare._spatial_board(four) == "1️⃣3️⃣\n" + ResultShare.EMPTY_TILE + "3️⃣" + ResultShare.EMPTY_TILE)
	stage.scale = Vector2(-1, 1)
	assert(ResultShare._spatial_board(four) == ResultShare.EMPTY_TILE + "3️⃣1️⃣\n" + ResultShare.EMPTY_TILE + "3️⃣")
	stage.scale = Vector2.ONE
	# A gap between distant moved piles survives as an empty row/column.
	var two: Array[MemoryPile] = [piles[0], piles[1]]
	two[0].position = Vector2.ZERO
	two[1].position = Vector2(180, 180)
	var separated := ResultShare._spatial_board(two)
	assert(separated.contains(ResultShare.EMPTY_TILE) and separated.split("\n").size() >= 3)
	assert(not separated.contains("⬜") and not separated.contains("✅"))
	# Dense or scattered moving boards never lose piles while quantizing.
	for dense in [true, false]:
		for index in piles.size():
			piles[index].completed = false
			piles[index].current_value = 3
			piles[index].position = Vector2(index % 5, index / 5) * (0.2 if dense else 250.0)
		var grid := ResultShare._spatial_board(piles)
		assert(grid.count("3️⃣") == 25, "Quantization must keep every pile")
		assert(grid.split("\n").size() <= ResultShare.MAX_BOARD_ROWS)
	# A rotating twelve-pile ring plus its central pile remains symmetric.
	var circle: Array[MemoryPile] = []
	for index in 13:
		circle.append(piles[index])
	for phase in [0.1, 0.25, 0.4]:
		for index in 12:
			circle[index].position = Vector2(cos(index * TAU / 12 + phase), sin(index * TAU / 12 + phase)) * 90
		circle[12].position = Vector2.ZERO
		var grid := ResultShare._spatial_board(circle)
		assert(grid.count("3️⃣") == 13)
		var rows := grid.replace("3️⃣", "##").replace(ResultShare.HALF_SPACE, ".").split("\n")
		for row in rows:
			assert(row.contains("#"), "A regular 12-pile ring should have no empty text rows")
		var width := 0
		for row in rows:
			width = maxi(width, row.length())
		for index in rows.size():
			var row := rows[index].rpad(width, ".")
			assert(row == row.reverse(), "Ring rows must be horizontally symmetric")
			assert(row == rows[rows.size() - 1 - index].rpad(width, "."), "Ring top and bottom must match")
	# A 24-pile ring needs eleven text rows to avoid an asymmetric fallback.
	for index in 24:
		piles[index].position = Vector2(cos(index * TAU / 24 + 0.1), sin(index * TAU / 24 + 0.1)) * 180
	piles[24].position = Vector2.ZERO
	var large_circle := ResultShare._spatial_board(piles)
	var large_points: Array[Vector2] = []
	for pile in piles:
		large_points.append(ResultShare._layout_center(pile))
	assert(not ResultShare._circular_cells(large_points).is_empty())
	assert(large_circle.count("3️⃣") == 25)
	assert(large_circle.split("\n").size() == 11)
	# Small wave offsets must not split one logical row or create blank rows.
	var waved: Array[MemoryPile] = []
	var wave_points := [Vector2(94, 82.6), Vector2(138, 74.9), Vector2(182, 84.3), Vector2(226, 75.6), Vector2(116, 121.7), Vector2(160, 125.1), Vector2(204, 126.3), Vector2(116, 165.7), Vector2(160, 169.1), Vector2(204, 170.3), Vector2(116, 209.7), Vector2(160, 213.1), Vector2(204, 214.3)]
	for index in wave_points.size():
		piles[index].position = wave_points[index]
		waved.append(piles[index])
	assert(ResultShare._spatial_board(waved).split("\n").size() == 4)
	stage.queue_free()
	await process_frame
	print("Spatial share grid passed: triangle, regular grid, bent snake, mirror, gaps and 25 crowded/scattered piles.")
	quit()
