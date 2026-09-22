extends SceneTree

const Announcement := preload("res://resources/scripts/ui/DifficultyAnnouncement.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Label.new()
	root.add_child(host)
	host.size = Vector2(440, 72)
	var tween := Announcement.animate(host, ["+1 PILE", "-1 SECOND"], 0.2, 0.45)
	tween.pause()
	var first := host.get_child(0) as Label
	var second := host.get_child(1) as Label
	tween.custom_step(0.3)
	assert(is_equal_approx(first.modulate.a, 1.0))
	assert(is_zero_approx(first.position.y))
	assert(is_zero_approx(second.modulate.a))
	tween.custom_step(0.22)
	assert(first.position.y < 0.0)
	assert(second.modulate.a > 0.0 and second.modulate.a < 1.0)
	tween.custom_step(0.2)
	assert(is_equal_approx(first.position.y, -second.position.y))
	assert(second.scale.is_equal_approx(Vector2.ONE))
	# Skipping must finish both line animations and remove their controls.
	tween.custom_step(1000000.0)
	await process_frame
	assert(host.get_child_count() == 0)
	assert(is_zero_approx(host.modulate.a))
	tween = Announcement.animate(host, ["+1 CARD"], 0.2, 0.45)
	tween.custom_step(1000000.0)
	await process_frame
	assert(host.get_child_count() == 0)
	host.queue_free()
	await process_frame
	print("Difficulty announcement tests passed.")
	quit()
