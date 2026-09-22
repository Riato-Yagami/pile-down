class_name SaveConfig
extends RefCounted

const PATH := "user://pile_down.cfg"


static func load_current() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(PATH)
	return config
