class_name RunSummary
extends RefCounted

enum Mode { NORMAL, CHECKPOINT, ENDLESS, CHALLENGE }

var mode := Mode.NORMAL
var started_from_checkpoint := false
var start_round := 1
var completed_rounds := 0
var highest_round := 0
var run_time_seconds := 0.0
var mistakes_made := 0
var lives_lost := 0
var active_bonus_levels: Dictionary = {}
var normal_game_completed := false
var uses_endless_progression := false
