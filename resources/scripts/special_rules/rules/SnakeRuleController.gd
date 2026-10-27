class_name SnakeRuleController
extends Node

const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")
const ABSORPTION_DURATION := 0.28
const SWALLOW_SEGMENT_DELAY := 0.07
const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

var active := false
var host: GameManager
var cells: Array[Vector2i] = []
var segments: Array[MemoryPile] = []
var card_cells: Dictionary = {}
var columns := 5
var rows := 5
var cell_size := Vector2(44, 44)
var origin := Vector2.ZERO
var elapsed := 0.0
var rng: RandomNumberGenerator
var mistake_pause_remaining := 0.0
var meal_pause_remaining := 0.0
var meal_heal_chance := Difficulty.SNAKE_MEAL_HEAL_CHANCE
var _meal_visuals: Array[Node2D] = []
var _permuting := false
var sliding := false
var _slide_elapsed := 0.0
var _slide_duration := 0.35
var _slide_origins: Dictionary = {}
var _original_z: Dictionary = {}
var _patrol_center := Vector2i(-1, -1)
var _heading := Vector2i.RIGHT


func start(game: GameManager, stream: RandomNumberGenerator) -> void:
	stop()
	host = game
	rng = stream
	if not host.placement_mistake_made.is_connected(pause_after_mistake):
		host.placement_mistake_made.connect(pause_after_mistake)
	host.timer_manager.countdown_restarted.connect(_freeze_after_meal)
	host.special_rule_manager.piles_swap_started.connect(_prepare_pile_swap)
	host.special_rule_manager.piles_swapped.connect(_finish_pile_swap)
	segments.assign(game.piles)
	_configure_grid()
	var path: Array[Vector2i] = []
	for y in rows:
		for x in columns:
			path.append(Vector2i(x if y % 2 == 0 else columns - 1 - x, y))
	for index in segments.size():
		cells.append(path[segments.size() - 1 - index])
	for pile in segments:
		_original_z[pile] = pile.z_index
	active = true
	_place_segments()
	_raise_head()


func stop() -> void:
	if is_instance_valid(host):
		if host.special_rule_manager.piles_swap_started.is_connected(_prepare_pile_swap):
			host.special_rule_manager.piles_swap_started.disconnect(_prepare_pile_swap)
		if host.special_rule_manager.piles_swapped.is_connected(_finish_pile_swap):
			host.special_rule_manager.piles_swapped.disconnect(_finish_pile_swap)
	_permuting = false
	if is_instance_valid(host) and host.placement_mistake_made.is_connected(pause_after_mistake):
		host.placement_mistake_made.disconnect(pause_after_mistake)
	if is_instance_valid(host) and host.timer_manager.countdown_restarted.is_connected(_freeze_after_meal):
		host.timer_manager.countdown_restarted.disconnect(_freeze_after_meal)
	for visual in _meal_visuals:
		if is_instance_valid(visual):
			visual.queue_free()
	_meal_visuals.clear()
	meal_pause_remaining = 0.0
	active = false
	mistake_pause_remaining = 0.0
	sliding = false
	_slide_origins.clear()
	for pile: MemoryPile in _original_z:
		if is_instance_valid(pile):
			pile.z_index = _original_z[pile]
			pile.stop_swallow_pulse()
	_original_z.clear()
	_patrol_center = Vector2i(-1, -1)
	_heading = Vector2i.RIGHT
	elapsed = 0.0
	cells.clear()
	segments.clear()
	card_cells.clear()
	host = null


func _configure_grid() -> void:
	# Leave enough free squares even at the actual 25-pile difficulty cap.
	var capacity := segments.size() + host.hand_size + 4
	columns = maxi(5, ceili(sqrt(float(capacity))))
	rows = maxi(5, ceili(float(capacity) / columns))
	cell_size = Vector2(
		minf(Difficulty.SNAKE_CELL_SIZE, (host.size.x - 16.0) / columns),
		minf(Difficulty.SNAKE_CELL_SIZE, (host.size.y - 64.0) / rows)
	)
	origin = Vector2((host.size.x - columns * cell_size.x) * 0.5, 56)


func _position(cell: Vector2i) -> Vector2:
	return origin + Vector2(cell) * cell_size + (cell_size - Vector2(34, 37)) * 0.5


func _global_position(cell: Vector2i) -> Vector2:
	return host.get_global_transform() * _position(cell)


func _place_segments() -> void:
	for index in segments.size():
		var pile := segments[index]
		if is_instance_valid(pile) and not pile.completed:
			_set_pile_grid_position(pile, _global_position(cells[index]))


func _pile_grid_position(pile: MemoryPile) -> Vector2:
	# Control.global_position includes pivot compensation during value flips.
	# The grid follows the layout position, independently of that visual scale.
	return pile.get_parent().get_global_transform() * pile.position


func _set_pile_grid_position(pile: MemoryPile, destination: Vector2) -> void:
	pile.position = pile.get_parent().get_global_transform().affine_inverse() * destination


func place_hand() -> void:
	if not active:
		return
	card_cells.clear()
	for card in host.hand_manager.current_cards:
		if is_instance_valid(card):
			_respawn(card)


func _free_cells(excluded := Vector2i(-1, -1)) -> Array[Vector2i]:
	var free: Array[Vector2i] = []
	for y in rows:
		for x in columns:
			var cell := Vector2i(x, y)
			if cell != excluded and not cells.has(cell) and not card_cells.values().has(cell) and not _cell_overlaps_snake(cell):
				free.append(cell)
	return free


func _tile_rect(tile: Control) -> Rect2:
	# get_global_rect decomposes reflected scales ambiguously; transform all
	# corners instead so both mirror axes describe the actual occupied area.
	return (tile.get_global_transform() * Rect2(Vector2.ZERO, tile.size)).abs()


func _cell_overlaps_snake(cell: Vector2i) -> bool:
	var tile_rect := (host.get_global_transform() * Rect2(_position(cell), Vector2(34, 37))).abs()
	for index in segments.size():
		var pile := segments[index]
		if not is_instance_valid(pile) or pile.completed:
			continue
		var occupied := _tile_rect(pile)
		if sliding and _slide_origins.has(pile):
			# Reserve the whole slide, including the tail's departing square.
			var grid_rect := host.get_global_transform() * Rect2(_position(cells[index]), Vector2(34, 37))
			occupied = occupied.merge(grid_rect.abs())
			grid_rect.position += (_slide_origins[pile] as Vector2) - _global_position(cells[index])
			occupied = occupied.merge(grid_rect.abs())
		if tile_rect.intersects(occupied):
			return true
	return false


func _respawn(card: PlayingCard, excluded := Vector2i(-1, -1)) -> void:
	var free := _free_cells(excluded)
	if free.is_empty():
		return
	# Prefer the far half of the available board, retaining seeded variety.
	var head_center := _tile_rect(segments[0]).get_center()
	var max_distance := 0.0
	for candidate in free:
		max_distance = maxf(max_distance, _global_position(candidate).distance_to(head_center))
	var distant: Array[Vector2i] = []
	for candidate in free:
		if _global_position(candidate).distance_to(head_center) >= max_distance * 0.7:
			distant.append(candidate)
	var cell := distant[rng.randi_range(0, distant.size() - 1)]
	card_cells[card] = cell
	card.disable_wandering()
	card.global_position = _global_position(cell)
	card.record_hand_position()
	CardAnimations.play_snake_entrance(card)


func _can_eat(card: PlayingCard) -> bool:
	return (
		is_instance_valid(card) and host.hand_manager.current_cards.has(card)
		and card.visible and not card.dragging and not card.is_discarding
		and not card._entrance_animation_running and card.drag_state == card.DragState.IDLE
		and card != host.selected_card
		and not host.drag_companions.has(card)
	)


func pause_after_mistake() -> void:
	mistake_pause_remaining = maxf(mistake_pause_remaining, Difficulty.SNAKE_MISTAKE_PAUSE_DURATION)


func _process(delta: float) -> void:
	meal_pause_remaining = maxf(0.0, meal_pause_remaining - delta)
	if active and mistake_pause_remaining > 0.0:
		mistake_pause_remaining = maxf(0.0, mistake_pause_remaining - delta)
		return
	if _permuting or not active or not is_instance_valid(host) or host.input_locked or not host.gameplay_layer.visible or not host.timer_manager.running:
		return
	_consume_at_head()
	elapsed += delta
	if sliding:
		_advance_slide(delta)
	var interval := Difficulty.SNAKE_STEP_DURATION / maxf(host.round_modifiers.special_rule_intensity_multiplier, 0.1)
	if elapsed >= interval and not sliding:
		elapsed = fmod(elapsed, interval)
		step()


func _prepare_pile_swap() -> void:
	_permuting = true
	# Finish the grid movement before Shell Game captures its destinations.
	sliding = false
	_slide_origins.clear()
	_place_segments()


func _finish_pile_swap(moving: Array[MemoryPile]) -> void:
	var previous := segments.duplicate()
	for index in moving.size():
		var destination_slot := previous.find(moving[(index + 1) % moving.size()])
		if destination_slot >= 0:
			segments[destination_slot] = moving[index]
	# Cells describe the continuous body path; only their occupants change.
	_permuting = false
	elapsed = 0.0
	_raise_head()


func _raise_head() -> void:
	for pile: MemoryPile in _original_z:
		if is_instance_valid(pile):
			pile.z_index = _original_z[pile]
	if not segments.is_empty() and is_instance_valid(segments[0]):
		segments[0].z_index = 20


func step() -> void:
	if not active or _permuting or cells.is_empty() or sliding:
		return
	# Remove finished ends. Internal gaps retain their path slot so the next
	# segment never jumps across another segment while closing the gap.
	while not segments.is_empty() and (not is_instance_valid(segments[0]) or segments[0].completed):
		segments.pop_front()
		cells.pop_front()
	while not segments.is_empty() and (not is_instance_valid(_last_segment()) or _last_segment().completed):
		segments.pop_back()
		cells.pop_back()
	if cells.is_empty():
		return
	for card: PlayingCard in card_cells.keys():
		if not is_instance_valid(card) or not host.hand_manager.current_cards.has(card):
			card_cells.erase(card)
	var next := _next_cell()
	if next == cells[0]:
		return
	_heading = next - cells[0]
	_slide_origins.clear()
	for pile in segments:
		if is_instance_valid(pile) and not pile.completed:
			_slide_origins[pile] = _pile_grid_position(pile)
	cells.push_front(next)
	cells.pop_back()
	_slide_elapsed = 0.0
	_slide_duration = minf(
		Difficulty.SNAKE_SLIDE_DURATION,
		Difficulty.SNAKE_STEP_DURATION * 0.8
	) / maxf(host.round_modifiers.special_rule_intensity_multiplier, 0.1)
	sliding = true
	_raise_head()


func _last_segment() -> MemoryPile:
	return segments.back()


func _advance_slide(delta: float) -> void:
	if not sliding:
		return
	_slide_elapsed += delta
	var progress := clampf(_slide_elapsed / maxf(_slide_duration, 0.001), 0, 1)
	var eased := smoothstep(0.0, 1.0, progress)
	for index in segments.size():
		var pile := segments[index]
		if is_instance_valid(pile) and not pile.completed and _slide_origins.has(pile):
			_set_pile_grid_position(pile, (_slide_origins[pile] as Vector2).lerp(_global_position(cells[index]), eased))
	_consume_at_head()
	if progress >= 1.0:
		sliding = false
		_slide_origins.clear()


func _next_cell() -> Vector2i:
	var targets: Array[Vector2i] = []
	var held_targets: Array[Vector2i] = []
	for card: PlayingCard in card_cells:
		if _can_eat(card):
			targets.append(card_cells[card])
		elif is_instance_valid(card) and host.hand_manager.current_cards.has(card) and not card.is_discarding:
			held_targets.append(card_cells[card])
	if not targets.is_empty():
		_patrol_center = Vector2i(-1, -1)
		var found := _path_step(targets)
		if found != cells[0]:
			return found
	elif not held_targets.is_empty():
		if held_targets.has(cells[0]):
			_patrol_center = cells[0]
		if held_targets.has(_patrol_center):
			var ring := _patrol_ring(_patrol_center)
			var index := ring.find(cells[0])
			var next_targets: Array[Vector2i] = []
			if index >= 0:
				next_targets.append(ring[(index + 1) % ring.size()])
			else:
				next_targets.assign(ring)
			var found := _path_step(next_targets)
			if found != cells[0]:
				return found
		else:
			var found := _path_step(held_targets)
			if found != cells[0]:
				return found
	# Respect every occupied cell, including the tail's departing square.
	for direction in [_heading, Vector2i(-_heading.y, _heading.x), Vector2i(_heading.y, -_heading.x), -_heading]:
		if _allowed(cells[0] + direction):
			return cells[0] + direction
	return cells[0]


func _patrol_ring(center: Vector2i) -> Array[Vector2i]:
	var ring: Array[Vector2i] = []
	var radius := 1
	while radius < maxi(columns, rows):
		var left := maxi(0, center.x - radius)
		var right := mini(columns - 1, center.x + radius)
		var top := maxi(0, center.y - radius)
		var bottom := mini(rows - 1, center.y + radius)
		ring.clear()
		for x in range(left, right + 1):
			ring.append(Vector2i(x, top))
		for y in range(top + 1, bottom + 1):
			ring.append(Vector2i(right, y))
		for x in range(right - 1, left - 1, -1):
			ring.append(Vector2i(x, bottom))
		for y in range(bottom - 1, top, -1):
			ring.append(Vector2i(left, y))
		if ring.size() > cells.size() + 1:
			break
		radius += 1
	return ring


func _path_step(targets: Array[Vector2i]) -> Vector2i:
	var head := cells[0]
	var frontier: Array[Vector2i] = [head]
	var previous: Dictionary = {head: head}
	var cursor := 0
	while cursor < frontier.size():
		var cell := frontier[cursor]
		cursor += 1
		if cell != head and targets.has(cell):
			while previous[cell] != head:
				cell = previous[cell]
			return cell
		for direction in DIRECTIONS:
			var neighbor := cell + direction
			if _allowed(neighbor) and not previous.has(neighbor):
				previous[neighbor] = cell
				frontier.append(neighbor)
	return head


func _allowed(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < columns and cell.y < rows and not cells.has(cell)


func _consume_at_head() -> void:
	if meal_pause_remaining > 0.0:
		return
	if segments.is_empty() or not is_instance_valid(segments[0]) or segments[0].completed:
		return
	var head_rect := _tile_rect(segments[0])
	for card: PlayingCard in card_cells.keys():
		if _can_eat(card) and head_rect.has_point(_tile_rect(card).get_center()):
			_eat(card)
			break


func try_release_card(card: PlayingCard, target: MemoryPile) -> bool:
	# A real pile drop must retain normal success/error feedback. Only a tile
	# released over the body outside a pile hitbox can become loose food.
	if not active or card.is_discarding or target != null:
		return false
	var dropped_on_snake := false
	for pile in segments:
		if is_instance_valid(pile) and not pile.completed and _tile_rect(pile).intersects(_tile_rect(card).grow(-6)):
			dropped_on_snake = true
			break
	if not dropped_on_snake:
		return false
	card.finish_drag()
	card.end_commit()
	card.reset_hand_pose()
	var local_center := host.get_global_transform().affine_inverse() * _tile_rect(card).get_center()
	var cell := Vector2i((local_center - origin) / cell_size)
	cell.x = clampi(cell.x, 0, columns - 1)
	cell.y = clampi(cell.y, 0, rows - 1)
	card_cells[card] = cell
	card.global_position = _global_position(cell)
	card.record_hand_position()
	host.selected_card = null
	host.hand_manager.clear_selection()
	host.hand_manager.unlock_hand()
	card.set_selectable(true)
	_raise_head()
	_consume_at_head()
	return true


func _eat(card: PlayingCard) -> void:
	var heal_target: MemoryPile
	if rng.randf() < meal_heal_chance:
		for index in range(segments.size() - 1, -1, -1):
			var pile := segments[index]
			# Select without healing: the point arrives with the swallowed tile.
			if is_instance_valid(pile) and not pile.completed and pile._can_regenerate():
				heal_target = pile
				break
	var digestion_duration := _animate_meal(card, heal_target)
	# Let the wave finish even on long snakes before another meal can replace it.
	meal_pause_remaining = maxf(Difficulty.SNAKE_MEAL_PAUSE_DURATION, digestion_duration)
	_freeze_after_meal()
	var old_cell: Vector2i = card_cells[card]
	card_cells.erase(card)
	_respawn(card, old_cell)


func _heal_swallowed_segment(pile: MemoryPile) -> void:
	if active and is_instance_valid(pile) and segments.has(pile):
		pile.regenerate_once()


func _freeze_after_meal() -> void:
	if meal_pause_remaining > 0.0:
		host.timer_manager.freeze_countdown(meal_pause_remaining)


func _animate_meal(card: PlayingCard, heal_target: MemoryPile = null) -> float:
	# A zero-sized carrier makes the visual's center the scale origin even when
	# its copied Control children recompute their minimum size after parenting.
	var carrier := Node2D.new()
	host.drag_layer.add_child(carrier)
	carrier.global_position = card.get_global_transform() * (card.size * 0.5)
	carrier.z_index = -1
	var visual := card.get_node("VisualRoot").duplicate(Node.DUPLICATE_SCRIPTS) as Control
	carrier.add_child(visual)
	visual.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	visual.size = card.size
	visual.position = -card.size * 0.5
	visual.scale = Vector2.ONE
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in visual.find_children("*", "Control", true, false):
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meal_visuals.append(carrier)
	var head := segments[0]
	var start_center := carrier.global_position
	var tween := carrier.create_tween()
	tween.tween_method(_update_absorption.bind(carrier, start_center, head), 0.0, 1.0, ABSORPTION_DURATION)
	tween.tween_callback(func() -> void:
		_meal_visuals.erase(carrier)
		carrier.queue_free()
	)
	var delay := ABSORPTION_DURATION
	for pile in segments:
		if is_instance_valid(pile) and not pile.completed:
			var on_swallowed := _heal_swallowed_segment.bind(pile) if pile == heal_target else Callable()
			pile.play_swallow_pulse(delay, on_swallowed)
			if pile == heal_target:
				return delay + 0.29
			delay += SWALLOW_SEGMENT_DELAY
	return maxf(ABSORPTION_DURATION, delay - SWALLOW_SEGMENT_DELAY + 0.29)


func _update_absorption(progress: float, carrier: Node2D, start_center: Vector2, head: MemoryPile) -> void:
	var eased := smoothstep(0.0, 1.0, progress)
	carrier.scale = Vector2.ONE * lerpf(1.0, 0.5, eased)
	if is_instance_valid(head):
		# Follow the moving head so the shrinking tile cannot emerge behind it.
		var head_center := head.get_global_transform() * (head.size * 0.5)
		carrier.global_position = start_center.lerp(head_center, eased)
	carrier.modulate.a = 1.0 - smoothstep(0.45, 1.0, progress)
