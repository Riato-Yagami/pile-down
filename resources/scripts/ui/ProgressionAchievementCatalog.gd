@tool
class_name ProgressionAchievementCatalog
extends Node

## Achievements affichés par le menu et suivis pendant une partie.
@export var achievements: Array[AchievementData] = AchievementRegistry.create_all()
