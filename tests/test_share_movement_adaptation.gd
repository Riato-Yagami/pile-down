extends "res://tests/test_share_movement_audit.gd"


func _run() -> void:
	create_timer(120).timeout.connect(func(): quit(1))
	await _audit("adaptation_orbit", [&"merry_go_stack"], 13)
	await _audit("adaptation_shake", [&"shaking_piles"], 13)
	await _audit("adaptation_wave", [&"wavy_baby"], 13)
	await _audit("adaptation_snake", [&"snake"], 13)
	var output := OS.get_environment("PILE_DOWN_SHARE_AUDIT_OUTPUT")
	if not output.is_empty():
		var file := FileAccess.open(output, FileAccess.WRITE)
		assert(file != null)
		file.store_string(JSON.stringify(samples, "\t"))
	print("Adaptation share audit passed: four level-III movement combinations, ", samples.size(), " snapshots.")
	quit()
