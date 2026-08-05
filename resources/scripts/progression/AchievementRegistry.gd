class_name AchievementRegistry
extends RefCounted


static func create_all() -> Array[AchievementData]:
	return [
		AchievementData.new(&"first_steps", "FIRST STEPS", "Complete your first round."),
		AchievementData.new(&"perfect_round", "PERFECT ROUND", "Complete a round without a mistake."),
		AchievementData.new(&"ten_down", "TEN DOWN", "Reach round 10.", false, &"tiny5"),
		AchievementData.new(&"checked_in", "CHECKED IN", "Unlock your first checkpoint."),
		AchievementData.new(&"rule_of_three", "RULE OF THREE", "Survive a round with three special rules."),
		AchievementData.new(&"full_house", "FULL HOUSE", "Reach the maximum hand size."),
		AchievementData.new(&"clean_run", "CLEAN RUN", "Reach round 20 without a mistake.", false, &"vcr"),
		AchievementData.new(&"counted_down", "COUNTED DOWN", "Complete the normal mode."),
		AchievementData.new(&"forever_counting", "FOREVER COUNTING", "Reach round 25 in Endless Mode."),
	]
