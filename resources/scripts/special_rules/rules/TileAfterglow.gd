extends Node2D

const GLOW_SHADER := preload("res://resources/shaders/ui/TileAfterglow.gdshader")
const DURATION := 1.35

var _sources: Array[Control] = []
var _copies: Array[Control] = []
var _frames: Array[Node2D] = []
var _elapsed := 0.0


func setup(face: TextureRect, back: TextureRect, label: Label) -> void:
	_sources.assign([face, back, label])
	for source in _sources:
		var frame := Node2D.new()
		add_child(frame)
		_frames.append(frame)
		var copy: Control
		if source is TextureRect:
			var sprite := TextureRect.new()
			sprite.texture = source.texture
			sprite.texture_filter = source.texture_filter
			var glow_material := ShaderMaterial.new()
			glow_material.shader = GLOW_SHADER
			sprite.material = glow_material
			copy = sprite
		else:
			copy = source.duplicate() as Label
			copy.material = null
			copy.add_theme_color_override("font_color", GameColors.AFTERGLOW_TEXT)
			copy.add_theme_constant_override("outline_size", 0)
			copy.add_theme_color_override("font_shadow_color", GameColors.TRANSPARENT)
		frame.add_child(copy)
		copy.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_copies.append(copy)
	_process(0.0)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= DURATION or not is_visible_in_tree():
		queue_free()
		return
	var glow := pow(1.0 - _elapsed / DURATION, 1.6)
	for index in _sources.size():
		var source := _sources[index]
		if not is_instance_valid(source) or source.is_queued_for_deletion():
			queue_free()
			return
		var copy := _copies[index]
		copy.visible = source.is_visible_in_tree()
		copy.size = source.size
		copy.scale = Vector2.ONE
		copy.rotation = 0.0
		copy.position = Vector2.ZERO
		_frames[index].transform = get_global_transform_with_canvas().affine_inverse() * source.get_global_transform_with_canvas()
		var opacity := source.self_modulate.a
		var ancestor: Node = source
		while ancestor is CanvasItem:
			opacity *= (ancestor as CanvasItem).modulate.a
			ancestor = ancestor.get_parent()
		copy.modulate = Color(GameColors.WHITE, opacity)
		copy.self_modulate = GameColors.WHITE
		if source is TextureRect:
			var glow_material := copy.material as ShaderMaterial
			glow_material.set_shader_parameter("phosphorescence", glow)
			if source.material is ShaderMaterial:
				glow_material.set_shader_parameter("tile_color", source.material.get_shader_parameter("tile_color"))
		else:
			# Follow current visibility/text so a flipped tile never leaks its value.
			(copy as Label).text = (source as Label).text
			copy.modulate.a *= glow * 0.85
