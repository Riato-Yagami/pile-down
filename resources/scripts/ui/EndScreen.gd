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
const SEED_WIDGET_CHROME_WIDTH := 90.0
const SHARE_ICON := preload("res://resources/sprites/ui/icons/links.png")
const COPIED_ICON := preload("res://resources/sprites/ui/check/checked.png")

signal result_copied(message: String)

var share_message := ""
var pending_tile_snapshot := ""
var _share_feedback: Tween

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
@onready var seed_display: SeedCopyDisplay = $OverlayCenter/ResultStack/OverlayPanel/Content/Footer/EndSeedDisplay


@onready var footer: HBoxContainer = seed_display.get_parent()
@onready var share_button: TextureButton = %ShareButton


func _ready() -> void:
	content.move_child(footer, content.get_child_count() - 1)
	share_button.pressed.connect(copy_share_result)
	share_button.mouse_entered.connect(func(): share_button.modulate = GameColors.ACCENT_HOVER / GameColors.ACCENT)
	share_button.mouse_exited.connect(func(): share_button.modulate = Color.WHITE)
	share_button.disabled = true
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


func capture_share_tiles(piles: Array[MemoryPile]) -> void:
	pending_tile_snapshot = ResultShare.capture_tiles(piles)


func set_share_result(title: String, details: String, tiles := "") -> void:
	share_message = ResultShare.build_message(title, details, tiles)
	share_button.disabled = false
	_reset_share_feedback()


func copy_share_result(clipboard_writer: Callable = Callable()) -> void:
	if share_message.is_empty():
		return
	if clipboard_writer.is_valid():
		clipboard_writer.call(share_message)
	elif DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		DisplayServer.clipboard_set(share_message)
	else:
		return
	if _share_feedback != null and _share_feedback.is_valid():
		_share_feedback.kill()
	share_button.texture_normal = COPIED_ICON
	share_button.tooltip_text = ""
	_share_feedback = create_tween()
	_share_feedback.tween_interval(0.9)
	_share_feedback.tween_callback(_reset_share_feedback)
	result_copied.emit(share_message)


func _reset_share_feedback() -> void:
	if _share_feedback != null and _share_feedback.is_valid():
		_share_feedback.kill()
	share_button.texture_normal = SHARE_ICON
	share_button.tooltip_text = ""
