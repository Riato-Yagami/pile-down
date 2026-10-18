class_name AchievementData
extends Data

@export var title: String
@export var description: String
@export var category: StringName
## Internal progression rank, from introductory (1) to completionist (10).
@export_range(1, 10, 1) var difficulty := 1
## Editorial explanation for the unlockables export, never shown in game.
@export_multiline var reward_rationale := ""
@export var hidden := false
@export var reward_font: StringName
## Seuil principal du succes lorsqu'il peut etre pilote par les donnees.
@export var required_count := 0
## Duree maximale stricte, en secondes. Zero desactive la contrainte de temps.
@export var time_limit_seconds := 0.0
@export_category("Unlock Modes")
## Menu actions are evaluated independently of the previous gameplay run.
@export var allow_menu := false
@export var allow_normal := true
@export var allow_endless := true
@export var allow_challenges := false
@export var allow_checkpoints := false
## Seeded runs must also be permitted by their underlying mode.
@export var allow_seeded := false


func allows_run(mode: RunSummary.Mode, seeded: bool) -> bool:
	if seeded and not allow_seeded:
		return false
	match mode:
		RunSummary.Mode.NORMAL:
			return allow_normal
		RunSummary.Mode.ENDLESS:
			return allow_endless
		RunSummary.Mode.CHALLENGE:
			return allow_challenges
		RunSummary.Mode.CHECKPOINT:
			return allow_checkpoints
	return false


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
