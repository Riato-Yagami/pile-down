class_name HighlightButton
extends Button

@export var highlight_material: ShaderMaterial


func _ready() -> void:
	material = null
	mouse_entered.connect(_show_highlight)
	mouse_exited.connect(_hide_highlight)


func _show_highlight() -> void:
	material = highlight_material


func _hide_highlight() -> void:
	material = null
