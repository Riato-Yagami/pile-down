class_name GameTransitions
extends RefCounted

## Menu, replay iris and result-screen animations.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func mask_replay_transition(host: GameManager) -> void:
	host.replay_transition_mask.visible = true
	host.replay_transition_mask.mouse_filter = Control.MOUSE_FILTER_STOP
	host.replay_transition_mask.modulate.a = 1.0
	var mask_size := host.replay_transition_mask.size
	var center := host.replay_transition_mask.get_local_mouse_position().clamp(
		Vector2.ZERO, mask_size
	)
	var material := host.replay_transition_mask.material as ShaderMaterial
	var center_uv := Vector2(center.x / mask_size.x, center.y / mask_size.y)
	var aspect_ratio := mask_size.x / mask_size.y
	material.set_shader_parameter(&"center_uv", center_uv)
	material.set_shader_parameter(&"aspect_ratio", aspect_ratio)
	host._replay_iris_radius = host._maximum_iris_radius(center_uv, aspect_ratio) + 0.02
	material.set_shader_parameter(&"radius", host._replay_iris_radius)
	var tween := host.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(
		material, "shader_parameter/radius", 0.0, host.replay_mask_duration
	)
	await tween.finished


static func unmask_replay_transition(host: GameManager) -> void:
	var material := host.replay_transition_mask.material as ShaderMaterial
	var tween := host.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		material,
		"shader_parameter/radius",
		host._replay_iris_radius,
		host.replay_mask_duration
	)
	await tween.finished
	host.replay_transition_mask.visible = false
	host.replay_transition_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE


static func maximum_iris_radius(
	host: GameManager, center_uv: Vector2, aspect_ratio: float
) -> float:
	var top_left := (Vector2.ZERO - center_uv) * Vector2(aspect_ratio, 1.0)
	var top_right := (Vector2.RIGHT - center_uv) * Vector2(aspect_ratio, 1.0)
	var bottom_left := (Vector2.DOWN - center_uv) * Vector2(aspect_ratio, 1.0)
	var bottom_right := (Vector2.ONE - center_uv) * Vector2(aspect_ratio, 1.0)
	return maxf(
		maxf(top_left.length(), top_right.length()),
		maxf(bottom_left.length(), bottom_right.length())
	)


static func play_return_to_menu_transition(host: GameManager) -> void:
	# Screens also inherits the game container's offset after a window resize.
	# Convert its origin into the transition layer instead of losing that offset.
	var splash_destination := (
		host.menu_transition_layer.get_final_transform().affine_inverse()
		* host.screens.get_global_transform_with_canvas().origin
	)
	host.splash.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	# Keep the centered menu rect while its background covers the wider canvas.
	# Changing its width here moves right-anchored icons until reparenting ends.
	host.splash.size = host.screens.size
	host.splash.position = splash_destination + Vector2(0.0, host._canvas_size().y + 2.0)
	host._prepare_splash_transition_layout()
	host.splash.visible = true
	# Commit the off-screen placement before starting the tween. This prevents a
	# single frame at the old position when Splash has just changed CanvasLayer.
	await host.get_tree().process_frame
	host._prepare_splash_transition_layout()
	var tween := host.create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		host.splash, "position:y", splash_destination.y, host.menu_swipe_duration
	)
	for element in host._start_transition_elements():
		element.pivot_offset = element.size * 0.5
		tween.tween_property(
			element, "modulate:a", 0.0, host.gameplay_pop_duration
		)
		tween.tween_property(
			element,
			"scale",
			Vector2.ONE * host.gameplay_pop_scale,
			host.gameplay_pop_duration
		)
	await tween.finished


static func prepare_gameplay_start_reveal(host: GameManager) -> void:
	if is_instance_valid(host.background_effects):
		host.background_effects.set_base_pattern_enabled(host._background_enabled)
	if is_instance_valid(host.background_manager):
		host.background_manager.set_enabled(host._background_enabled)
	# During the transition, keep ESC behind the sliding splash like the other
	# gameplay elements. Its interactive z-index is restored once gameplay owns
	# the screen.
	host.back_button.visible = true
	host.back_button.z_index = 0
	for element in host._start_transition_elements():
		element.pivot_offset = element.size * 0.5
		element.modulate.a = 0.0
		element.scale = Vector2.ONE * host.gameplay_pop_scale


static func play_start_game_transition(host: GameManager) -> void:
	if host._menu_exit_tween != null and host._menu_exit_tween.is_valid():
		host._menu_exit_tween.kill()
	var splash_origin := host.splash.position
	host._menu_exit_tween = (
		host.create_tween()
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_IN)
	)
	host._menu_exit_tween.tween_property(
		host.splash,
		"position:y",
		splash_origin.y + host.size.y + 8.0,
		host.menu_swipe_duration
	)
	var elements := host._start_transition_elements()
	for index in elements.size():
		var element := elements[index]
		var reveal := (
			element.create_tween()
			.set_parallel()
			.set_trans(Tween.TRANS_BACK)
			.set_ease(Tween.EASE_OUT)
		)
		reveal.tween_property(
			element,
			"modulate:a",
			1.0,
			host.gameplay_pop_duration
		).set_delay(index * host.gameplay_pop_stagger)
		reveal.tween_property(
			element,
			"scale",
			Vector2.ONE,
			host.gameplay_pop_duration
		).set_delay(index * host.gameplay_pop_stagger)
	await host._menu_exit_tween.finished
	host.splash.visible = false
	host.splash.position = splash_origin
	host.back_button.visible = true
	host.back_button.z_index = 10


static func start_transition_elements(host: GameManager) -> Array[Control]:
	return [host.timer_ring, host.round_panel, host.back_button, host.piles_board, host.hand_tray]


static func restore_gameplay_transition_elements(host: GameManager) -> void:
	# Checkpoint starts do not use the ordinary menu-exit animation. Restore the
	# controls faded by the preceding quit transition before revealing gameplay.
	for element in host._start_transition_elements():
		element.modulate.a = 1.0
		element.scale = Vector2.ONE
	host.back_button.z_index = 10


static func show_game_over_overlay(host: GameManager, animate_death: bool) -> void:
	host._fit_overlay_to_canvas()
	host.back_button.visible = false
	host.overlay.visible = true
	host.overlay_scrim.modulate.a = 1.0
	host.overlay_panel.modulate.a = 1.0
	host.overlay_panel.scale = Vector2.ONE
	if not animate_death:
		return
	host.overlay_scrim.modulate.a = 0.0
	host.overlay_panel.modulate.a = 0.0
	host.overlay_panel.scale = Vector2(0.42, 0.42)
	host.overlay_panel.pivot_offset = host.overlay_panel.size * 0.5
	var tween := host.create_tween().set_parallel(true)
	tween.tween_property(host.overlay_scrim, "modulate:a", 1.0, 0.18)
	tween.tween_property(host.overlay_panel, "modulate:a", 1.0, 0.12)
	tween.tween_property(
		host.overlay_panel,
		"scale",
		Vector2.ONE,
		0.3
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
