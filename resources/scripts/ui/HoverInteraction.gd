class_name HoverInteraction
extends RefCounted

var _target_ref: WeakRef
var _show_method: StringName
var _hide_method: StringName


func setup(
	control: Control,
	target: Object,
	show_method: StringName,
	hide_method: StringName
) -> void:
	_target_ref = weakref(target)
	_show_method = show_method
	_hide_method = hide_method
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	control.mouse_entered.connect(show)
	control.mouse_exited.connect(hide)


func show() -> void:
	var target := _target_ref.get_ref() as Object
	if target != null:
		target.call(_show_method)


func hide() -> void:
	var target := _target_ref.get_ref() as Object
	if target != null:
		target.call(_hide_method)
