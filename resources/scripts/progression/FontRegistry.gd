class_name FontRegistry
extends RefCounted

const PRESS_START := preload("res://resources/fonts/PressStart2P-Regular.ttf")
const TINY5 := preload("res://resources/fonts/Tiny5-Regular.ttf")
const VCR := preload("res://resources/fonts/VCR_OSD_MONO_1.001.ttf")


static func create_all() -> Array[FontData]:
	return [
		FontData.new(&"press_start_2p", "PRESS START 2P", PRESS_START, true),
		FontData.new(&"tiny5", "TINY5", TINY5, false, &"ten_down"),
		FontData.new(&"vcr", "VCR OSD MONO", VCR, false, &"clean_run"),
	]
