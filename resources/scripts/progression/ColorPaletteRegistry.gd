class_name ColorPaletteRegistry
extends RefCounted


static func create_all() -> Array[ColorPaletteData]:
	return [
		ColorPaletteData.new(
			&"arcade", "CLASSIC",
			[
				Color("#2FA7C9"), Color("#2FA66A"), Color("#3F6FD9"),
				Color("#E2554F"), Color("#D9A514"), Color("#7FA52B"),
				Color("#D84F83"), Color("#E27A2D"), Color("#7B5BC7"),
				Color("#A65F32"),
			], true
		),
		ColorPaletteData.new(
			&"arcade_crt", "ARCADE CRT",
			[
				Color("#596275"), Color("#00B8D9"), Color("#FF3D81"),
				Color("#FFD23F"), Color("#00B894"), Color("#FF7043"),
				Color("#7357D9"), Color("#3D7EFF"), Color("#A3CB38"),
				Color("#D252E1"),
			], true
		),
		_palette(&"falling_blocks", "FALLING BLOCKS", [
			"#5D6472", "#00ACC1", "#FBC02D", "#8E24AA", "#43A047",
			"#E53935", "#1E88E5", "#FB8C00", "#D81B60", "#7CB342",
		], &"max_piles"),
		_palette(&"monster_types", "MONSTER TYPES", [
			"#687076", "#E95C32", "#3688D8", "#54A84F", "#E2B91F",
			"#D154A5", "#39AFC5", "#6657B8", "#715097", "#E06B9A",
		], &"beat_all_special_rules"),
		_palette(&"cube_mix", "CUBE MIX", [
			"#62676D", "#D93832", "#E77B22", "#E0B51B", "#379658",
			"#2878C7", "#7054B7", "#D14E8B", "#269F9A", "#A86235",
		], &"start_value_nine"),
		_palette(&"digital_pet", "DIGITAL PET", [
			"#66707A", "#F15B64", "#F28C35", "#D9B82A", "#57A967",
			"#408FD0", "#8865C8", "#DD619A", "#27A8A0", "#B46742",
		], &"first_checkpoint"),
		_palette(&"vhs_sunset", "VHS SUNSET", [
			"#625768", "#D94C5C", "#E87538", "#DDAE32", "#CC4778",
			"#A64FC4", "#7259D4", "#367CC9", "#279CB4", "#368B7B",
		], &"speedrun_10_rounds"),
		_palette(&"saturday_heroes", "SATURDAY HEROES", [
			"#59636F", "#D73D3D", "#3276C3", "#D6AD24", "#3B9856",
			"#D8528A", "#7B55B3", "#E2752C", "#26989C", "#A56A34",
		], &"five_different_bonuses"),
		_palette(&"mecha_warning", "MECHA WARNING", [
			"#555F69", "#D84A3A", "#E5802A", "#D5B229", "#4E9B63",
			"#278EAE", "#3D70B7", "#6753A6", "#C74C73", "#8A7042",
		], &"minimum_timer"),
		_palette(&"magic_gems", "MAGIC GEMS", [
			"#697079", "#C74747", "#D27632", "#C2A52B", "#41946C",
			"#318BBD", "#5756B4", "#8A4BB0", "#C24D8B", "#348E8A",
		], &"all_bonuses_maxed_once"),
		_palette(&"pocket_screen", "POCKET SCREEN", [
			"#52644A", "#718A4D", "#8A7E3F", "#4F823F", "#3D7962",
			"#4F7084", "#63608C", "#80567C", "#8B5F48", "#68733C",
		], &"complete_normal_game"),
	]


static func _palette(
	id: StringName, title: String, hex_colors: Array, achievement_id: StringName
) -> ColorPaletteData:
	var colors: Array[Color] = []
	for hex_color in hex_colors:
		colors.append(Color(str(hex_color)))
	return ColorPaletteData.new(
		id, title, colors, false, _achievement(achievement_id)
	)


static func _achievement(id: StringName) -> AchievementData:
	for achievement in AchievementRegistry.create_all():
		if achievement.id == id:
			return achievement
	return null
