extends SceneTree

const DustPoolScript := preload("res://resources/scripts/effects/DustPool.gd")
const StripeBackgroundScript := preload(
	"res://resources/scripts/effects/DeformableStripeBackground.gd"
)
const StripeMaterial := preload(
	"res://resources/materials/StripeBackgroundMaterial.tres"
)
const DeformationMaterial := preload(
	"res://resources/materials/DeformableBackgroundMaterial.tres"
)
const LitButtonTexture := preload(
	"res://resources/materials/textures/ui/buttons/button.tres"
)
const LitPanelTexture := preload(
	"res://resources/materials/textures/ui/panels/pop-up.tres"
)
const LitHandTexture := preload(
	"res://resources/materials/textures/hand/hand-background.tres"
)
const PileScene := preload("res://resources/scenes/gameplay/Pile.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(StripeMaterial is ShaderMaterial)
	assert(DeformationMaterial is ShaderMaterial)
	for lit_texture in [LitButtonTexture, LitPanelTexture, LitHandTexture]:
		assert(lit_texture is CanvasTexture)
		assert((lit_texture as CanvasTexture).diffuse_texture != null)
		assert((lit_texture as CanvasTexture).normal_texture != null)
		assert(
			(lit_texture as CanvasTexture).diffuse_texture.get_size()
			== (lit_texture as CanvasTexture).normal_texture.get_size()
		)
		assert(_has_normal_variation(
			(lit_texture as CanvasTexture).normal_texture
		))
	assert(StripeMaterial.shader != DeformationMaterial.shader)
	assert(float(StripeMaterial.get_shader_parameter("effect_enabled")) > 0.0)
	assert(float(StripeMaterial.get_shader_parameter("pixel_size")) >= 1.0)
	assert(float(DeformationMaterial.get_shader_parameter("pixel_size")) >= 1.0)
	var stripe_scroll_speed := float(
		StripeMaterial.get_shader_parameter("stripe_scroll_speed")
	)
	assert(stripe_scroll_speed >= -1.0 and stripe_scroll_speed <= 1.0)
	assert((StripeMaterial.get_shader_parameter("stripe_color") as Color).a > 0.0)
	var control := Control.new()
	control.set_script(DustPoolScript)
	var pool := control as DustPool
	root.add_child(pool)
	pool.setup(4, true, 3.0, Color.RED)
	assert(pool.particles.size() == 4)
	assert(is_equal_approx(pool.viscosity, 3.0))
	assert(pool.particle_color == Color.RED)
	pool.setup(12, true)
	assert(pool.particles.size() == 12)
	assert(pool.debug_visible)
	assert(DebugSettings.is_dust_debug_visible() == (
		DebugSettings.ENABLED and DebugSettings.SHOW_DUST_DEBUG
	))
	for particle in pool.particles:
		assert((particle["position"] as Vector2) != Vector2.ZERO)
	var influenced := pool.particles[0]
	var anchor := influenced["anchor"] as Vector2
	var velocity_before := influenced["velocity"] as Vector2
	pool.emit_motion(
		influenced["position"] as Vector2, Vector2(100, 0), 1.0
	)
	assert(not (influenced["velocity"] as Vector2).is_equal_approx(velocity_before))
	influenced["position"] = anchor + Vector2(20, 0)
	influenced["velocity"] = Vector2.ZERO
	pool._process(0.1)
	assert((influenced["velocity"] as Vector2).x < 0.0)
	pool.emit_wave(anchor, 1.0)
	assert(pool.waves.size() == 1)
	pool.enabled = false
	velocity_before = influenced["velocity"] as Vector2
	pool.emit_motion(Vector2(30, 20), Vector2(100, 0), 1.0)
	assert((influenced["velocity"] as Vector2).is_equal_approx(velocity_before))
	pool.setup(0, false)
	assert(pool.particles.is_empty())
	pool.queue_free()
	var stripe_control := Control.new()
	stripe_control.set_script(StripeBackgroundScript)
	var stripe_background := stripe_control as DeformableStripeBackground
	var background_texture := ColorRect.new()
	background_texture.name = "BackgroundArt"
	background_texture.material = StripeMaterial.duplicate() as ShaderMaterial
	stripe_background.add_child(background_texture)
	var deformation_overlay := ColorRect.new()
	deformation_overlay.name = "DeformationOverlay"
	stripe_background.add_child(deformation_overlay)
	root.add_child(stripe_background)
	stripe_background.effect_speed = 0.5
	(background_texture.material as ShaderMaterial).set_shader_parameter(
		"stripe_scroll_speed", -0.125
	)
	stripe_background.setup()
	assert(is_equal_approx(float(
		(background_texture.material as ShaderMaterial).get_shader_parameter(
			"pixel_size"
		)
	), stripe_background.background_pixel_size))
	assert(is_equal_approx(float(
		(deformation_overlay.material as ShaderMaterial).get_shader_parameter(
			"pixel_size"
		)
	), stripe_background.background_pixel_size))
	assert(is_equal_approx(
		float((background_texture.material as ShaderMaterial).get_shader_parameter(
			"stripe_scroll_speed"
		)),
		-0.125
	))
	var resting_tile := Control.new()
	resting_tile.position = Vector2(12, 18)
	resting_tile.size = Vector2(34, 37)
	stripe_background.add_child(resting_tile)
	var dragged_tile := Control.new()
	dragged_tile.position = Vector2(70, 24)
	dragged_tile.size = Vector2(34, 37)
	stripe_background.add_child(dragged_tile)
	stripe_background.set_tile_weights(
		[resting_tile, dragged_tile],
		dragged_tile,
		{
			resting_tile.get_instance_id(): 1.4,
			dragged_tile.get_instance_id(): 0.65,
		}
	)
	var tile_weights := (
		(deformation_overlay.material as ShaderMaterial).get_shader_parameter(
			"tile_weights"
		) as PackedVector4Array
	)
	assert(tile_weights.size() == stripe_background.MAX_TILE_WEIGHTS)
	assert(tile_weights[0].w > 0.0)
	assert(tile_weights[0].w > stripe_background.tile_weight_strength)
	assert(tile_weights[1].w > stripe_background.tile_weight_strength)
	var tile_shapes := (
		(deformation_overlay.material as ShaderMaterial).get_shader_parameter(
			"tile_weight_shapes"
		) as PackedVector4Array
	)
	assert(tile_shapes.size() == stripe_background.MAX_TILE_WEIGHTS)
	assert(tile_shapes[0].x == resting_tile.size.x * 0.5)
	assert(tile_shapes[0].y == resting_tile.size.y * 0.5)
	assert(tile_shapes[0].z > 0.0)
	stripe_background.emit_motion(
		Vector2(30, 20), Vector2(100, 0), 1.0
	)
	assert(stripe_background.impulses.size() == 1)
	assert((stripe_background.impulses[0]["direction"] as Vector2).x > 0.0)
	stripe_background.emit_wave(Vector2(30, 20), 1.0)
	assert(stripe_background.impulses.size() == 2)
	assert(bool(stripe_background.impulses[1]["wave"]))
	assert(bool(stripe_background.impulses[1]["full_viewport_wave"]))
	assert(
		float(stripe_background.impulses[1]["exit_radius"])
		> Vector2(30, 20).distance_to(stripe_background.size)
	)
	var wave := stripe_background.impulses[1]
	stripe_background.emit_tile_impact_wave(Vector2(42, 28))
	var impact_wave: Dictionary = stripe_background.impulses.back()
	assert(bool(impact_wave["wave"]))
	assert(not bool(impact_wave["full_viewport_wave"]))
	assert(float(impact_wave["lifetime"]) < 0.3)
	for impulse_index in range(stripe_background.MAX_IMPULSES * 2):
		stripe_background.emit_motion(
			Vector2(20 + impulse_index, 20), Vector2(100, 0), 1.0
		)
	assert(stripe_background.impulses.has(wave))
	var initial_wave_radius := float(wave["radius"])
	stripe_background._process(0.1)
	assert(is_equal_approx(
		float(wave["radius"]),
		initial_wave_radius + stripe_background.wave_speed * 0.05
	))
	assert(float(wave["current_strength"]) > 10.0)
	stripe_background.enabled = false
	assert(is_zero_approx(float(
		(deformation_overlay.material as ShaderMaterial).get_shader_parameter(
			"effect_enabled"
		)
	)))
	assert(float(
		(background_texture.material as ShaderMaterial).get_shader_parameter(
			"effect_enabled"
		)
	) > 0.0)
	stripe_background.emit_motion(
		Vector2(30, 20), Vector2(100, 0), 1.0
	)
	assert(stripe_background.impulses.has(wave))
	stripe_background.queue_free()
	var pile := PileScene.instantiate() as MemoryPile
	root.add_child(pile)
	pile.setup(0, 1)
	var pile_material := pile.face_sprite.material as ShaderMaterial
	assert(is_zero_approx(float(
		pile_material.get_shader_parameter("completion_morph")
	)))
	await pile.complete_animation()
	assert(pile.completed)
	assert(not pile.visible)
	assert(is_zero_approx(pile.background_weight))
	assert(is_equal_approx(float(
		pile_material.get_shader_parameter("completion_morph")
	), 1.0))
	pile.queue_free()
	var fading_pile := PileScene.instantiate() as MemoryPile
	root.add_child(fading_pile)
	fading_pile.setup(0, 1)
	var fading_material := fading_pile.face_sprite.material as ShaderMaterial
	await fading_pile.complete_animation(false)
	assert(fading_pile.completed)
	assert(not fading_pile.visible)
	assert(is_zero_approx(float(
		fading_material.get_shader_parameter("completion_morph")
	)))
	assert(is_zero_approx(fading_pile.modulate.a))
	fading_pile.queue_free()
	await process_frame
	print("Visual effects test passed.")
	quit()


func _has_normal_variation(texture: Texture2D) -> bool:
	var image := texture.get_image()
	if image == null or image.is_empty():
		return false
	var first := image.get_pixel(0, 0)
	for y in range(0, image.get_height(), maxi(image.get_height() / 12, 1)):
		for x in range(0, image.get_width(), maxi(image.get_width() / 12, 1)):
			var sample := image.get_pixel(x, y)
			if Vector3(sample.r, sample.g, sample.b).distance_to(
				Vector3(first.r, first.g, first.b)
			) > 0.02:
				return true
	return false
