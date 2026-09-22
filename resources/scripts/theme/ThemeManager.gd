class_name ThemeManager
extends Node

signal theme_changed(theme: ThemePaletteData)

const SELECTED_TEXT_COLOR := Color("4d82c2")

var definitions: Array[ThemePaletteData] = []
var active_theme_id: StringName = &"arcade"


func configure_from_palettes(palettes: Array[ColorPaletteData], selected_id: StringName) -> void:
	definitions = ThemePaletteRegistry.create_all(palettes)
	active_theme_id = selected_id
	if find(active_theme_id) == null and not definitions.is_empty():
		active_theme_id = definitions[0].id


func get_active_theme() -> ThemePaletteData:
	var theme := find(active_theme_id)
	if theme != null:
		return theme
	if definitions.is_empty():
		definitions = ThemePaletteRegistry.create_all()
	return definitions[0] if not definitions.is_empty() else ThemePaletteData.new()


func set_active_theme(theme_id: StringName) -> void:
	if find(theme_id) == null:
		return
	active_theme_id = theme_id
	theme_changed.emit(get_active_theme())


func find(theme_id: StringName) -> ThemePaletteData:
	for theme in definitions:
		if theme.id == theme_id:
			return theme
	return null


func apply_theme_to_control(root: Control) -> void:
	if root == null:
		return
	var theme := get_active_theme()
	_apply_to_control_recursive(root, theme)


func apply_theme_to_background(background: Node) -> void:
	if background != null and background.has_method("apply_theme"):
		background.call("apply_theme", get_active_theme())


func _apply_to_control_recursive(node: Control, theme: ThemePaletteData) -> void:
	if node is Label:
		var label := node as Label
		if not label.has_theme_color_override(&"font_color"):
			label.add_theme_color_override(&"font_color", theme.ui_text_color)
	elif node is Button:
		var button := node as Button
		for color_name in [&"font_color", &"font_disabled_color"]:
			button.add_theme_color_override(color_name, theme.ui_text_color)
		for color_name in [
			&"font_hover_color", &"font_pressed_color",
			&"font_hover_pressed_color", &"font_focus_color",
		]:
			button.add_theme_color_override(color_name, SELECTED_TEXT_COLOR)
	elif node is PanelContainer:
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = theme.ui_panel_color
		panel_style.corner_radius_top_left = 4
		panel_style.corner_radius_top_right = 4
		panel_style.corner_radius_bottom_right = 4
		panel_style.corner_radius_bottom_left = 4
		node.add_theme_stylebox_override(&"panel", panel_style)
	for child in node.get_children():
		if child is Control:
			_apply_to_control_recursive(child, theme)
