class_name ButtonInteraction
extends RefCounted

var touch_index := -1

const HoverInteractionScript := preload(
	"res://resources/scripts/ui/HoverInteraction.gd"
)

var _button_ref: WeakRef
var _highlight_material: ShaderMaterial
var _hover_interaction = HoverInteractionScript.new()


func setup(button: BaseButton, highlight_material: ShaderMaterial) -> void:
	_button_ref = weakref(button)
	_highlight_material = highlight_material
	button.material = null
	_hover_interaction.setup(
		button,
		self,
		&"show_highlight",
		&"hide_highlight"
	)


func handle_gui_input(event: InputEvent) -> void:
	var button := _button_ref.get_ref() as BaseButton
	if button == null:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if button.disabled or touch_index >= 0:
				return
			touch_index = touch.index
			show_highlight()
			button.accept_event()
		elif touch.index == touch_index:
			touch_index = -1
			hide_highlight()
			if not touch.canceled and Rect2(Vector2.ZERO, button.size).has_point(touch.position):
				button.pressed.emit()
			button.accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index != touch_index:
			return
		if Rect2(Vector2.ZERO, button.size).has_point(drag.position):
			show_highlight()
		else:
			hide_highlight()
		button.accept_event()


func show_highlight() -> void:
	var button := _button_ref.get_ref() as BaseButton
	if button != null:
		button.material = _highlight_material


func hide_highlight() -> void:
	var button := _button_ref.get_ref() as BaseButton
	if button != null:
		button.material = null
