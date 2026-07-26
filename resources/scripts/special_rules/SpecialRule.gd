class_name SpecialRule
extends RefCounted

var id: StringName
var title: String
var subtitle: String
var incompatible_rules: Array[StringName] = []
var required_rules: Array[StringName] = []
var minimum_round := 1
var weight := 1.0


func activate(_context: RoundContext) -> void:
	pass


func deactivate(_context: RoundContext) -> void:
	pass
