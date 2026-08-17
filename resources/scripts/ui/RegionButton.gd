@tool
class_name RegionButton
extends Button

const ButtonInteractionScript := preload(
	"res://resources/scripts/ui/ButtonInteraction.gd"
)

@export var highlight_material: ShaderMaterial
@export_category("Stretchable Texture")
@export var button_texture: Texture2D:
	set(value):
		button_texture = value
		_queue_texture_refresh()
@export var region_rect := Rect2(0.0, 0.0, 86.0, 31.0):
	set(value):
		region_rect = value
		_queue_texture_refresh()
@export_group("Patch Margins")
@export var patch_margin_left := 8.0:
	set(value):
		patch_margin_left = maxf(value, 0.0)
		_queue_texture_refresh()
@export var patch_margin_top := 6.0:
	set(value):
		patch_margin_top = maxf(value, 0.0)
		_queue_texture_refresh()
@export var patch_margin_right := 8.0:
	set(value):
		patch_margin_right = maxf(value, 0.0)
		_queue_texture_refresh()
@export var patch_margin_bottom := 6.0:
	set(value):
		patch_margin_bottom = maxf(value, 0.0)
		_queue_texture_refresh()
@export_group("Content Margins")
@export var content_margin_left := 9.0:
	set(value):
		content_margin_left = value
		_queue_texture_refresh()
@export var content_margin_top := 4.0:
	set(value):
		content_margin_top = value
		_queue_texture_refresh()
@export var content_margin_right := 9.0:
	set(value):
		content_margin_right = value
		_queue_texture_refresh()
@export var content_margin_bottom := 4.0:
	set(value):
		content_margin_bottom = value
		_queue_texture_refresh()

var _interaction = ButtonInteractionScript.new()
var _texture_refresh_queued := false


func _ready() -> void:
	_apply_region_style()
	if not Engine.is_editor_hint():
		_interaction.setup(self, highlight_material)


func _gui_input(event: InputEvent) -> void:
	if not Engine.is_editor_hint():
		_interaction.handle_gui_input(event)


func _queue_texture_refresh() -> void:
	if not is_inside_tree() or _texture_refresh_queued:
		return
	_texture_refresh_queued = true
	call_deferred("_apply_region_style")


func _apply_region_style() -> void:
	_texture_refresh_queued = false
	if button_texture == null or region_rect.size.x <= 0.0 or region_rect.size.y <= 0.0:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = button_texture
	atlas.region = region_rect
	var style := StyleBoxTexture.new()
	style.texture = atlas
	style.texture_margin_left = patch_margin_left
	style.texture_margin_top = patch_margin_top
	style.texture_margin_right = patch_margin_right
	style.texture_margin_bottom = patch_margin_bottom
	style.content_margin_left = content_margin_left
	style.content_margin_top = content_margin_top
	style.content_margin_right = content_margin_right
	style.content_margin_bottom = content_margin_bottom
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		add_theme_stylebox_override(state, style)
