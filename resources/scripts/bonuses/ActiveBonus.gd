class_name ActiveBonus
extends RefCounted

var data: BonusData
var level := 1


func _init(bonus_data: BonusData = null) -> void:
	data = bonus_data

