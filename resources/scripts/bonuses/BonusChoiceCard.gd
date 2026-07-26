class_name BonusChoiceCard
extends HighlightButton

var choice_index := 0


func setup(data: BonusData, level: int, index: int) -> void:
	choice_index = index
	text = "%s%s" % [
		data.title,
		" %s" % _roman(level) if level > 1 else "",
	]


func _roman(value: int) -> String:
	return ["", "I", "II", "III"][clampi(value, 0, 3)]
