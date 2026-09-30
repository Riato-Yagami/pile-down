class_name CardAppearance
extends RefCounted

const TINY_REGULAR_FONT := preload("res://resources/fonts/Tiny5-Regular.ttf")
const Settings := preload("res://resources/scripts/settings/settings.gd")
const HIDDEN_TILE_COLOR := GameColors.HIDDEN_TILE


static func update(card: PlayingCard) -> void:
	if not card.is_node_ready():
		return
	var color: Color = card._tile_colors[
		card.card_value % card._tile_colors.size()
	]
	var visual_color := GameColors.COLORBLIND_TILE if card.colorblind_enabled else color
	var custom_hidden_tile := (
		not card.face_up and card._override_hidden_tile_with_font
	)
	card.face_sprite.visible = card.face_up or custom_hidden_tile
	card.back_sprite.visible = not card.face_up and not custom_hidden_tile
	card.selection_outline.texture = (
		card.face_sprite.texture if card.face_sprite.visible else card.back_sprite.texture
	)
	# Read settings at runtime as well: F6/F5 does not run the export sync tool.
	var selection_material := card.selection_outline.material as ShaderMaterial
	selection_material.set_shader_parameter("highlight_color", GameColors.SELECTION_HIGHLIGHT)
	selection_material.set_shader_parameter("rim_color", GameColors.SELECTION_RIM)
	card.back_sprite.modulate = GameColors.WHITE
	var tile_material := card.face_sprite.material as ShaderMaterial
	tile_material.set_shader_parameter(
		"tile_color", HIDDEN_TILE_COLOR if custom_hidden_tile else visual_color
	)
	card.value_label.visible = (
		(card.face_up or custom_hidden_tile)
		and (
			card.is_joker
			or card.round_modifiers == null
			or not card.round_modifiers.hide_tile_numbers
		)
	)
	card.value_label.text = (
		"?" if custom_hidden_tile
		else "J" if card.is_joker
		else RoundModifiers.format_value(
			card.card_value, card.roman_numerals_enabled
		)
	)
	card._apply_value_label_offset(card.face_sprite.position.y)
	card.value_label.add_theme_font_size_override(
		"font_size",
		int(round(
			card._value_font_size
			* (
				0.7
				if card.roman_numerals_enabled and card.card_value in [7, 8]
				else 1.0
			)
		))
	)
	if card.face_up and card.roman_numerals_enabled and card.card_value in [7, 8]:
		card.value_label.add_theme_font_override("font", TINY_REGULAR_FONT)
	elif card._value_font != null:
		card.value_label.add_theme_font_override("font", card._value_font)
	else:
		card.value_label.remove_theme_font_override("font")
	card.value_label.add_theme_color_override(
		"font_color",
		HIDDEN_TILE_COLOR if custom_hidden_tile
		else Settings.COLORBLIND_VALUE_COLOR if card.colorblind_enabled
		else GameColors.tile_text_color(color)
	)
