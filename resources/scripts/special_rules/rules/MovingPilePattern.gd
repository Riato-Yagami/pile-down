class_name MovingPilePattern
extends Node

const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")

var active := false
var elapsed := 0.0
var piles: Array[MemoryPile] = []
var base_positions: Dictionary = {}
var speed_multiplier := 1.0
var pattern_id: StringName = &"orbit"
var orbit_data: Dictionary = {}
var manually_moving_pile: MemoryPile
var movement_suspended := false


func _process(delta: float) -> void:
	if not active or movement_suspended:
		return
	elapsed += delta
	if pattern_id == &"orbit":
		for pile in piles:
			if _can_move(pile):
				_apply_orbit(pile)
		return
	var offsets: Dictionary = {}
	for index in piles.size():
		var pile := piles[index]
		if not _can_move(pile):
			continue
		if pattern_id == &"wave":
			var base: Vector2 = base_positions.get(pile, pile.position)
			var horizontal_phase := (
				Difficulty.WAVY_BABY_PHASE
				+ base.x * Difficulty.WAVY_BABY_HORIZONTAL_PHASE_SPACING
			)
			offsets[pile] = Vector2(
				0.0,
				sin(
					elapsed * Difficulty.WAVY_BABY_SPEED * speed_multiplier
					+ horizontal_phase
				)
					* Difficulty.WAVY_BABY_AMPLITUDE
			)
		else:
			var phase_x := float(index) * Difficulty.SHAKING_PILES_PHASE_STEP_X
			var phase_y := float(index) * Difficulty.SHAKING_PILES_PHASE_STEP_Y
			offsets[pile] = Vector2(
				sin(
					elapsed * Difficulty.SHAKING_PILES_FREQUENCY_X
					* speed_multiplier + phase_x
				) * Difficulty.SHAKING_PILES_AMPLITUDE_X,
				cos(
					elapsed * Difficulty.SHAKING_PILES_FREQUENCY_Y
					* speed_multiplier + phase_y
				) * Difficulty.SHAKING_PILES_AMPLITUDE_Y
			)
	var safe_scale := _safe_offset_scale(offsets)
	for pile: MemoryPile in offsets:
		var base: Vector2 = base_positions[pile]
		# Keep the continuous coordinates. Rounding every frame turns the sine
		# wave into visible one-pixel steps at low speed.
		pile.position = base + (offsets[pile] as Vector2) * safe_scale


func start(
	round_piles: Array[MemoryPile],
	round_number: int,
	movement_speed_multiplier := 1.0,
	requested_pattern: StringName = &"orbit"
) -> void:
	active = true
	elapsed = 0.0
	speed_multiplier = movement_speed_multiplier
	pattern_id = requested_pattern if not requested_pattern.is_empty() else &"orbit"
	piles.assign(round_piles)
	base_positions.clear()
	orbit_data.clear()
	for pile in piles:
		base_positions[pile] = pile.position
	if pattern_id == &"orbit":
		_configure_orbits(round_number)
		await _animate_orbit_setup()


func _animate_orbit_setup() -> void:
	if orbit_data.is_empty():
		return
	movement_suspended = true
	var tween := (
		create_tween()
		.set_parallel(true)
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_IN_OUT)
	)
	var duration := (
		Difficulty.MERRY_GO_STACK_SETUP_DURATION
		/ maxf(speed_multiplier, 0.01)
	)
	for pile: MemoryPile in orbit_data:
		var data: Dictionary = orbit_data[pile]
		var destination := (data.center as Vector2) + (data.offset as Vector2)
		tween.tween_property(pile, "position", destination, duration)
	await tween.finished
	movement_suspended = false
	elapsed = 0.0
	_process(0.0)


func _configure_orbits(round_number: int) -> void:
	if piles.size() < 2:
		return
	var centroid := Vector2.ZERO
	for pile in piles:
		centroid += pile.position
	centroid /= piles.size()
	var center_pile := piles[0]
	for pile in piles:
		if pile.position.distance_squared_to(centroid) < center_pile.position.distance_squared_to(centroid):
			center_pile = pile
	var center := _screen_center_in_pile_parent(center_pile)
	var direction := -1.0 if round_number % 2 == 0 else 1.0
	var orbiting_piles: Array[MemoryPile] = []
	for pile in piles:
		if pile != center_pile:
			orbiting_piles.append(pile)
	var orbit_count := orbiting_piles.size()
	var radius := Difficulty.MERRY_GO_STACK_MINIMUM_RADIUS
	if orbit_count > 1:
		# Adjacent piles on a regular polygon are separated by a chord. Grow the
		# radius until that chord clears the full minimum drop-area distance.
		var chord_radius := (
			Difficulty.MINIMUM_PILE_DISTANCE
			/ (2.0 * sin(PI / float(orbit_count)))
		)
		radius = maxf(
			radius,
			chord_radius + Difficulty.MERRY_GO_STACK_RADIUS_PADDING
		)
	orbit_data[center_pile] = {
		"center": center,
		"offset": Vector2.ZERO,
		"direction": direction,
	}
	for index in orbit_count:
		var pile := orbiting_piles[index]
		var start_angle := -PI * 0.5 + TAU * float(index) / float(orbit_count)
		var offset := Vector2(cos(start_angle), sin(start_angle)) * radius
		orbit_data[pile] = {
			"center": center,
			"offset": offset,
			"direction": direction,
		}


func _screen_center_in_pile_parent(pile: MemoryPile) -> Vector2:
	var parent_control := pile.get_parent() as Control
	if parent_control == null:
		return pile.position
	var viewport_center := get_viewport().get_visible_rect().size * 0.5
	var local_center := (
		parent_control.get_global_transform().affine_inverse()
		* viewport_center
	)
	return local_center - pile.size * 0.5


func _apply_orbit(pile: MemoryPile) -> void:
	if not orbit_data.has(pile):
		pile.position = (base_positions.get(pile, pile.position) as Vector2).round()
		return
	var data: Dictionary = orbit_data[pile]
	var angle := (
		elapsed
		* Difficulty.MERRY_GO_STACK_SPEED
		* speed_multiplier
		* float(data.direction)
	)
	pile.position = ((data.center as Vector2) + (data.offset as Vector2).rotated(angle)).round()


func _can_move(pile: MemoryPile) -> bool:
	return (
		is_instance_valid(pile)
		and not pile.completed
		and pile.visible
		and pile != manually_moving_pile
	)


func _safe_offset_scale(offsets: Dictionary) -> float:
	if _offsets_are_safe(offsets, 1.0):
		return 1.0
	var safe_scale := 0.0
	var unsafe_scale := 1.0
	# A binary search follows the continuously changing safe amplitude without
	# the visible 5% jumps produced by the former decrementing loop.
	for _iteration in Difficulty.MOVING_PILES_SAFETY_SEARCH_ITERATIONS:
		var candidate := (safe_scale + unsafe_scale) * 0.5
		if _offsets_are_safe(offsets, candidate):
			safe_scale = candidate
		else:
			unsafe_scale = candidate
	return safe_scale


func _offsets_are_safe(offsets: Dictionary, scale: float) -> bool:
	var pile_rects: Dictionary = {}
	var viewport_rect := get_viewport().get_visible_rect()
	for pile in piles:
		if not is_instance_valid(pile) or pile.completed or not pile.visible:
			continue
		var base: Vector2 = base_positions.get(pile, pile.position)
		var offset: Vector2 = offsets.get(pile, Vector2.ZERO)
		var candidate := base + offset * scale
		var parent_control := pile.get_parent() as Control
		if parent_control != null:
			var parent_transform := parent_control.get_global_transform()
			var first_corner := parent_transform * candidate
			var second_corner := parent_transform * (candidate + pile.size)
			var global_rect := Rect2(
				first_corner,
				second_corner - first_corner
			).abs()
			if not viewport_rect.encloses(global_rect):
				return false
		pile_rects[pile] = Rect2(candidate, pile.size).grow(
			Difficulty.MOVING_PILES_VISUAL_GAP * 0.5
		)
	var checked: Array[MemoryPile] = []
	for pile: MemoryPile in pile_rects:
		for other in checked:
			if (pile_rects[pile] as Rect2).intersects(pile_rects[other] as Rect2):
				return false
		checked.append(pile)
	return true


func stop() -> void:
	if not active:
		return
	active = false
	for pile in piles:
		if is_instance_valid(pile) and base_positions.has(pile):
			pile.position = base_positions[pile]
	piles.clear()
	base_positions.clear()
	orbit_data.clear()
	manually_moving_pile = null
	movement_suspended = false


func permute_paths(
	selected_piles: Array[MemoryPile],
	direction := 1,
	duration := 0.4
) -> void:
	var moving: Array[MemoryPile] = []
	for pile in selected_piles:
		if _can_move(pile):
			moving.append(pile)
	if moving.size() < 2:
		return
	movement_suspended = true
	var destinations: Array[Vector2] = []
	for index in moving.size():
		destinations.append(
			moving[posmod(index + direction, moving.size())].position
		)
	var tween := (
		create_tween()
		.set_parallel(true)
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_IN_OUT)
	)
	for index in moving.size():
		tween.tween_property(moving[index], "position", destinations[index], duration)
	await tween.finished
	if pattern_id == &"orbit":
		var previous_orbits := orbit_data.duplicate(true)
		for index in moving.size():
			var source := moving[posmod(index + direction, moving.size())]
			if previous_orbits.has(source):
				orbit_data[moving[index]] = previous_orbits[source]
	else:
		var previous_bases := base_positions.duplicate()
		for index in moving.size():
			var source := moving[posmod(index + direction, moving.size())]
			base_positions[moving[index]] = previous_bases.get(
				source,
				moving[index].position
			)
	movement_suspended = false
	_process(0.0)


func begin_manual_move(pile: MemoryPile) -> void:
	if active and piles.has(pile):
		manually_moving_pile = pile


func finish_manual_move(pile: MemoryPile) -> void:
	if pile != manually_moving_pile:
		return
	if active and is_instance_valid(pile):
		base_positions[pile] = pile.position
	manually_moving_pile = null
