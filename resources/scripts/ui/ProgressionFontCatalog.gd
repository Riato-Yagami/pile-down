@tool
class_name ProgressionFontCatalog
extends Node

signal editor_preview_changed()

## Catalogues used by the menu and the in-editor preview.
@export var font_data_catalog: SelectableDataCatalog = FontRegistry.CATALOG:
	set(value):
		_disconnect_catalog(font_data_catalog)
		font_data_catalog = value
		_connect_catalog(font_data_catalog)
		editor_preview_changed.emit()
@export var palette_data_catalog: SelectableDataCatalog = ColorPaletteRegistry.CATALOG:
	set(value):
		_disconnect_catalog(palette_data_catalog)
		palette_data_catalog = value
		_connect_catalog(palette_data_catalog)
		editor_preview_changed.emit()
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
@export_tool_button("Reload Editor Preview", "Reload")
var reload_editor_preview_action: Callable = _reload_editor_preview

var available_fonts: Array[FontData]:
	get:
		return get_available_fonts()
	set(_value):
		push_warning("Available Fonts is deprecated. Edit Font Data Catalog instead.")
var available_palettes: Array[ColorPaletteData]:
	get:
		return get_available_palettes()
	set(_value):
		push_warning("Available Palettes is deprecated. Edit Palette Data Catalog instead.")
var editor_preview_font: FontData:
	get:
		return get_editor_preview_font()
	set(value):
		if font_data_catalog != null:
			font_data_catalog.selected_data = value
		editor_preview_changed.emit()
var editor_preview_palette: ColorPaletteData:
	get:
		return get_editor_preview_palette()
	set(value):
		if palette_data_catalog != null:
			palette_data_catalog.selected_data = value
		editor_preview_changed.emit()


func _ready() -> void:
	_connect_catalog(font_data_catalog)
	_connect_catalog(palette_data_catalog)


func get_available_fonts() -> Array[FontData]:
	var result: Array[FontData] = []
	if font_data_catalog == null:
		return result
	for entry in font_data_catalog.enabled_data:
		var data := entry as FontData
		if data == null:
			push_warning("Ignoring non-FontData entry in font data catalog.")
			continue
		result.append(data)
	ProgressionOrdering.sort_unlockables(result)
	return result


func get_available_palettes() -> Array[ColorPaletteData]:
	var result: Array[ColorPaletteData] = []
	if palette_data_catalog == null:
		return result
	for entry in palette_data_catalog.enabled_data:
		var data := entry as ColorPaletteData
		if data == null:
			push_warning("Ignoring non-ColorPaletteData entry in palette data catalog.")
			continue
		result.append(data)
	ProgressionOrdering.sort_unlockables(result)
	return result


func get_editor_preview_font() -> FontData:
	if font_data_catalog == null:
		return null
	return font_data_catalog.get_selected_data() as FontData


func get_editor_preview_palette() -> ColorPaletteData:
	if palette_data_catalog == null:
		return null
	return palette_data_catalog.get_selected_data() as ColorPaletteData


func _reload_editor_preview() -> void:
	editor_preview_changed.emit()


func _connect_catalog(catalog: SelectableDataCatalog) -> void:
	if catalog == null:
		return
	if not catalog.changed.is_connected(_on_catalog_changed):
		catalog.changed.connect(_on_catalog_changed)
	if not catalog.editor_preview_refreshed.is_connected(_on_catalog_preview_refreshed):
		catalog.editor_preview_refreshed.connect(_on_catalog_preview_refreshed)


func _disconnect_catalog(catalog: SelectableDataCatalog) -> void:
	if catalog == null:
		return
	if catalog.changed.is_connected(_on_catalog_changed):
		catalog.changed.disconnect(_on_catalog_changed)
	if catalog.editor_preview_refreshed.is_connected(_on_catalog_preview_refreshed):
		catalog.editor_preview_refreshed.disconnect(_on_catalog_preview_refreshed)


func _on_catalog_changed() -> void:
	editor_preview_changed.emit()


func _on_catalog_preview_refreshed(_selected_data: Data) -> void:
	editor_preview_changed.emit()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	var fonts := get_available_fonts()
	var palettes := get_available_palettes()
	if font_data_catalog == null:
		warnings.append("Font Data Catalog must be assigned.")
	if palette_data_catalog == null:
		warnings.append("Palette Data Catalog must be assigned.")
	if default_font == null:
		warnings.append("Default Font must be assigned.")
	elif not fonts.has(default_font):
		warnings.append("Default Font must be present in Font Data Catalog.")
	if default_palette == null:
		warnings.append("Default Palette must be assigned.")
	elif not palettes.has(default_palette):
		warnings.append("Default Palette must be present in Palette Data Catalog.")
	for palette in palettes:
		if palette == null:
			warnings.append("Palette Data Catalog contains an empty entry.")
		elif palette.colors.size() != 10:
			warnings.append(
				"Palette '%s' must contain exactly 10 colors (values 0 to 9)."
				% palette.display_name
			)
	return warnings
