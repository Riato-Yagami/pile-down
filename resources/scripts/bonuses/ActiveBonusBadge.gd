class_name ActiveBonusBadge
extends Label


func setup(data: BonusData, level: int, consumed := false) -> void:
	text = "%s%s" % [
		data.title.substr(0, 2),
		str(level) if level > 1 else "",
	]
	tooltip_text = "%s — %s" % [data.title, data.description]
	modulate = Color(0.55, 0.55, 0.55, 0.7) if consumed else Color.WHITE
