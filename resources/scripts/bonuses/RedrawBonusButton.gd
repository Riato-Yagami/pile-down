class_name RedrawBonusButton
extends HighlightButton

@export_category("Use Animation")
@export var spin_duration := 0.32

@onready var redraw_icon: TextureRect = %RedrawIcon
@onready var remaining_label: Label = %RemainingLabel

var _spin_tween: Tween


func _ready() -> void:
	super._ready()
	redraw_icon.pivot_offset = redraw_icon.size * 0.5
	redraw_icon.resized.connect(
		func() -> void:
			redraw_icon.pivot_offset = redraw_icon.size * 0.5
	)


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
