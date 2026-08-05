class_name CheckpointSnapshot
extends Resource

var checkpoint_id: int
var start_round: int
var pile_count: int
var hand_size: int
var start_value: int
var turn_time: float
var difficulty_droughts: Dictionary
var unlocked_endless: bool


func to_dictionary() -> Dictionary:
	return {
		"checkpoint_id": checkpoint_id,
		"start_round": start_round,
		"pile_count": pile_count,
		"hand_size": hand_size,
		"start_value": start_value,
		"turn_time": turn_time,
		"difficulty_droughts": difficulty_droughts.duplicate(true),
		"unlocked_endless": unlocked_endless,
	}


static func from_dictionary(value: Dictionary) -> CheckpointSnapshot:
	var snapshot := CheckpointSnapshot.new()
	snapshot.checkpoint_id = int(value.get("checkpoint_id", 0))
	snapshot.start_round = int(value.get("start_round", 1))
	snapshot.pile_count = int(value.get("pile_count", 1))
	snapshot.hand_size = int(value.get("hand_size", 1))
	snapshot.start_value = int(value.get("start_value", 3))
	snapshot.turn_time = float(value.get("turn_time", 5.0))
	snapshot.difficulty_droughts = Dictionary(
		value.get("difficulty_droughts", {})
	).duplicate(true)
	snapshot.unlocked_endless = bool(value.get("unlocked_endless", false))
	return snapshot
