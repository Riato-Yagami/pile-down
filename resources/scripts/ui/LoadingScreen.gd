@tool
extends Control

const MAIN_SCENE := "res://resources/scenes/Main.tscn"
@export var auto_start := true
@export_range(0.0, 10.0, 0.1) var minimum_duration := UISettings.LOADING_MIN_SECONDS

var _elapsed := 0.0
var _progress := 0.0
var _opening := false
var _failed := false
@onready var _status: Label = %Status
@onready var _retry: Button = %Retry
var _game_script: Script
var _script_loader: Thread
var _resource_requested := false
var _content_offsets: Dictionary = {}


func _ready() -> void:
	%Version.text = FileAccess.get_file_as_string("res://VERSION").strip_edges()
	if Engine.is_editor_hint() or not auto_start:
		set_process(false)
		return
	RenderingServer.set_default_clear_color($Background.color)
	if MobileDisplayController.instance.is_mobile():
		for child in get_children():
			if child is Control and child != $Background:
				_content_offsets[child] = Vector4(
					child.offset_left, child.offset_top, child.offset_right, child.offset_bottom
				)
		MobileDisplayController.instance.safe_area_changed.connect(_fit_safe_area)
		resized.connect(_fit_safe_area)
		_fit_safe_area()
	_retry.pressed.connect(_request_load)
	# Let the custom screen reach the renderer before starting resource work.
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
	_request_load()


func _fit_safe_area() -> void:
	var safe := MobileDisplayController.instance.safe_rect(get_viewport())
	var difference := safe.size - size
	for child: Control in _content_offsets:
		var original: Vector4 = _content_offsets[child]
		child.offset_left = original.x + safe.position.x + child.anchor_left * difference.x
		child.offset_top = original.y + safe.position.y + child.anchor_top * difference.y
		child.offset_right = original.z + safe.position.x + child.anchor_right * difference.x
		child.offset_bottom = original.w + safe.position.y + child.anchor_bottom * difference.y


func _request_load() -> void:
	if _script_loader != null and _script_loader.is_started():
		return
	_failed = false
	_resource_requested = false
	_retry.hide()
	_status.text = "LOADING..."
	# Resolve the cyclic gameplay script graph on one worker before the scene
	# loader starts. No gameplay scene or script is loaded on the UI thread.
	_script_loader = Thread.new()
	var error := _script_loader.start(_prepare_game_script)
	if error != OK:
		_show_error()


static func _prepare_game_script() -> Script:
	return ResourceLoader.load("res://resources/scripts/core/GameManager.gd") as Script


func _request_scene() -> void:
	var error := ResourceLoader.load_threaded_request(MAIN_SCENE, "PackedScene")
	if error != OK:
		_show_error()
	else:
		_resource_requested = true


func _process(delta: float) -> void:
	_elapsed += delta
	if _opening or _failed or _status == null:
		return
	if _script_loader != null and _script_loader.is_started():
		if _script_loader.is_alive():
			return
		_game_script = _script_loader.wait_to_finish() as Script
		if _game_script == null or not _game_script.can_instantiate():
			_show_error()
			return
		_request_scene()
	if not _resource_requested:
		return
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(MAIN_SCENE, progress)
	if not progress.is_empty():
		_progress = float(progress[0])
	_status.text = "%d%%" % roundi(_progress * 100.0)
	if status == ResourceLoader.THREAD_LOAD_FAILED:
		_show_error()
	elif status == ResourceLoader.THREAD_LOAD_LOADED and _elapsed >= minimum_duration:
		_open_game.call_deferred()
		_opening = true


func _show_error() -> void:
	_failed = true
	_status.text = "LOAD FAILED"
	_retry.show()


func _open_game() -> void:
	var scene := ResourceLoader.load_threaded_get(MAIN_SCENE) as PackedScene
	if scene == null:
		_opening = false
		_show_error()
		return
	var main := scene.instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	# Keep the overlay above the new scene until its initial layout is ready.
	get_parent().move_child(self, -1)
	await get_tree().process_frame
	await get_tree().process_frame
	hide()
	await main.get_node("GameCenter/Game").play_menu_opening()
	queue_free()


func _exit_tree() -> void:
	# A window can close during loading; never destroy a running Thread.
	if _script_loader != null and _script_loader.is_started():
		_script_loader.wait_to_finish()
	if _resource_requested and ResourceLoader.load_threaded_get_status(MAIN_SCENE) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		# Godot cannot cancel this request. Drain it only during teardown, before
		# the script/resource dependencies of the loading screen are released.
		ResourceLoader.load_threaded_get(MAIN_SCENE)
