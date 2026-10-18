extends SceneTree

const TimerScript := preload("res://resources/scripts/gameplay/TimerManager.gd")


func _init() -> void:
	var timer := TimerScript.new()
	var expired := {"count": 0}
	timer.time_expired.connect(func() -> void: expired.count += 1)
	timer.start_countdown(3.0)
	timer.freeze_countdown(DifficultySettings.MISTAKE_TIMER_FREEZE_DURATION)
	timer._process(0.2)
	assert(timer.time_left == 3.0)
	timer._process(0.2)
	assert(timer.time_left == 3.0)
	timer._process(0.2)
	assert(is_equal_approx(timer.time_left, 2.9), "Only time after the freeze must count")
	assert(timer.running)

	# A second mistake gives a new respite instead of resuming the older one.
	timer.freeze_countdown(0.5)
	timer._process(0.3)
	timer.freeze_countdown(0.5)
	timer._process(0.4)
	assert(is_equal_approx(timer.time_left, 2.9))
	timer._process(0.2)
	assert(is_equal_approx(timer.time_left, 2.8))

	# A new hand cancels the previous respite, and stopping cannot resume later.
	timer.freeze_countdown(0.5)
	timer.start_countdown(2.0)
	timer._process(0.1)
	assert(is_equal_approx(timer.time_left, 1.9))
	timer.freeze_countdown(0.5)
	timer.stop_countdown()
	timer._process(1.0)
	assert(not timer.running)
	assert(is_equal_approx(timer.time_left, 1.9))
	timer.resume_countdown()
	timer._process(0.1)
	assert(is_equal_approx(timer.time_left, 1.8))

	# Disabling the respite retains normal expiration, including a short timer.
	timer.start_countdown(0.1)
	timer.freeze_countdown(0.0)
	timer._process(0.1)
	assert(expired.count == 1)
	timer.start_countdown(0.1)
	timer.freeze_countdown(0.5)
	timer._process(0.5)
	assert(timer.time_left == 0.1)
	assert(expired.count == 1)
	timer._process(0.2)
	assert(expired.count == 2)
	timer.free()
	print("Mistake timer freeze tests passed.")
	quit()
