class_name GameScreenLayout
extends RefCounted

## Canvas fitting and screen-edge margins, including the sliding menu.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func normalized_edge_margins(host: GameManager, margins: Vector4) -> Vector4:
	return Vector4(
		maxf(margins.x, 0.0),
		maxf(margins.y, 0.0),
		maxf(margins.z, 0.0),
		maxf(margins.w, 0.0)
	)


static func apply_screen_edge_margins(host: GameManager) -> void:
	var margins := host._normalized_edge_margins(host.screen_edge_margins)
	host._position_top_left(host.timer_ring, margins.x, margins.y)
	host._position_top_right(host.round_panel, margins.z, margins.y)
	host._position_bottom_left(host.debug_help, margins.x, margins.w)
	host._position_bottom_left(host.splash_debug_help, margins.x, margins.w)
	host._position_top_right(host.progression_button, margins.z, margins.y)
	host._position_top_right(
		host.options_button,
		margins.z + host._edge_width(host.progression_button) + 6.0,
		margins.y
	)
	host._position_top_right(
		host.challenge_button,
		margins.z
		+ host._edge_width(host.progression_button)
		+ host._edge_width(host.options_button)
		+ 12.0,
		margins.y
	)
	host._position_right_keep_top(host.back_button, margins.z)
	host._position_bottom_right(
		host.bonus_selection.get_node_or_null("SkipButton") as Control,
		margins.z,
		margins.w
	)
	host._apply_screen_margin_control(host.splash.get_node_or_null("Center") as Control, margins)
	host._apply_screen_margin_control(host.options_menu.get_node_or_null("Margin") as Control, margins)
	host._apply_screen_margin_control(host.checkpoint_menu.get_node_or_null("Center") as Control, margins)
	host._apply_screen_margin_control(host.quit_popup.get_node_or_null("Center") as Control, margins)
	host._apply_bonus_title_margins(margins)
	if host.progression_menu is MenuPanelLayout:
		var progression_layout := host.progression_menu as MenuPanelLayout
		progression_layout.panel_margins = margins
		progression_layout.apply_panel_layout()
	if host.challenge_selection is MenuPanelLayout:
		var challenge_layout := host.challenge_selection as MenuPanelLayout
		challenge_layout.panel_margins = margins
		challenge_layout.apply_panel_layout()
	if is_instance_valid(host.hand_tray):
		host.hand_tray.set_screen_edge_margins(margins)
		host.hand_tray.set_conveyor_enabled(host.challenge_modifiers.conveyor_hand)


static func apply_screen_margin_control(
	host: GameManager, control: Control, margins: Vector4
) -> void:
	if control == null:
		return
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.offset_left = margins.x
	control.offset_top = margins.y
	control.offset_right = -margins.z
	control.offset_bottom = -margins.w
	var margin_container := control as MarginContainer
	if margin_container == null:
		return
	margin_container.add_theme_constant_override(&"margin_left", 0)
	margin_container.add_theme_constant_override(&"margin_top", 0)
	margin_container.add_theme_constant_override(&"margin_right", 0)
	margin_container.add_theme_constant_override(&"margin_bottom", 0)


static func apply_bonus_title_margins(host: GameManager, margins: Vector4) -> void:
	var title := host.bonus_selection.get_node_or_null("Title") as Control
	if title == null:
		return
	title.offset_left = margins.x
	title.offset_right = -margins.z


static func position_top_left(host: GameManager, control: Control, left: float, top: float) -> void:
	if not is_instance_valid(control):
		return
	var control_size := host._edge_size(control)
	control.offset_left = left
	control.offset_top = top
	control.offset_right = left + control_size.x
	control.offset_bottom = top + control_size.y


static func position_top_right(
	host: GameManager, control: Control, right: float, top: float
) -> void:
	if not is_instance_valid(control):
		return
	var control_size := host._edge_size(control)
	control.offset_right = -right
	control.offset_left = control.offset_right - control_size.x
	control.offset_top = top
	control.offset_bottom = top + control_size.y


static func position_right_keep_top(host: GameManager, control: Control, right: float) -> void:
	if not is_instance_valid(control):
		return
	var control_size := host._edge_size(control)
	control.offset_right = -right
	control.offset_left = control.offset_right - control_size.x


static func position_bottom_left(
	host: GameManager, control: Control, left: float, bottom: float
) -> void:
	if not is_instance_valid(control):
		return
	var control_size := host._edge_size(control)
	control.offset_left = left
	control.offset_right = left + control_size.x
	control.offset_bottom = -bottom
	control.offset_top = control.offset_bottom - control_size.y


static func position_bottom_right(
	host: GameManager, control: Control, right: float, bottom: float
) -> void:
	if not is_instance_valid(control):
		return
	var control_size := host._edge_size(control)
	control.offset_right = -right
	control.offset_left = control.offset_right - control_size.x
	control.offset_bottom = -bottom
	control.offset_top = control.offset_bottom - control_size.y


static func edge_size(host: GameManager, control: Control) -> Vector2:
	var current_size := control.size
	if current_size.x <= 0.0:
		current_size.x = absf(control.offset_right - control.offset_left)
	if current_size.y <= 0.0:
		current_size.y = absf(control.offset_bottom - control.offset_top)
	return current_size


static func edge_width(host: GameManager, control: Control) -> float:
	if not is_instance_valid(control):
		return 0.0
	return host._edge_size(control).x


static func canvas_origin(host: GameManager) -> Vector2:
	return host.get_global_rect().position


static func canvas_size(host: GameManager) -> Vector2:
	return host.size


static func fit_control_to_canvas_space(
	host: GameManager, control: Control, center_source: Control = null
) -> void:
	if not is_instance_valid(control):
		return
	var parent_control := control.get_parent() as Control
	var parent_origin := (
		parent_control.get_global_rect().position
		if parent_control != null else Vector2.ZERO
	)
	control.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	control.position = host._canvas_origin() - parent_origin
	control.size = host._canvas_size()
	for child in control.get_children():
		var child_control := child as Control
		if child_control == null:
			continue
		if (
			is_zero_approx(child_control.anchor_left)
			and is_zero_approx(child_control.anchor_top)
			and is_equal_approx(child_control.anchor_right, 1.0)
			and is_equal_approx(child_control.anchor_bottom, 1.0)
		):
			child_control.offset_left = 0.0
			child_control.offset_top = 0.0
			child_control.offset_right = 0.0
			child_control.offset_bottom = 0.0


static func fit_overlay_to_canvas(host: GameManager) -> void:
	host._fit_control_to_canvas_space(host.overlay, host.screens)


static func fit_splash_background_to_canvas(host: GameManager) -> void:
	if host.splash.get_parent() == host.menu_transition_layer:
		host._fit_splash_background_to_local_rect()
		return
	var splash_background := host.splash.get_node_or_null("Background") as ColorRect
	if splash_background != null:
		host._fit_control_to_canvas_space(splash_background, host.splash)


static func fit_splash_background_to_local_rect(host: GameManager) -> void:
	var splash_background := host.splash.get_node_or_null("Background") as ColorRect
	if splash_background == null:
		return
	splash_background.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	splash_background.position = -host.screens.position
	splash_background.size = host._canvas_size()


static func prepare_splash_transition_layout(host: GameManager) -> void:
	host._fit_splash_background_to_local_rect()
	host._apply_screen_edge_margins()


static func restore_splash_screen_layout(host: GameManager) -> void:
	host.splash.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	host.splash.position = Vector2.ZERO
	host.splash.size = host.screens.size
	host._fit_splash_background_to_canvas()
	host._apply_screen_edge_margins()


static func fit_quit_popup_to_viewport(host: GameManager) -> void:
	# CanvasLayer controls follow the viewport, not the game container whose
	# size may still be stale when the window's resize signal is emitted.
	host.quit_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := host.quit_popup.get_node("Center") as CenterContainer
	host._apply_screen_margin_control(center, host._normalized_edge_margins(host.screen_edge_margins))
	center.queue_sort()
