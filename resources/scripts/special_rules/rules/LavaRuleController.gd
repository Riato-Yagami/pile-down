class_name LavaRuleController
extends Node

const LAVA_ZONE_SCENE := preload("res://resources/scenes/LavaZone.tscn")

signal card_entered_lava(card: PlayingCard)

var zones: Array[LavaZone] = []

const EMPTY_HAND_SAFE_SIZE := Vector2(164.0, 50.0)


func generate(
	_round_number: int,
	piles: Array[MemoryPile],
	hand_area: Control,
	_timer_display: Control,
	lava_layer: Control,
	rng: RandomNumberGenerator
) -> void:
	clear()
	var hand_rect := _control_rect_in_layer(hand_area, lava_layer)
	if hand_rect.size.x < 1.0 or hand_rect.size.y < 1.0:
		hand_rect = Rect2(
			hand_rect.get_center() - EMPTY_HAND_SAFE_SIZE * 0.5,
			EMPTY_HAND_SAFE_SIZE
		)
	var protected_rect := hand_rect
	var pile_rect := Rect2()
	var has_pile := false
	for pile in piles:
		if is_instance_valid(pile):
			var current_pile_rect := _control_rect_in_layer(pile, lava_layer)
			protected_rect = protected_rect.merge(current_pile_rect)
			pile_rect = (
				pile_rect.merge(current_pile_rect)
				if has_pile
				else current_pile_rect
			)
			has_pile = true
	var protrusion_y := -1.0
	if has_pile:
		var gap_top := pile_rect.end.y + 8.0
		var gap_bottom := hand_rect.position.y - 10.0
		if gap_bottom - gap_top >= 12.0:
			protrusion_y = lerpf(gap_top, gap_bottom, 0.72)
	var zone := LAVA_ZONE_SCENE.instantiate() as LavaZone
	zone.configure_boundary(
		lava_layer.size,
		protected_rect,
		protrusion_y,
		rng.randi()
	)
	lava_layer.add_child(zone)
	zone.card_entered_lava.connect(
		func(card: PlayingCard) -> void:
			card_entered_lava.emit(card)
	)
	zones.append(zone)


func touches_card(card: PlayingCard) -> bool:
	if card == null or not is_instance_valid(card):
		return false
	var card_center := card.get_global_transform() * (card.size * 0.5)
	for zone in zones:
		if is_instance_valid(zone) and zone.contains_global_point(card_center):
			return true
	return false


func touches_rect(global_rect: Rect2) -> bool:
	var points: Array[Vector2] = [
		global_rect.get_center(),
		global_rect.position,
		Vector2(global_rect.end.x, global_rect.position.y),
		global_rect.end,
		Vector2(global_rect.position.x, global_rect.end.y),
	]
	for zone in zones:
		if not is_instance_valid(zone):
			continue
		for point in points:
			if zone.contains_global_point(point):
				return true
	return false


func _control_rect_in_layer(control: Control, layer: Control) -> Rect2:
	var global_transform := control.get_global_transform()
	var layer_inverse := layer.get_global_transform().affine_inverse()
	var corners: Array[Vector2] = [
		layer_inverse * (global_transform * Vector2.ZERO),
		layer_inverse * (global_transform * Vector2(control.size.x, 0.0)),
		layer_inverse * (global_transform * control.size),
		layer_inverse * (global_transform * Vector2(0.0, control.size.y)),
	]
	var minimum := corners[0]
	var maximum := corners[0]
	for corner in corners:
		minimum = minimum.min(corner)
		maximum = maximum.max(corner)
	return Rect2(minimum, maximum - minimum)


func clear(animated := false) -> void:
	for zone in zones:
		if not is_instance_valid(zone):
			continue
		zone.enabled = false
		if animated:
			zone.disable_and_fade()
		else:
			zone.queue_free()
	zones.clear()
