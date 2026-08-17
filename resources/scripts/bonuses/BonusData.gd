class_name BonusData
extends Data

enum Category { MEMORY, HAND, TIME, SURVIVAL, SPECIAL_RULE }
enum Rarity { COMMON, RARE, LEGENDARY }

@export var title: String
@export_multiline var description: String
@export var category: Category
@export var rarity: Rarity
@export var max_level: int
@export var weight: float
@export var minimum_round: int


func _init(
	bonus_id: StringName = &"",
	bonus_title := "",
	bonus_description := "",
	bonus_category := Category.MEMORY,
	bonus_max_level := 1,
	bonus_weight := 1.0,
	bonus_minimum_round := 1,
	bonus_rarity := Rarity.COMMON
) -> void:
	id = bonus_id
	title = bonus_title
	description = bonus_description
	category = bonus_category
	max_level = bonus_max_level
	weight = bonus_weight
	minimum_round = bonus_minimum_round
	rarity = bonus_rarity
