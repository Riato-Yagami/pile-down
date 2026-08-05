class_name TextureHighlightButton
extends TextureButton

@export var highlight_material: ShaderMaterial

const ButtonInteractionScript := preload(
	"res://resources/scripts/ui/ButtonInteraction.gd"
)

var _interaction = ButtonInteractionScript.new()


func _ready() -> void:
	_interaction.setup(self, highlight_material)


func _gui_input(event: InputEvent) -> void:
	_interaction.handle_gui_input(event)


func set_pointer_hovered(hovered: bool) -> void:
	if hovered:
		_interaction.show_highlight()
	else:
		_interaction.hide_highlight()
