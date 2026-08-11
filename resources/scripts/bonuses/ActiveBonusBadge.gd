class_name ActiveBonusBadge
extends Label

signal description_requested(description: String)
signal description_hidden()

@export var highlight_material: ShaderMaterial

var _description := ""


func _ready() -> void:
	material = null
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(
	data: BonusData,
	level: int,
	consumed := false,
	display_acronym := ""
) -> void:
	text = "%s%s" % [
		display_acronym if not display_acronym.is_empty() else _acronym(data.title),
		" %s" % _roman_level(level) if level > 1 else "",
	]
	_description = data.description
	tooltip_text = ""
	modulate = Color(0.55, 0.55, 0.55, 0.7) if consumed else Color.WHITE


func _on_mouse_entered() -> void:
	material = highlight_material
	description_requested.emit(_description)


func _on_mouse_exited() -> void:
	material = null
	description_hidden.emit()


func _acronym(title: String) -> String:
	var words := title.strip_edges().split(" ", false)
	if words.size() <= 1:
		return title.substr(0, 2).to_upper()
	var result := ""
	for word in words:
		if not word.is_empty():
			result += word.left(1)
	return result.to_upper()


static func build_unique_acronyms(definitions: Array[BonusData]) -> Dictionary:
	var words_by_id := {}
	var widths_by_id := {}
	for data in definitions:
		var words := _title_words(data.title)
		words_by_id[data.id] = words
		var widths: Array[int] = []
		widths.resize(words.size())
		widths.fill(1)
		widths_by_id[data.id] = widths

	while true:
		var collisions := _acronym_collisions(definitions, words_by_id, widths_by_id)
		if collisions.is_empty():
			break
		var expanded := false
		for colliding_ids_value in collisions:
			var colliding_ids: Array = colliding_ids_value
			var word_count: int = (words_by_id[colliding_ids[0]] as Array).size()
			for word_index in word_count:
				var distinct_words := {}
				var can_expand := false
				for id in colliding_ids:
					var words: Array = words_by_id[id]
					var widths: Array = widths_by_id[id]
					distinct_words[words[word_index]] = true
					can_expand = can_expand or widths[word_index] < words[word_index].length()
				if distinct_words.size() > 1 and can_expand:
					for id in colliding_ids:
						var words: Array = words_by_id[id]
						var widths: Array = widths_by_id[id]
						widths[word_index] = mini(widths[word_index] + 1, words[word_index].length())
					expanded = true
					break
		if not expanded:
			break

	var result := {}
	for data in definitions:
		result[data.id] = _format_acronym(words_by_id[data.id], widths_by_id[data.id])
	return result


static func _title_words(title: String) -> Array[String]:
	var result: Array[String] = []
	for word in title.strip_edges().split(" ", false):
		if not word.is_empty():
			result.append(word.to_lower())
	return result


static func _format_acronym(words: Array, widths: Array) -> String:
	if words.size() == 1:
		return words[0].left(maxi(2, widths[0])).capitalize()
	var result := ""
	for index in words.size():
		var part: String = words[index].left(widths[index])
		result += part.left(1).to_upper() + part.substr(1).to_lower()
	return result


static func _acronym_collisions(
	definitions: Array[BonusData],
	words_by_id: Dictionary,
	widths_by_id: Dictionary
) -> Array:
	var ids_by_acronym := {}
	for data in definitions:
		var acronym := _format_acronym(words_by_id[data.id], widths_by_id[data.id])
		if not ids_by_acronym.has(acronym):
			ids_by_acronym[acronym] = []
		ids_by_acronym[acronym].append(data.id)
	var result := []
	for ids in ids_by_acronym.values():
		if ids.size() > 1:
			result.append(ids)
	return result


func _roman_level(level: int) -> String:
	const ROMAN_LEVELS := ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]
	return ROMAN_LEVELS[level] if level > 0 and level < ROMAN_LEVELS.size() else str(level)
