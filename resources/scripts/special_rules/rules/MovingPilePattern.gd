class_name MovingPilePattern
extends Node

const PATTERN_COUNT := 6

var active := false
var elapsed := 0.0
var piles: Array[MemoryPile] = []
var base_positions: Dictionary = {}
var pattern_index := 0
var speed_multiplier := 1.0


func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	for index in piles.size():
		var pile := piles[index]
		if not is_instance_valid(pile) or pile.completed:
			continue
		var base: Vector2 = base_positions.get(pile, pile.position)
		var phase := (
			elapsed * 0.8 * speed_multiplier
			+ float(index) * TAU / maxf(piles.size(), 1)
		)
		var offset := Vector2.ZERO
		match pattern_index:
			0:
				# Elliptical carousel.
				offset = Vector2(cos(phase) * 9.0, sin(phase) * 5.0)
			1:
				# Alternating horizontal pendulum.
				offset = Vector2(sin(phase) * 12.0, 0.0)
			2:
				# Figure eight.
				offset = Vector2(sin(phase) * 10.0, sin(phase * 2.0) * 5.0)
			3:
				# One central pile with alternating concentric orbits.
				if index > 0:
					var orbit_direction := 1.0 if index % 2 == 0 else -1.0
					var orbit_radius := 5.0 + float((index - 1) % 3) * 2.0
					offset = Vector2(
						cos(phase * orbit_direction) * orbit_radius,
						sin(phase * orbit_direction) * orbit_radius
					)
			4:
				# Vertical stadium wave.
				offset = Vector2(
					sin(phase * 0.5) * 3.0,
					sin(phase) * (4.0 + float(index % 2) * 3.0)
				)
			5:
				# Regular movement through four fixed corner points.
				offset = _square_path(fposmod(phase / TAU, 1.0), Vector2(8.0, 5.0))
		pile.position = (base + offset).round()


func start(
	round_piles: Array[MemoryPile],
	round_number: int,
	movement_speed_multiplier := 1.0
) -> void:
	active = true
	elapsed = 0.0
	speed_multiplier = movement_speed_multiplier
	pattern_index = round_number % PATTERN_COUNT
	piles.assign(round_piles)
	base_positions.clear()
	for pile in piles:
		base_positions[pile] = pile.position


func stop() -> void:
	if not active:
		return
	active = false
	var longest_tween: Tween
	for pile in piles:
		if not is_instance_valid(pile) or not base_positions.has(pile):
			continue
		var tween := pile.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(pile, "position", base_positions[pile], 0.25)
		longest_tween = tween
	if longest_tween != null:
		await longest_tween.finished
	piles.clear()
	base_positions.clear()


func _square_path(progress: float, extent: Vector2) -> Vector2:
	var segment := progress * 4.0
	if segment < 1.0:
		return Vector2(lerpf(-extent.x, extent.x, segment), -extent.y)
	if segment < 2.0:
		return Vector2(extent.x, lerpf(-extent.y, extent.y, segment - 1.0))
	if segment < 3.0:
		return Vector2(lerpf(extent.x, -extent.x, segment - 2.0), extent.y)
	return Vector2(-extent.x, lerpf(extent.y, -extent.y, segment - 3.0))
