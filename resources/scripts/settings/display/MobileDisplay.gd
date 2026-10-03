class_name MobileDisplayController
extends Node

signal safe_area_changed

static var instance: MobileDisplayController

const BASE_SIZE := Vector2(256, 320)
var show_system_bars := true
var ignore_notch := false
var _safe_pixels := Rect2()
var _window_pixels := Vector2.ZERO
var _poll_elapsed := 0.0


func _enter_tree() -> void:
	instance = self


func is_mobile() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios")


func supports_system_bars() -> bool:
	return OS.has_feature("android")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(is_mobile())
	reload_settings()
	if is_mobile():
		get_window().size_changed.connect(_refresh_safe_area)
		_refresh_safe_area()


func reload_settings() -> void:
	var config := SaveConfig.load_current()
	show_system_bars = bool(config.get_value(
		"graphics", "show_system_bars", true
	))
	ignore_notch = bool(config.get_value("graphics", "ignore_notch", false))
	_apply_system_bars()
	_refresh_safe_area(true)


func set_system_bars_visible(value: bool) -> void:
	if not supports_system_bars():
		return
	show_system_bars = value
	var config := SaveConfig.load_current()
	config.set_value("graphics", "show_system_bars", value)
	config.save(SaveConfig.PATH)
	_apply_system_bars()
	_refresh_safe_area(true)


func set_ignore_notch(value: bool) -> void:
	if not supports_system_bars() or show_system_bars:
		return
	ignore_notch = value
	var config := SaveConfig.load_current()
	config.set_value("graphics", "ignore_notch", value)
	config.save(SaveConfig.PATH)
	_refresh_safe_area(true)


func _apply_system_bars() -> void:
	if supports_system_bars():
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if show_system_bars
			else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
		_apply_dark_system_icons()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED:
		_apply_dark_system_icons()


func _apply_dark_system_icons() -> void:
	if not OS.has_feature("android") or not Engine.has_singleton("AndroidRuntime"):
		return
	var runtime = Engine.get_singleton("AndroidRuntime")
	var activity = runtime.getActivity()
	if activity == null:
		return
	# Android calls its dark foreground icons the "light bars" appearance.
	# Run after Godot's immersive-mode update on Android's UI thread.
	var apply_icons := func():
		var java = Engine.get_singleton("JavaClassWrapper")
		var version = java.wrap("android.os.Build$VERSION")
		var window = activity.getWindow()
		if int(version.SDK_INT) >= 30:
			var controller = window.getInsetsController()
			if controller != null:
				# APPEARANCE_LIGHT_STATUS_BARS | APPEARANCE_LIGHT_NAVIGATION_BARS.
				controller.setSystemBarsAppearance(8 | 16, 8 | 16)
		else:
			var view = window.getDecorView()
			var flags := int(view.getSystemUiVisibility())
			if int(version.SDK_INT) >= 23:
				flags |= 8192 # SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
			if int(version.SDK_INT) >= 26:
				flags |= 16 # SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
			view.setSystemUiVisibility(flags)
	activity.runOnUiThread(runtime.createRunnableFromGodotCallable(apply_icons))


func _process(delta: float) -> void:
	# Insets can change without a viewport resize (immersive gestures, cutouts).
	_poll_elapsed += delta
	if _poll_elapsed >= 0.2:
		_poll_elapsed = 0.0
		_refresh_safe_area()


func _refresh_safe_area(force := false) -> void:
	if not is_mobile():
		return
	var pixels := _read_window_size()
	var safe := _read_safe_area()
	if not force and pixels == _window_pixels and safe == _safe_pixels:
		return
	_window_pixels = pixels
	_safe_pixels = safe
	_apply_dark_system_icons()
	configure_window()
	safe_area_changed.emit()


func configure_window() -> void:
	if not is_mobile():
		return
	var pixels := _read_window_size()
	var safe := _layout_safe_area(pixels)
	if not safe.has_area():
		return
	# Reserve the base playable size INSIDE the safe area, even in classic mode.
	# Two extra logical pixels absorb inward rounding at the two opposing edges.
	var factor := minf(safe.size.x / (BASE_SIZE.x + 2.0), safe.size.y / (BASE_SIZE.y + 2.0))
	var window := get_window()
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.content_scale_size = Vector2i((pixels / factor).ceil())


func safe_rect(viewport: Viewport) -> Rect2:
	var bounds := viewport.get_visible_rect()
	if not is_mobile():
		return bounds
	var pixels := _read_window_size()
	var safe := _layout_safe_area(pixels)
	var local := viewport.get_screen_transform().affine_inverse() * safe
	# Round inward so a snapped pixel cannot end up under the notch.
	var start := local.position.ceil()
	var end := local.end.floor()
	return Rect2(start, end - start).intersection(bounds)


func _layout_safe_area(pixels: Vector2) -> Rect2:
	if supports_system_bars() and not show_system_bars and ignore_notch:
		return Rect2(Vector2.ZERO, pixels)
	return clipped_safe_area(_read_safe_area(), pixels)


func _read_window_size() -> Vector2:
	return Vector2(DisplayServer.window_get_size())


func _read_safe_area() -> Rect2:
	return Rect2(DisplayServer.get_display_safe_area())


static func clipped_safe_area(safe: Rect2, window_size: Vector2) -> Rect2:
	var bounds := Rect2(Vector2.ZERO, window_size)
	var clipped := safe.intersection(bounds)
	return clipped if clipped.has_area() else bounds
