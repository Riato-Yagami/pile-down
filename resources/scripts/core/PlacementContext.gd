class_name PlacementContext
extends RefCounted

enum Source {
	PLAYER,
	DOUBLE_DOWN,
	DEJA_VU,
	BRING_A_FRIEND,
}

var source := Source.PLAYER
var root_action_id := 0
var allow_deja_vu := false
var allow_double_down := false
var allow_bring_a_friend := false


func _init(
	placement_source := Source.PLAYER,
	action_id := 0
) -> void:
	source = placement_source
	root_action_id = action_id
	allow_deja_vu = source == Source.PLAYER
	allow_double_down = source == Source.PLAYER
	allow_bring_a_friend = source == Source.PLAYER
