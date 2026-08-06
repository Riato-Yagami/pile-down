class_name ProgressionCompletionBar
extends NinePatchRect

var progress_hint := ""


func _make_custom_tooltip(_for_text: String) -> Object:
	var label := Label.new()
	label.text = progress_hint
	label.custom_minimum_size.x = 120.0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
