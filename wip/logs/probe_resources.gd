extends SceneTree
func _init() -> void:
 var scene = load("res://resources/scenes/gameplay/Card.tscn")
 var card = scene.instantiate()
 var material = card.get_node("VisualRoot/FaceSprite").material
 print("MAT ", material.resource_path, " ID ", material.resource_scene_unique_id)
 print("SHADER ", material.shader.resource_path, " ID ", material.shader.resource_scene_unique_id)
 print("OUTLINE ",card.get_node("VisualRoot/SelectionOutline").material.resource_path, " ID ",card.get_node("VisualRoot/SelectionOutline").material.resource_scene_unique_id)
 card.free()
 quit()
