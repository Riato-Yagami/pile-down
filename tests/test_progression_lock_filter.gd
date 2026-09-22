extends SceneTree

const LockFilterScene := preload(
	"res://resources/scenes/ui/ProgressionLockFilter.tscn"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lock_filter := LockFilterScene.instantiate() as ProgressionLockFilter
	root.add_child(lock_filter)
	lock_filter.animation_duration = 0.0
	lock_filter.set_mode(ProgressionLockFilter.LOCKED)
	await process_frame
	lock_filter.animation_duration = 0.2
	var lock_handle := lock_filter.get_node(
		"IconOffset/HandleFlipAnchor/LockHandle"
	) as TextureRect
	var flip_anchor := lock_filter.get_node(
		"IconOffset/HandleFlipAnchor"
	) as Node2D
	var lock_main := lock_filter.get_node("IconOffset/LockMain") as TextureRect
	var locked_position := (
		lock_filter.HANDLE_BASE_POSITION + lock_filter.locked_handle_offset
	)
	var unlocked_position := (
		lock_filter.HANDLE_BASE_POSITION + lock_filter.unlocked_handle_offset
	)
	assert(lock_main.size == lock_main.texture.get_size())
	assert(lock_handle.size == lock_handle.texture.get_size())
	assert(lock_handle.position == locked_position)
	lock_filter.set_mode(ProgressionLockFilter.UNLOCKED)
	var passed_through_both := false
	var midpoint_deadline := Time.get_ticks_msec() + int(
		lock_filter.animation_duration * 750.0
	)
	while Time.get_ticks_msec() < midpoint_deadline:
		if (
			is_equal_approx(lock_handle.position.x, lock_filter.HANDLE_BASE_POSITION.x)
			and lock_handle.position.y < locked_position.y
			and flip_anchor.scale == Vector2.ONE
		):
			passed_through_both = true
			break
		await process_frame
	assert(passed_through_both)
	await lock_filter._pose_tween.finished
	assert(lock_handle.position.is_equal_approx(unlocked_position))
	assert(flip_anchor.scale.is_equal_approx(lock_filter.unlocked_handle_scale))
	lock_filter.queue_free()
	quit()
