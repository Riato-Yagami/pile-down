extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var effect := BackgroundEffects.new()
	root.add_child(effect)
	effect.position = Vector2(10, 20)
	effect._shader_material = ShaderMaterial.new()
	effect._shader_material.shader = BackgroundEffects.BACKGROUND_SHADER
	var tile := Control.new()
	root.add_child(tile)
	tile.position = Vector2(40, 60)
	tile.size = Vector2(20, 40)
	var tiles: Array[Control] = [tile]
	effect.set_tile_weights(tiles)
	var initial: PackedVector4Array = effect._shader_material.get_shader_parameter("tile_weights")
	assert(initial.size() == 16)
	assert(initial[0].is_equal_approx(Vector4(40, 60, 30, 2)))
	for index in 3:
		effect.set_tile_weights(tiles)
		assert(effect._shader_material.get_shader_parameter("tile_weights") == initial)
	tile.position += Vector2(5, 10)
	effect.set_tile_weights(tiles, tile, {tile.get_instance_id(): 0.5})
	var dragged: PackedVector4Array = effect._shader_material.get_shader_parameter("tile_weights")
	assert(dragged[0].is_equal_approx(Vector4(45, 70, 30, 1.8)))
	effect.position += Vector2(5, 10)
	tile.size = Vector2(60, 80)
	effect.tile_weight_strength = 3
	effect.set_tile_weights(tiles)
	var resized: PackedVector4Array = effect._shader_material.get_shader_parameter("tile_weights")
	assert(resized[0].is_equal_approx(Vector4(60, 80, 57.6, 3)))
	var shapes: PackedVector4Array = effect._shader_material.get_shader_parameter("tile_weight_shapes")
	assert(shapes[0] == Vector4(30, 40, 5, 0))
	tile.hide()
	effect.set_tile_weights(tiles)
	_assert_empty(effect)
	tile.show()
	for index in 20:
		tiles.append(tile)
	effect.set_tile_weights(tiles)
	var capped: PackedVector4Array = effect._shader_material.get_shader_parameter("tile_weights")
	assert(capped.size() == 16 and capped[15].w == 3)
	effect.set_tile_weights([tile])
	var shortened: PackedVector4Array = effect._shader_material.get_shader_parameter("tile_weights")
	assert(shortened[0].w == 3)
	for index in range(1, 16):
		assert(shortened[index] == Vector4.ZERO)
	tile.free()
	effect.set_tile_weights(tiles)
	_assert_empty(effect)
	effect.free()
	print("Tile weight update tests passed.")
	quit()


func _assert_empty(effect: BackgroundEffects) -> void:
	for parameter in ["tile_weights", "tile_weight_shapes"]:
		var values: PackedVector4Array = effect._shader_material.get_shader_parameter(parameter)
		for value in values:
			assert(value == Vector4.ZERO)
