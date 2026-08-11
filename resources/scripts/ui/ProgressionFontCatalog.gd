@tool
class_name ProgressionFontCatalog
extends Node

signal editor_preview_changed()

## Polices proposées par le menu et utilisées sur les cartes et les piles.
@export var available_fonts: Array[FontData] = FontRegistry.create_all()
@export var available_palettes: Array[ColorPaletteData] = ColorPaletteRegistry.create_all()
@export_category("Defaults")
@export var default_font: FontData
@export var default_palette: ColorPaletteData
@export_category("Editor Preview")
@export var editor_preview_enabled := true:
	set(value):
		editor_preview_enabled = value
		editor_preview_changed.emit()
@export_enum("Highscores", "Achievements", "Bonuses", "Special Rules", "Fonts")
var editor_preview_page := 0:
	set(value):
		editor_preview_page = clampi(value, 0, 4)
		editor_preview_changed.emit()
@export_range(1, 10, 1) var editor_preview_tile_count := 9:
	set(value):
		editor_preview_tile_count = clampi(value, 1, 10)
		editor_preview_changed.emit()
@export var editor_preview_font: FontData:
	set(value):
		_disconnect_preview_resource(editor_preview_font)
		editor_preview_font = value
		_connect_preview_resource(editor_preview_font)
		editor_preview_changed.emit()
@export var editor_preview_palette: ColorPaletteData:
	set(value):
		_disconnect_preview_resource(editor_preview_palette)
		editor_preview_palette = value
		_connect_preview_resource(editor_preview_palette)
		editor_preview_changed.emit()
@export_tool_button("Reload Editor Preview", "Reload")
var reload_editor_preview_action: Callable = _reload_editor_preview


func _reload_editor_preview() -> void:
	editor_preview_changed.emit()


func _connect_preview_resource(resource: Resource) -> void:
	if resource != null and not resource.changed.is_connected(_on_preview_resource_changed):
		resource.changed.connect(_on_preview_resource_changed)


func _disconnect_preview_resource(resource: Resource) -> void:
	if resource != null and resource.changed.is_connected(_on_preview_resource_changed):
		resource.changed.disconnect(_on_preview_resource_changed)


func _on_preview_resource_changed() -> void:
	editor_preview_changed.emit()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if default_font == null:
		warnings.append("Default Font must be assigned.")
	elif not available_fonts.has(default_font):
		warnings.append("Default Font must be present in Available Fonts.")
	if default_palette == null:
		warnings.append("Default Palette must be assigned.")
	elif not available_palettes.has(default_palette):
		warnings.append("Default Palette must be present in Available Palettes.")
	for palette in available_palettes:
		if palette == null:
			warnings.append("Available Palettes contains an empty entry.")
		elif palette.colors.size() != 10:
			warnings.append(
				"Palette '%s' must contain exactly 10 colors (values 0 to 9)."
				% palette.display_name
			)
	return warnings
