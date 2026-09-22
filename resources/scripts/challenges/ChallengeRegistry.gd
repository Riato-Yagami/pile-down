class_name ChallengeRegistry
extends RefCounted

const CATALOG := preload("res://resources/data/challenges.tres")


static func create_all() -> Array[ChallengeData]:
	var result: Array[ChallengeData] = []
	for entry in CATALOG.enabled_data:
		var data := entry as ChallengeData
		if data == null:
			push_warning("Ignoring non-ChallengeData entry in challenge catalog.")
			continue
		result.append(data)
	ProgressionOrdering.sort_unlockables(result)
	return result
