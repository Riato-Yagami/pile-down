class_name AchievementData
extends Resource

@export var id: StringName
@export var title: String
@export var description: String
@export var category: StringName
@export var hidden := false
@export var reward_font: StringName
## Seuil principal du succes lorsqu'il peut etre pilote par les donnees.
@export var required_count := 0
## Duree maximale stricte, en secondes. Zero desactive la contrainte de temps.
@export var time_limit_seconds := 0.0


func _init(
	achievement_id: StringName = &"",
	achievement_title := "",
	achievement_description := "",
	achievement_category: StringName = &"ROUNDS",
	is_hidden := false,
	font_reward: StringName = &""
) -> void:
	id = achievement_id
	title = achievement_title
	description = achievement_description
	category = achievement_category
	hidden = is_hidden
	reward_font = font_reward
