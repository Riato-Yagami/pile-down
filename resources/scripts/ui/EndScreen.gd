@tool
class_name EndScreen
extends Control

# RichTextLabel line boxes and the popup NinePatch include visual whitespace
# that VBoxContainer cannot see. Subtract it internally so Result Gap measures
# the visible glyph/popup edges instead of their control rectangles.
const VISUAL_EDGE_COMPENSATION := 44
const BASE_PANEL_SIZE := Vector2(236, 255)
const PANEL_SCREEN_MARGIN := 32.0
const CONTENT_HORIZONTAL_MARGIN := 34.0
const CONTENT_VERTICAL_MARGIN := 95.0
const SEED_WIDGET_CHROME_WIDTH := 50.0

@export_category("Editor Preview")
@export var show_editor_preview := true:
	set(value):
		show_editor_preview = value
		_refresh_preview()
@export var preview_high_score := true:
	set(value):
		preview_high_score = value
		_refresh_preview()
@export var preview_progression := true:
	set(value):
		preview_progression = value
		_refresh_preview()
@export_category("Layout")
@export_range(0, 24, 1, "suffix:px") var result_gap := 0:
	set(value):
		result_gap = maxi(value, 0)
		_refresh_gap()

@onready var result_stack: VBoxContainer = %ResultStack
@onready var high_score: RichTextLabel = %OverlayHighScore
@onready var progression: RichTextLabel = %OverlayUnlocks
@onready var panel: NinePatchRect = %OverlayPanel
@onready var content: VBoxContainer = panel.get_node("Content")
@onready var seed_display: SeedCopyDisplay = $OverlayCenter/ResultStack/OverlayPanel/Content/EndSeedDisplay


func _ready() -> void:
	content.move_child(seed_display, content.get_child_count() - 1)
	panel.custom_minimum_size = BASE_PANEL_SIZE
	# Text wrapping settles after container layout. Follow the whole content
	# minimum so a temporary tall measurement can shrink again once it settles.
	if not content.minimum_size_changed.is_connected(_refresh_panel_size):
		content.minimum_size_changed.connect(_refresh_panel_size, CONNECT_DEFERRED)
	if not resized.is_connected(_refresh_panel_size):
		resized.connect(_refresh_panel_size)
	_refresh_gap()
	_refresh_panel_size()
	_refresh_preview()


func _refresh_gap() -> void:
	if is_instance_valid(result_stack):
		result_stack.add_theme_constant_override(
			"separation", result_gap - VISUAL_EDGE_COMPENSATION
		)


func _refresh_preview() -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	visible = show_editor_preview
	high_score.visible = preview_high_score
	progression.visible = preview_progression


func _refresh_panel_size() -> void:
	if not is_node_ready():
		return
	var viewport_size := get_viewport_rect().size
	var max_panel_width := maxf(
		BASE_PANEL_SIZE.x,
		viewport_size.x - PANEL_SCREEN_MARGIN
	)
	var seed_label_width := maxf(
		64.0,
		max_panel_width - CONTENT_HORIZONTAL_MARGIN - SEED_WIDGET_CHROME_WIDTH
	)
	if not is_equal_approx(seed_display.expanded_label_width, seed_label_width):
		seed_display.expanded_label_width = seed_label_width
	var content_size := content.get_combined_minimum_size()
	panel.custom_minimum_size = Vector2(
		minf(
			maxf(BASE_PANEL_SIZE.x, content_size.x + CONTENT_HORIZONTAL_MARGIN),
			max_panel_width
		),
		maxf(BASE_PANEL_SIZE.y, content_size.y + CONTENT_VERTICAL_MARGIN)
	)
