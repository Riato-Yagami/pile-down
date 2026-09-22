class_name ProgressionOrdering
extends RefCounted


static func sort_achievements(entries: Array) -> void:
	var categories: Dictionary = {}
	for data: AchievementData in entries:
		if not categories.has(data.category):
			categories[data.category] = categories.size()
	entries.sort_custom(func(a: AchievementData, b: AchievementData) -> bool:
		if a.category != b.category:
			return categories[a.category] < categories[b.category]
		if a.difficulty != b.difficulty:
			return a.difficulty < b.difficulty
		return String(a.id) < String(b.id)
	)


static func unlock_difficulty(data: Data) -> int:
	if data is FontData or data is ColorPaletteData:
		if data.default_unlocked:
			return 0
	elif data is ChallengeData and data.required_achievement_id().is_empty():
		return 0
	var required: AchievementData = data.required_achievement
	# Unconfigured locked rewards belong at the end, never among free rewards.
	return required.difficulty if required != null else 11


static func sort_unlockables(entries: Array) -> void:
	entries.sort_custom(func(a: Data, b: Data) -> bool:
		var a_rank := unlock_difficulty(a)
		var b_rank := unlock_difficulty(b)
		if a_rank != b_rank:
			return a_rank < b_rank
		return String(a.id) < String(b.id)
	)
