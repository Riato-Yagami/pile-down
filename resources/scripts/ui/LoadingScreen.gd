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


func _ready() -> void:
	%Version.text = FileAccess.get_file_as_string("res://VERSION").strip_edges()
	if Engine.is_editor_hint() or not auto_start:
		set_process(false)
		return
	RenderingServer.set_default_clear_color($Background.color)
	_retry.pressed.connect(_request_load)
	# Let the custom screen reach the renderer before starting resource work.
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
	# Resolve the mutually typed gameplay scripts on the main thread. Godot
	# cannot compile this cyclic script graph safely from a loader worker.
	_game_script = load("res://resources/scripts/core/GameManager.gd")
	_request_load()


func _request_load() -> void:
	_failed = false
	_retry.hide()
	var error := ResourceLoader.load_threaded_request(MAIN_SCENE, "PackedScene")
	if error != OK:
		_show_error()


func _process(delta: float) -> void:
	_elapsed += delta
	if _opening or _failed or _status == null:
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
	queue_free()
