@tool
class_name BackgroundLayer
extends ColorRect

const FALLBACK_SHADER := preload(
	"res://resources/shaders/backgrounds/BackgroundStripes.gdshader"
)
const STRIPE_ONLY_BACKGROUND_COLOR := Color("e5edf2")
const STRIPE_ONLY_STRIPE_COLOR := Color(1.0, 1.0, 1.0, 0.58)
var data: BackgroundThemeData
var catalog: BackgroundThemeCatalog
var shader_material: ShaderMaterial
var _resize_parent: Control
var _pixelated_override := true
var _runtime_viewport_size := Vector2.ZERO


func setup(
	background_data: BackgroundThemeData,
	theme: ThemePaletteData,
	background_catalog: BackgroundThemeCatalog = null
) -> void:
	data = background_data
	catalog = background_catalog if background_catalog != null else BackgroundThemeRegistry.catalog()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resize_parent = get_parent() as Control
	if _resize_parent != null and not _resize_parent.resized.is_connected(resize_to_viewport):
		_resize_parent.resized.connect(resize_to_viewport)
	shader_material = _create_material(background_data)
	material = shader_material
	apply_theme(theme)
	resize_to_viewport()


func apply_theme(theme: ThemePaletteData) -> void:
	if shader_material == null:
		return
	_apply_shared_data()


func resize_to_viewport() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	var target_size := get_viewport_rect().size
	if (
		_resize_parent != null
		and _resize_parent.size.x > 0.0
		and _resize_parent.size.y > 0.0
	):
		target_size = _resize_parent.size
	size = target_size
	_runtime_viewport_size = target_size
	_apply_shared_data()


func set_transition_t(value: float) -> void:
	if shader_material != null:
		shader_material.set_shader_parameter("transition_t", clampf(value, 0.0, 1.0))


func set_pixelated(enabled: bool) -> void:
	_pixelated_override = enabled
	_apply_shared_data()


func _apply_shared_data() -> void:
	if shader_material == null or catalog == null:
		return
	var viewport_size := (
		_runtime_viewport_size
		if _runtime_viewport_size.x > 0.0 and _runtime_viewport_size.y > 0.0
		else catalog.viewport_size
	)
	RenderingServer.global_shader_parameter_set(
		&"background_viewport_size", viewport_size
	)
	RenderingServer.global_shader_parameter_set(
		&"background_reference_size", catalog.reference_size
	)
	RenderingServer.global_shader_parameter_set(
		&"background_color_a", catalog.background_color
	)
	RenderingServer.global_shader_parameter_set(
		&"background_color_b", catalog.pattern_color
	)
	RenderingServer.global_shader_parameter_set(
		&"background_intensity", catalog.intensity
	)
	RenderingServer.global_shader_parameter_set(
		&"background_pixelated",
		1.0 if catalog.pixelated and _pixelated_override else 0.0
	)
	RenderingServer.global_shader_parameter_set(
		&"background_pixel_size", catalog.pixel_size
	)


func _create_material(background_data: BackgroundThemeData) -> ShaderMaterial:
	if background_data != null and background_data.material != null:
		return background_data.material.duplicate() as ShaderMaterial
	var result := ShaderMaterial.new()
	result.shader = FALLBACK_SHADER
	return result
