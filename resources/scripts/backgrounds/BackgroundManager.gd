class_name BackgroundManager
extends Node

signal background_changed(background_id: StringName)

const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")
const Debug := preload("res://resources/scripts/settings/debug.gd")

var definitions: Array[BackgroundThemeData] = BackgroundThemeRegistry.create_all()
var catalog: BackgroundThemeCatalog = BackgroundThemeRegistry.catalog()
var layer_parent: Control
var current_layer: BackgroundLayer
var previous_layer: BackgroundLayer
var active_theme: ThemePaletteData
var last_background_id: StringName
var dynamic_presets_enabled := true
var pixelated_backgrounds := true
var _transition_tween: Tween
var _transition_generation := 0
var _enabled := true


func setup(
	parent: Control,
	theme: ThemePaletteData,
	enabled := true,
	backgrounds_pixelated := true
) -> void:
	layer_parent = parent
	active_theme = theme
	_enabled = enabled
	pixelated_backgrounds = backgrounds_pixelated
	if layer_parent != null:
		layer_parent.clip_contents = false


func start_run(rng: RandomNumberGenerator) -> void:
	if not dynamic_presets_enabled:
		_clear_layers()
		last_background_id = &"stripes"
		background_changed.emit(last_background_id)
		return
	var forced := Debug.get_forced_background_id()
	var data := BackgroundThemeRegistry.find(forced) if forced != &"" else _pick(rng)
	if data == null:
		data = definitions[0]
	_set_immediate(data)


func transition_to_next(rng: RandomNumberGenerator) -> Tween:
	if not dynamic_presets_enabled:
		return null
	var forced := Debug.get_forced_background_id()
	var data := BackgroundThemeRegistry.find(forced) if forced != &"" else _pick(rng)
	if data == null:
		return null
	return transition_to(data)


func transition_to(data: BackgroundThemeData) -> Tween:
	if data == null:
		return null
	if catalog != null and not catalog.supports_morph:
		_set_immediate(data)
		return null
	if not _enabled or Debug.DISABLE_SHADER_BACKGROUNDS:
		_set_immediate(data)
		return null
	if current_layer != null and current_layer.data != null and current_layer.data.id == data.id:
		return null
	_transition_generation += 1
	var generation := _transition_generation
	# Finaliser le fondu interrompu avant de remplacer sa couche précédente.
	skip_transition()
	previous_layer = current_layer
	current_layer = _create_layer(data)
	current_layer.modulate.a = 0.0
	current_layer.set_transition_t(0.0)
	_transition_tween = create_tween().set_parallel(true)
	_transition_tween.set_trans(Tween.TRANS_SINE)
	_transition_tween.set_ease(Tween.EASE_IN_OUT)
	if previous_layer != null:
		_transition_tween.tween_property(
			previous_layer, "modulate:a", 0.0, Difficulty.BG_TRANSITION_DURATION
		)
	_transition_tween.tween_property(
		current_layer, "modulate:a", 1.0, Difficulty.BG_TRANSITION_DURATION
	)
	_transition_tween.tween_method(
		_set_current_transition_t, 0.0, 1.0, Difficulty.BG_TRANSITION_DURATION
	)
	_transition_tween.finished.connect(_finish_transition.bind(generation))
	last_background_id = data.id
	background_changed.emit(data.id)
	return _transition_tween


func skip_transition() -> void:
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	if current_layer != null:
		current_layer.modulate.a = 1.0
		current_layer.set_transition_t(1.0)
	if previous_layer != null:
		previous_layer.queue_free()
		previous_layer = null
	_transition_tween = null


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if current_layer != null:
		current_layer.visible = enabled
	if previous_layer != null:
		previous_layer.visible = enabled


func set_pixelated_backgrounds(enabled: bool) -> void:
	pixelated_backgrounds = enabled
	var pixelated := Difficulty.BG_MORPH_PIXELATED and pixelated_backgrounds
	if current_layer != null:
		current_layer.set_pixelated(pixelated)
	if previous_layer != null:
		previous_layer.set_pixelated(pixelated)


func apply_theme(theme: ThemePaletteData) -> void:
	active_theme = theme
	if current_layer != null:
		current_layer.apply_theme(theme)
	if previous_layer != null:
		previous_layer.apply_theme(theme)


func resize_to_viewport() -> void:
	if current_layer != null:
		current_layer.resize_to_viewport()
	if previous_layer != null:
		previous_layer.resize_to_viewport()


func _clear_layers() -> void:
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = null
	if current_layer != null:
		current_layer.queue_free()
		current_layer = null
	if previous_layer != null:
		previous_layer.queue_free()
		previous_layer = null


func _set_immediate(data: BackgroundThemeData) -> void:
	_clear_layers()
	current_layer = _create_layer(data)
	current_layer.modulate.a = 1.0
	current_layer.set_transition_t(1.0)
	last_background_id = data.id
	background_changed.emit(data.id)


func _create_layer(data: BackgroundThemeData) -> BackgroundLayer:
	var layer := BackgroundLayer.new()
	layer.name = "Background_%s" % String(data.id)
	layer.visible = _enabled and not Debug.DISABLE_SHADER_BACKGROUNDS
	var insert_index := _background_insert_index()
	layer_parent.add_child(layer)
	layer_parent.move_child(layer, insert_index)
	layer.setup(data, active_theme, catalog)
	layer.set_pixelated(Difficulty.BG_MORPH_PIXELATED and pixelated_backgrounds)
	return layer


func _background_insert_index() -> int:
	if layer_parent == null:
		return -1
	var copy := layer_parent.get_node_or_null("BackgroundCopy")
	if copy != null:
		return copy.get_index()
	return layer_parent.get_child_count()


func _pick(rng: RandomNumberGenerator) -> BackgroundThemeData:
	if definitions.is_empty():
		return null
	if definitions.size() == 1:
		return definitions[0]
	var total := 0.0
	for data in definitions:
		total += _weight_for(data)
	var roll := rng.randf() * maxf(total, 0.001)
	for data in definitions:
		roll -= _weight_for(data)
		if roll <= 0.0:
			return data
	return definitions.back()


func _weight_for(data: BackgroundThemeData) -> float:
	if data.id == last_background_id:
		return maxf(data.weight * 0.08, 0.001)
	return maxf(data.weight, 0.001)


func _set_current_transition_t(value: float) -> void:
	if current_layer != null:
		current_layer.set_transition_t(value)


func _finish_transition(generation: int) -> void:
	if generation != _transition_generation:
		return
	if previous_layer != null:
		previous_layer.queue_free()
		previous_layer = null
	if current_layer != null:
		current_layer.modulate.a = 1.0
		current_layer.set_transition_t(1.0)
	_transition_tween = null
