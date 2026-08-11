class_name BonusRegistry
extends RefCounted


static func create_all() -> Array[BonusData]:
	return [
		BonusData.new(&"open_book", "OPEN BOOK", "Keeps one additional pile face up per level.", BonusData.Category.MEMORY, 3),
		BonusData.new(&"quick_peek", "QUICK PEEK", "Periodically flashes every pile value. Higher levels flash more often and for longer.", BonusData.Category.MEMORY, 3),
		BonusData.new(&"last_reminder", "LAST REMINDER", "Keeps the pile you most recently played on face up.", BonusData.Category.MEMORY),
		BonusData.new(&"mistake_reveal", "LESSON LEARNED", "After a mistake, briefly reveals every pile value. Higher levels reveal them longer.", BonusData.Category.MEMORY, 3),
		BonusData.new(&"wild_card", "WILD CARD", "Adds a growing chance for a joker to appear in each new hand.", BonusData.Category.HAND, 3),
		BonusData.new(&"redraw", "REDRAW", "Replaces the current hand. Grants one use per level each round.", BonusData.Category.HAND, 3),
		BonusData.new(&"lucky_hand", "LUCKY HAND", "Some new hands contain extra cards that can be played immediately. Higher levels add more.", BonusData.Category.HAND, 3),
		BonusData.new(&"time_bank", "TIME BANK", "Carries part of the unused hand time into the next hand, up to 2 seconds.", BonusData.Category.TIME, 3),
		BonusData.new(&"slow_start", "WARM-UP", "Adds time to the first hands of each round. The bonus decreases every 3 hands.", BonusData.Category.TIME, 3),
		BonusData.new(&"spare_life", "SPARE LIFE", "Adds one mistake point per level at the start of each round.", BonusData.Category.SURVIVAL, 3),
		BonusData.new(&"safety_net", "SAFETY NET", "Prevents the first mistake of each round from removing a mistake point.", BonusData.Category.SURVIVAL),
		BonusData.new(&"clean_slate", "CLEAN SLATE", "Completing a pile restores a mistake point. Higher levels add uses; level 3 fully restores them.", BonusData.Category.SURVIVAL, 3),
		BonusData.new(
			&"bring_a_friend", "BRING A FRIEND", "Dragging a card also carries neighboring hand cards, which try to play on nearby compatible piles.",
			BonusData.Category.HAND, 3, 0.65, 1, BonusData.Rarity.RARE
		),
		BonusData.new(
			&"pile_mover", "PILE MOVER", "Lets you drag unfinished piles to rearrange the board.",
			BonusData.Category.MEMORY, 1, 0.65, 1, BonusData.Rarity.RARE
		),
		BonusData.new(
			&"double_down", "DOUBLE DOWN", "After a valid play, automatically plays up to one sequential card per level on the same pile.",
			BonusData.Category.HAND, 3, 0.55, 1, BonusData.Rarity.RARE
		),
		BonusData.new(
			&"deja_vu", "DEJA VU", "After a valid play, automatically plays up to one matching card per level on other compatible piles.",
			BonusData.Category.HAND, 3, 0.55, 1, BonusData.Rarity.RARE
		),
		BonusData.new(
			&"rule_breaker", "RULE BREAKER", "Before a round, lets you remove active special rules. Higher levels remove more or allow the last rule.",
			BonusData.Category.SPECIAL_RULE,
			3, 0.55, 10, BonusData.Rarity.LEGENDARY
		),
		BonusData.new(
			&"adaptation", "ADAPTATION", "Reduces the intensity of special rules, with a stronger reduction at each level.",
			BonusData.Category.SPECIAL_RULE,
			3, 0.75, 5, BonusData.Rarity.RARE
		),
	]


static func get_bonus(id: StringName) -> BonusData:
	for data in create_all():
		if data.id == id:
			return data
	return null
