extends "res://tests/test_share_movement_audit.gd"


func _run() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	await _audit("shell_orbit", [&"shell_game", &"merry_go_stack"], 13)
	var output := OS.get_environment("PILE_DOWN_SHARE_AUDIT_OUTPUT")
	if not output.is_empty():
		var file := FileAccess.open(output, FileAccess.WRITE)
		assert(file != null)
		file.store_string(JSON.stringify(samples, "\t"))
	print("Shell Game + orbit share audit passed: swaps across orbit paths, ", samples.size(), " snapshots.")
	quit()
