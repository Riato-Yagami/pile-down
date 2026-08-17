class_name RedrawBonusButton
extends HighlightButton

@export_category("Use Animation")
@export var spin_duration := 0.32

@onready var redraw_icon: TextureRect = %RedrawIcon
@onready var remaining_label: Label = %RemainingLabel

var _spin_tween: Tween
var _tray_parent: Control


func _ready() -> void:
	super._ready()
	_tray_parent = get_parent() as Control
	redraw_icon.pivot_offset = redraw_icon.size * 0.5
	redraw_icon.resized.connect(
		func() -> void:
			redraw_icon.pivot_offset = redraw_icon.size * 0.5
	)


func set_as_hand_slot(container: HBoxContainer, enabled: bool) -> void:
	var target_parent: Control = container if enabled else _tray_parent
	if get_parent() != target_parent:
		reparent(target_parent)
	if enabled:
		custom_minimum_size = Vector2(34.0, 37.0)
		redraw_icon.position = Vector2(6.0, 8.0)
		remaining_label.position = Vector2(23.0, 20.0)
		container.move_child(self, -1)
	else:
		custom_minimum_size = Vector2.ZERO
		set_anchors_preset(Control.PRESET_TOP_RIGHT)
		offset_left = -35.0
		offset_top = 1.0
		offset_right = -6.0
		offset_bottom = 22.0
		redraw_icon.position = Vector2.ZERO
		remaining_label.position = Vector2(17.0, 12.0)


func set_remaining(count: int, show_count: bool) -> void:
	remaining_label.visible = show_count and count > 0
	remaining_label.text = str(count)


func play_used_animation() -> void:
	if _spin_tween != null and _spin_tween.is_valid():
		_spin_tween.kill()
	redraw_icon.rotation = 0.0
	_spin_tween = (
		create_tween()
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_IN_OUT)
	)
	_spin_tween.tween_property(redraw_icon, "rotation", TAU, spin_duration)
	_spin_tween.tween_callback(
		func() -> void:
			redraw_icon.rotation = 0.0
	)
