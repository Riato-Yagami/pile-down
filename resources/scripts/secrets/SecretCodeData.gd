class_name SecretCodeData
extends Data

@export var code: String
@export var reward_font: FontData
## Exclusive UTC cutoffs, empty to disable a condition.
@export var achievement_before: String
@export var expires_at: String


func is_eligible(achievements: AchievementManager, now: int) -> bool:
	if not expires_at.is_empty() and now >= int(Time.get_unix_time_from_datetime_string(expires_at)):
		return false
	if achievement_before.is_empty():
		return true
	var cutoff := int(Time.get_unix_time_from_datetime_string(achievement_before))
	for achievement_id in achievements.unlocked:
		var date := str(achievements.unlock_dates.get(achievement_id, ""))
		if date.is_empty():
			continue
		var timestamp := int(Time.get_unix_time_from_datetime_string(date))
		if timestamp > 0 and timestamp < cutoff:
			return true
	return false
