@tool
class_name CustomisationTabs
extends VBoxContainer

## Add another title and page path to extend the customisation screen.
@export var tab_titles: PackedStringArray = ["FONTS", "PALETTES", "DIGITS"]
@export var tab_pages: Array[NodePath] = [NodePath("FontsScroll"), NodePath("PalettesScroll"), NodePath("ValuesScroll")]
@export_range(0.0, 0.5, 0.01, "suffix:s") var transition_duration := 0.18

signal tab_selected(index: int)

var current_tab := 0
var _tween: Tween
@onready var tabs: TabBar = $Tabs


func _ready() -> void:
	tabs.clear_tabs()
	for title in tab_titles:
		tabs.add_tab(title)
	tabs.tab_changed.connect(select_tab)
	tabs.resized.connect(_fit_titles)
	_fit_titles.call_deferred()
	select_tab(current_tab, false)


func select_tab(index: int, animate := true) -> void:
	if index < 0 or index >= tab_pages.size():
		return
	var changed := index != current_tab
	current_tab = index
	tabs.set_current_tab(index)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	for page_index in tab_pages.size():
		var page := get_node_or_null(tab_pages[page_index]) as Control
		if page == null:
			continue
		page.visible = page_index == index
		page.process_mode = Node.PROCESS_MODE_INHERIT if page.visible else Node.PROCESS_MODE_DISABLED
		page.modulate.a = 1.0
		if page.visible and changed and animate and not Engine.is_editor_hint():
			page.modulate.a = 0.0
			_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tween.tween_property(page, "modulate:a", 1.0, transition_duration)

	tab_selected.emit(index)


func _fit_titles() -> void:
	if tabs.size.x <= 0.0:
		return
	var font := tabs.get_theme_font("font")
	var padding := tabs.get_theme_stylebox("tab_selected").get_minimum_size().x
	var font_size := 16
	while font_size > 10:
		var width := 0.0
		for title in tab_titles:
			width += font.get_string_size(tr(title), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + padding
		if width <= tabs.size.x:
			break
		font_size -= 1
	tabs.add_theme_font_size_override("font_size", font_size)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_fit_titles.call_deferred()
