@tool
class_name SelectableDataCatalog
extends DataCatalog

signal editor_preview_refreshed(selected_data: Data)

var _selected_data: Data
var _selected_index := 0

@export var selected_data: Data:
	get:
		return _selected_data
	set(value):
		_disconnect_selected_data()
		_selected_data = value
		_sync_selected_index_from_data()
		_connect_selected_data()
		refresh_selected_preview()
@export var selected_index := 0:
	get:
		return _selected_index
	set(value):
		_selected_index = maxi(value, 0)
		_sync_selected_data_from_index()
		refresh_selected_preview()
@export_tool_button("Refresh Selected Preview", "Reload")
var refresh_selected_preview_action: Callable = refresh_selected_preview


func get_selection_pool() -> Array[Data]:
	return enabled_data


func get_selected_data() -> Data:
	if _selected_data != null:
		return _selected_data
	var pool := get_selection_pool()
	if pool.is_empty():
		return null
	return pool[clampi(_selected_index, 0, pool.size() - 1)]


func refresh_selected_preview() -> void:
	_clamp_selected_index()
	editor_preview_refreshed.emit(get_selected_data())
	if Engine.is_editor_hint():
		_broadcast_editor_preview_refresh()
	emit_changed()


func _broadcast_editor_preview_refresh() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	_broadcast_editor_preview_refresh_to(tree.root)


func _broadcast_editor_preview_refresh_to(node: Node) -> void:
	if node.has_method("_on_data_catalog_editor_preview_refreshed"):
		node.call(
			"_on_data_catalog_editor_preview_refreshed",
			self,
			get_selected_data()
		)
	for child in node.get_children():
		_broadcast_editor_preview_refresh_to(child)


func _clamp_selected_index() -> void:
	var pool := get_selection_pool()
	if pool.is_empty():
		_selected_index = 0
		return
	_selected_index = clampi(_selected_index, 0, pool.size() - 1)


func _sync_selected_data_from_index() -> void:
	var pool := get_selection_pool()
	if pool.is_empty():
		_selected_data = null
		return
	_disconnect_selected_data()
	_selected_data = pool[clampi(_selected_index, 0, pool.size() - 1)]
	_connect_selected_data()


func _sync_selected_index_from_data() -> void:
	var pool := get_selection_pool()
	if _selected_data == null:
		_clamp_selected_index()
		return
	var index := pool.find(_selected_data)
	if index >= 0:
		_selected_index = index


func _connect_selected_data() -> void:
	if _selected_data != null and not _selected_data.changed.is_connected(refresh_selected_preview):
		_selected_data.changed.connect(refresh_selected_preview)


func _disconnect_selected_data() -> void:
	if _selected_data != null and _selected_data.changed.is_connected(refresh_selected_preview):
		_selected_data.changed.disconnect(refresh_selected_preview)
