class_name DustPool
extends Control

const INFLUENCE_RADIUS := 34.0
const WAVE_SPEED := 150.0
const WAVE_MAX_RADIUS := 110.0

var enabled := true:
	set(value):
		enabled = value
		queue_redraw()
var particles_visible := true:
	set(value):
		particles_visible = value
		queue_redraw()
var debug_visible := false
var viscosity := 2.2
var particle_color := Color("77746d")
var particles: Array[Dictionary] = []
var waves: Array[Dictionary] = []
var _elapsed := 0.0
var _bounds := Vector2.ONE


func setup(
	pool_size: int,
	show_debug: bool,
	material_viscosity := 2.2,
	color := Color("77746d")
) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	debug_visible = show_debug
	viscosity = maxf(material_viscosity, 0.0)
	particle_color = color
	particles.clear()
	waves.clear()
	var bounds := get_viewport_rect().size
	_bounds = bounds
	for index in maxi(pool_size, 0):
		var phase := float(index) * 1.731
		# Two irrational strides give an even, non-grid distribution without
		# allocating or randomizing particles during play.
		var position := Vector2(
			fmod(float(index) * 0.61803398875 + 0.17, 1.0) * bounds.x,
			fmod(float(index) * 0.41421356237 + 0.11, 1.0) * bounds.y
		)
		particles.append({
			"position": position,
			"anchor": position,
			"velocity": Vector2(cos(phase), sin(phase * 1.37)) * 0.45,
			"phase": phase,
			"size": 2.0 if index % 7 == 0 else 1.0,
		})
	set_process(true)
	queue_redraw()


func resize_to_viewport(pool_size: int) -> void:
	setup(pool_size, debug_visible, viscosity, particle_color)


func emit_motion(global_point: Vector2, velocity: Vector2, impulse_scale := 1.0) -> void:
	if not enabled or particles.is_empty() or velocity.length_squared() < 16.0:
		return
	var local_point := get_global_transform().affine_inverse() * global_point
	var radius := INFLUENCE_RADIUS + 6.0 * impulse_scale
	for particle in particles:
		var offset := (particle["position"] as Vector2) - local_point
		var distance := offset.length()
		if distance >= radius:
			continue
		var direction := (
			offset / distance
			if distance > 0.01
			else velocity.normalized().orthogonal()
		)
		var proximity := 1.0 - distance / radius
		particle["velocity"] = (
			particle["velocity"] as Vector2
			+ direction * proximity * 26.0 * impulse_scale
			+ velocity.limit_length(80.0) * 0.08 * proximity * impulse_scale
		).limit_length(38.0)
	queue_redraw()


func emit_wave(global_center: Vector2, influence := 1.0) -> void:
	if not enabled or particles.is_empty() or influence <= 0.0:
		return
	waves.append({
		"center": get_global_transform().affine_inverse() * global_center,
		"radius": 0.0,
		"influence": influence,
	})


func _process(delta: float) -> void:
	_elapsed += delta
	var bounds := get_viewport_rect().size
	for wave in waves:
		var previous_radius := float(wave["radius"])
		var radius := previous_radius + WAVE_SPEED * delta
		var center := wave["center"] as Vector2
		for particle in particles:
			var offset := (particle["position"] as Vector2) - center
			var distance := offset.length()
			if distance <= previous_radius or distance > radius:
				continue
			var direction := offset / maxf(distance, 0.001)
			particle["velocity"] = (
				particle["velocity"] as Vector2
				+ direction * 34.0 * float(wave["influence"])
			).limit_length(42.0)
		wave["radius"] = radius
	for wave_index in range(waves.size() - 1, -1, -1):
		if float(waves[wave_index]["radius"]) >= WAVE_MAX_RADIUS:
			waves.remove_at(wave_index)
	for particle in particles:
		var phase := float(particle["phase"])
		var volatile_offset := Vector2(
			sin(_elapsed * 0.7 + phase),
			cos(_elapsed * 0.53 + phase * 1.41)
		) * 1.5
		var target := (particle["anchor"] as Vector2) + volatile_offset
		var position := particle["position"] as Vector2
		var velocity := particle["velocity"] as Vector2
		velocity += (target - position) * viscosity * delta
		velocity *= exp(-viscosity * 0.65 * delta)
		position += velocity * delta
		position.x = clampf(position.x, 0.0, maxf(bounds.x - 1.0, 0.0))
		position.y = clampf(position.y, 0.0, maxf(bounds.y - 1.0, 0.0))
		particle["position"] = position
		particle["velocity"] = velocity
	if enabled or debug_visible:
		queue_redraw()


func _draw() -> void:
	if not enabled and not debug_visible:
		return
	if particles_visible:
		for particle in particles:
			var phase := float(particle["phase"])
			var color := particle_color
			color.a = 0.18 + (sin(_elapsed * 0.8 + phase) + 1.0) * 0.06
			if not enabled:
				color.a *= 0.25
			var point := (particle["position"] as Vector2).round()
			var particle_size := float(particle["size"])
			draw_rect(Rect2(point, Vector2.ONE * particle_size), color)
	if debug_visible:
		draw_rect(
			Rect2(Vector2(2, 2), Vector2(12, 4)),
			Color(1, 0, 1, 0.7), false
		)
