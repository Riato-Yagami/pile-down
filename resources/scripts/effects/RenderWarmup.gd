class_name RenderWarmup
extends RefCounted

## Prepare first-use canvas rendering before the player starts a run.
## The viewport is never displayed and is released after its single draw.

const CARD := preload("res://resources/scenes/gameplay/Card.tscn")
const PILE := preload("res://resources/scenes/gameplay/Pile.tscn")


static func run(host: Node, gameplay: Node = null, transition_mask: CanvasItem = null) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var viewport := SubViewport.new()
	viewport.name = "RenderWarmup"
	viewport.size = Vector2i(64, 64)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var seen: Dictionary = {}
	_collect(gameplay if gameplay != null else host, viewport, seen)
	if transition_mask != null:
		_add_material(transition_mask.material as ShaderMaterial, null, transition_mask.light_mask, viewport, seen)
	for scene in [CARD, PILE]:
		var template: Node = scene.instantiate()
		_collect(template, viewport, seen)
		template.free()
	for data in BackgroundThemeRegistry.create_all():
		_add_material(data.material, null, 1, viewport, seen)
	for light in host.find_children("*", "PointLight2D", true, false):
		var copy := light.duplicate(0) as PointLight2D
		copy.position = Vector2(32, 32)
		copy.visible = true
		viewport.add_child(copy)
	host.add_child(viewport)
	await RenderingServer.frame_post_draw
	if is_instance_valid(viewport):
		viewport.queue_free()


static func _collect(node: Node, viewport: SubViewport, seen: Dictionary) -> void:
	if node is CanvasItem:
		var texture: Texture2D
		if node is TextureRect:
			texture = node.texture
		_add_material(node.material as ShaderMaterial, texture, node.light_mask, viewport, seen)
	for child in node.get_children():
		_collect(child, viewport, seen)


static func _add_material(material: ShaderMaterial, texture: Texture2D, light_mask: int, viewport: SubViewport, seen: Dictionary) -> void:
	if material == null or material.shader == null:
		return
	var key := str(material.shader.get_instance_id()) + ("_normal" if texture is CanvasTexture else "_plain")
	if seen.has(key):
		return
	var rect: Control
	if texture != null:
		var textured := TextureRect.new()
		textured.texture = texture
		textured.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect = textured
	else:
		rect = ColorRect.new()
	rect.material = material
	rect.light_mask = light_mask
	rect.position = Vector2((seen.size() % 16) * 4, (seen.size() / 16) * 4)
	rect.size = Vector2(4, 4)
	seen[key] = true
	viewport.add_child(rect)
