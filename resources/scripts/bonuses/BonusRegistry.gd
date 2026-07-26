class_name BonusRegistry
extends RefCounted


static func create_all() -> Array[BonusData]:
	return [
		BonusData.new(&"open_book", "OPEN BOOK", "One stack never flips.", BonusData.Category.MEMORY, 3),
		BonusData.new(&"quick_peek", "QUICK PEEK", "Stacks flash before each hand.", BonusData.Category.MEMORY, 3),
		BonusData.new(&"last_reminder", "LAST REMINDER", "Your last stack stays visible.", BonusData.Category.MEMORY),
		BonusData.new(&"mistake_reveal", "LESSON LEARNED", "Mistakes reveal every stack.", BonusData.Category.MEMORY, 3),
		BonusData.new(&"wild_card", "WILD CARD", "Jokers may appear.", BonusData.Category.HAND, 3),
		BonusData.new(&"redraw", "REDRAW", "Replace one hand per round.", BonusData.Category.HAND, 3),
		BonusData.new(&"lucky_hand", "LUCKY HAND", "Some hands offer answers.", BonusData.Category.HAND, 3),
		BonusData.new(&"time_bank", "TIME BANK", "Save some unused time.", BonusData.Category.TIME, 3),
		BonusData.new(&"slow_start", "WARM-UP", "Early hands get extra time.", BonusData.Category.TIME, 3),
		BonusData.new(&"spare_life", "SPARE LIFE", "Gain one extra mistake.", BonusData.Category.SURVIVAL, 3),
		BonusData.new(&"safety_net", "SAFETY NET", "Ignore the first mistake.", BonusData.Category.SURVIVAL),
		BonusData.new(&"clean_slate", "CLEAN SLATE", "Finish a stack, recover a mistake.", BonusData.Category.SURVIVAL, 3),
		BonusData.new(
			&"rule_breaker", "RULE BREAKER", "Cancel one special rule.",
			BonusData.Category.SPECIAL_RULE, 
			#3, 0.55, 10, BonusData.Rarity.LEGENDARY
		),
		BonusData.new(
			&"adaptation", "ADAPTATION", "Special rules become slightly easier.",
			BonusData.Category.SPECIAL_RULE, 
			#3, 0.75, 5, BonusData.Rarity.RARE
		),
	]
