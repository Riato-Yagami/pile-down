class_name OptionsMenuLayout
extends Control

const SCROLL_TRACK := preload("res://resources/materials/textures/ui/buttons/slide-bar/vertical/bar.tres")
const SCROLL_SELECTOR := preload("res://resources/materials/textures/ui/buttons/slide-bar/vertical/selector.tres")

var tabs_horizontal := UISettings.TABS_HORIZONTAL:
	set(value):
		tabs_horizontal = value
		if is_node_ready():
			_apply_orientation()
var vertical_padding_min := UISettings.OPTIONS_VERTICAL_PADDING_MIN
var vertical_padding_max := UISettings.OPTIONS_VERTICAL_PADDING_MAX

@onready var body: BoxContainer = $Margin/Layout/Body
@onready var navigation: BoxContainer = $Margin/Layout/Body/Navigation
@onready var scroll: ScrollContainer = $Margin/Layout/Body/PageScroll
@onready var page: VBoxContainer = $Margin/Layout/Body/PageScroll/Page

var _spacing_pending := false


func _ready() -> void:
	PixelUi.style_scroll_container(scroll, SCROLL_TRACK, SCROLL_SELECTOR)
	_apply_orientation()
	scroll.resized.connect(queue_spacing)
	page.minimum_size_changed.connect(queue_spacing)
	page.resized.connect(queue_spacing)
	visibility_changed.connect(queue_spacing)
	queue_spacing()


func _apply_orientation() -> void:
	body.vertical = tabs_horizontal
	navigation.vertical = not tabs_horizontal
	navigation.alignment = BoxContainer.ALIGNMENT_BEGIN
	$Margin/Layout.add_theme_constant_override(&"separation", UISettings.HEADER_GAP)
	body.add_theme_constant_override(&"separation", UISettings.BODY_GAP)
	navigation.add_theme_constant_override(&"separation", UISettings.TAB_GAP)
	for button in navigation.get_children():
		if button is TextureButton:
			button.custom_minimum_size = UISettings.TAB_SIZE
	queue_spacing()


func queue_spacing() -> void:
	if _spacing_pending or not is_node_ready():
		return
	_spacing_pending = true
	_update_spacing.call_deferred()


func _update_spacing() -> void:
	_spacing_pending = false
	if not is_visible_in_tree() or scroll.size.y <= 0.0:
		return
	var boxes: Array[VBoxContainer] = []
	for child in page.get_children():
		_collect_option_boxes(child, boxes)
	var gap_count := 0
	var current_padding := 0
	for box in boxes:
		var gaps := _gap_count(box)
		gap_count += gaps
		current_padding += gaps * box.get_theme_constant(&"separation")
	if gap_count == 0:
		return
	# Measure from the scroll viewport, never the expanding content itself.
	# Removing existing gaps makes the result independent of the previous size.
	var content_height := page.get_combined_minimum_size().y - current_padding
	var minimum := maxi(vertical_padding_min, 0)
	var maximum := maxi(vertical_padding_max, minimum)
	var padding := clampi(floori((scroll.size.y - content_height) / gap_count), minimum, maximum)
	for box in boxes:
		if box.get_theme_constant(&"separation") != padding:
			box.add_theme_constant_override(&"separation", padding)


func _collect_option_boxes(node: Node, boxes: Array[VBoxContainer]) -> void:
	if node is Control and not node.visible:
		return
	if node is VBoxContainer:
		boxes.append(node)
	for child in node.get_children():
		_collect_option_boxes(child, boxes)


func _gap_count(box: VBoxContainer) -> int:
	var count := 0
	for child in box.get_children():
		if child is Control and child.visible and not child.is_set_as_top_level():
			count += 1
	return maxi(count - 1, 0)
