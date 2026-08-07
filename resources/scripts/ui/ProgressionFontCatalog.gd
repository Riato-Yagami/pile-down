@tool
class_name ProgressionFontCatalog
extends Node

## Polices proposées par le menu et utilisées sur les cartes et les piles.
@export var available_fonts: Array[FontData] = FontRegistry.create_all()
@export var available_palettes: Array[ColorPaletteData] = ColorPaletteRegistry.create_all()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	for palette in available_palettes:
		if palette == null:
			warnings.append("Available Palettes contains an empty entry.")
		elif palette.colors.size() != 10:
			warnings.append(
				"Palette '%s' must contain exactly 10 colors (values 0 to 9)."
				% palette.display_name
			)
	return warnings
