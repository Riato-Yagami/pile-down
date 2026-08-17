class_name GameManager
extends Control

signal card_placed(card, pile)
signal mistake_made()
signal round_completed()
signal game_over()

enum GameMode {
	STANDARD,
	CHECKPOINT,
	ENDLESS,
	CHALLENGE,
}

const PILE_SCENE := preload("res://resources/scenes/gameplay/Pile.tscn")
# A replay has no menu transition to let the player settle before memorizing.
# Keep the opening pile values visible long enough to establish a fresh run.
const RESTART_PILE_REVEAL_BONUS := 1.0
const HIGHLIGHT_BUTTON_SCRIPT := preload(
	"res://resources/scripts/ui/HighlightButton.gd"
)
const DustPoolScript := preload("res://resources/scripts/effects/DustPool.gd")
const SELECTED_TEXTURE := preload(
	"res://resources/materials/textures/ui/check/selected.tres"
)
const UNCHECKED_TEXTURE := preload(
	"res://resources/materials/textures/ui/check/unchecked.tres"
)
const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")
const DifficultyProgressionScript := preload(
	"res://resources/scripts/gameplay/DifficultyProgression.gd"
)
const ProgressionSnapshotBuilderScript := preload(
	"res://resources/scripts/progression/ProgressionSnapshotBuilder.gd"
)
const SubmenuSwipeControllerScript := preload(
	"res://resources/scripts/ui/SubmenuSwipeController.gd"
)
const GameOptionsControllerScript := preload(
	"res://resources/scripts/settings/GameOptionsController.gd"
)
const CheckpointMenuControllerScript := preload(
	"res://resources/scripts/progression/checkpoints/CheckpointMenuController.gd"
)
const ProgressionUnreadStoreScript := preload(
	"res://resources/scripts/progression/ProgressionUnreadStore.gd"
)
const AchievementNotificationControllerScript := preload(
	"res://resources/scripts/progression/AchievementNotificationController.gd"
)
const PROGRESSION_BONUS_ICON := "res://resources/materials/icons/bonuses.tres"
const PROGRESSION_RULE_ICON := "res://resources/materials/icons/rules.tres"
const PROGRESSION_CHECKPOINT_ICON := "res://resources/materials/icons/saves.tres"
const PROGRESSION_ACHIEVEMENT_ICON := (
	"res://resources/materials/icons/trophies.tres"
)
const Debug := preload("res://resources/scripts/settings/debug.gd")
const MUSIC_BUS_NAME := &"Music"
const SFX_BUS_NAME := &"SFX"
const OPTIONS_SELECTED_COLOR := Color("4d82c2")
const OPTION_TEXT_COLOR := Color("3c3c3c")
const OPTION_GAMEPLAY := 0
const OPTION_SOUND := 1
const OPTION_GRAPHICS := 2
const OPTION_SAVE := 3
const OPTION_LINKS := 4
const ITCH_URL := "https://juel-s.itch.io/"
const KOFI_URL := "https://ko-fi.com/juels"
const LOCKED_VIEWPORT_SIZE := Vector2i(256, 320)
const AUDIO_CONFIG_PATH := "user://pile_down.cfg"
const DEATH_POPUP_DELAY := 0.1
const DEATH_PILE_REVEAL_HOLD_DURATION := 0.25
const SAVE_SCHEMA_VERSION := 4
const URGENT_TICK_THRESHOLDS: Array[float] = [
	2.0,
	1.6667,
	1.3333,
	1.0,
	0.8333,
	0.6667,
	0.5,
	0.3333,
	0.1667,
	0.0,
]

@onready var piles_board: Control = %PilesBoard
@onready var hand_container: HBoxContainer = %HandContainer
@onready var hand_tray: ConveyorHandTray = %HandTray
@onready var drag_layer: Control = %DragLayer
@onready var hand_manager: HandManager = %HandManager
@onready var pile_manager: PileManager = %PileManager
@onready var timer_manager: CountdownManager = %TimerManager
@onready var timer_label: Label = %TimerLabel
@onready var timer_ring: CountdownRing = %TimerRing
@onready var round_panel: TextureRect = %RoundPanel
@onready var round_label: Label = %RoundLabel
@onready var run_time_label: Label = %RunTimeLabel
@onready var mistakes_dots: RoundDots = %MistakesDots
@onready var transient_label: Label = %TransientLabel
@onready var achievement_popup: Control = %AchievementPopup
@onready var achievement_popup_title: Label = %AchievementPopupTitle
@onready var bonus_selection: BonusSelection = %BonusSelection
@onready var skippable_sequence: SkippableSequence = %SkippableSequence
@onready var quit_popup: Control = %QuitPopup
@onready var quit_continue_button: Button = %QuitContinueButton
@onready var quit_restart_button: Button = %QuitRestartButton
@onready var quit_run_button: Button = %QuitRunButton
@onready var overlay: Control = %Overlay
@onready var overlay_title: RichTextLabel = %OverlayTitle
@onready var overlay_details: RichTextLabel = %OverlayDetails
@onready var overlay_button: Button = %OverlayButton
@onready var overlay_endless_button: Button = %OverlayEndlessButton
@onready var overlay_high_score: RichTextLabel = %OverlayHighScore
@onready var overlay_unlocks: RichTextLabel = %OverlayUnlocks
@onready var overlay_quit_button: Button = %OverlayQuitButton
@onready var overlay_scrim: ColorRect = $Screens/Overlay/Scrim
@onready var overlay_panel: NinePatchRect = $Screens/Overlay/Center/ResultStack/Panel
@onready var replay_transition_mask: ColorRect = %ReplayTransitionMask
@onready var menu_transition_layer: CanvasLayer = %MenuTransitionLayer
@onready var screens: Node = $Screens
@onready var splash: Control = %Splash
@onready var splash_button: Button = %SplashButton
@onready var endless_button: Button = %EndlessButton
@onready var checkpoint_button: Button = %CheckpointButton
@onready var checkpoint_up_button: TextureButton = %CheckpointUpButton
@onready var checkpoint_down_button: TextureButton = %CheckpointDownButton
@onready var checkpoint_menu: Control = %CheckpointMenu
@onready var checkpoint_list: VBoxContainer = %CheckpointList
@onready var checkpoint_back_button: Button = %CheckpointBackButton
@onready var splash_high_score: RichTextLabel = %SplashHighScore
@onready var splash_high_score_time: Label = %SplashHighScoreTime
@onready var splash_debug_mode: Label = %SplashDebugMode
@onready var splash_debug_help: Label = %SplashDebugHelp
@onready var progression_button: TextureButton = %ProgressionButton
@onready var challenge_button: TextureButton = %ChallengeButton
@onready var challenge_selection: ChallengeSelection = %ChallengeSelection
@onready var progression_notification: TextureRect = %ProgressionNotification
@onready var options_button: TextureButton = %OptionsButton
@onready var options_menu: Control = %OptionsMenu
@onready var options_back_button: TextureButton = %OptionsBackButton
@onready var gameplay_options_button: TextureButton = %GameplayOptionsButton
@onready var sound_options_button: TextureButton = %SoundOptionsButton
@onready var graphics_options_button: TextureButton = %GraphicsOptionsButton
@onready var save_options_button: TextureButton = %SaveOptionsButton
@onready var links_options_button: TextureButton = %LinksOptionsButton
@onready var options_page_title: Label = %OptionsPageTitle
@onready var gameplay_options: Control = %GameplayOptions
@onready var sound_options: Control = %SoundOptions
@onready var graphics_options: Control = %GraphicsOptions
@onready var save_options: Control = %SaveOptions
@onready var links_options: Control = %LinksOptions
@onready var adaptive_resolution_button: Button = %AdaptiveResolutionButton
@onready var dust_effects_button: Button = %DustEffectsButton
@onready var background_enabled_button: Button = %BackgroundEnabledButton
@onready var relief_lighting: ReliefLighting = %ReliefLighting
@onready var uniform_relief_light: DirectionalLight2D = %UniformReliefLight
@onready var pointer_relief_light: PointLight2D = %PointerReliefLight
@onready var achievement_notifications_button: Button = %AchievementNotificationsButton
@onready var timer_display_button: Button = %TimerDisplayButton
@onready var itch_link_button: Button = %ItchLinkButton
@onready var kofi_link_button: Button = %KofiLinkButton
@onready var export_save_button: Button = %ExportSaveButton
@onready var import_save_button: Button = %ImportSaveButton
@onready var delete_save_button: Button = %DeleteSaveButton
@onready var export_save_dialog: FileDialog = %ExportSaveDialog
@onready var import_save_dialog: FileDialog = %ImportSaveDialog
@onready var delete_save_confirmation: ConfirmationDialog = %DeleteSaveConfirmation
@onready var save_status: Label = %SaveStatus
@onready var save_data_manager: SaveDataManager = %SaveDataManager
@onready var progression_menu: ProgressionMenu = %ProgressionMenu
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var sound_volume_slider: HSlider = %SoundVolumeSlider
@onready var debug_help: Label = %DebugHelp
@onready var debug_probability_panel: Label = %DebugProbabilityPanel
@onready var soft_audio: SoftAudio = %SoftAudio
@onready var music_manager: MusicManager = %MusicManager
@onready var special_rule_manager: SpecialRuleManager = %SpecialRuleManager
@onready var bonus_manager: BonusManager = %BonusManager
@onready var lava_rule_controller: LavaRuleController = %LavaRuleController
@onready var sticky_fingers_controller: StickyFingersRuleController = %StickyFingersRuleController
@onready var mirror_match_controller: MirrorMatchRuleController = %MirrorMatchRuleController
@onready var flashlight_overlay: FlashlightOverlay = %FlashlightOverlay
@onready var lava_layer: Control = %LavaLayer
@onready var redraw_button: RedrawBonusButton = %RedrawButton
@onready var active_bonus_bar: GridContainer = %ActiveBonusBar
@onready var back_button: TextureHighlightButton = %BackButton

var difficulty_progression := DifficultyProgressionScript.new()
var pile_count: int:
	get: return difficulty_progression.pile_count
	set(value): difficulty_progression.pile_count = value
var hand_size: int:
	get: return difficulty_progression.hand_size
	set(value): difficulty_progression.hand_size = value
var start_value: int:
	get: return difficulty_progression.start_value
	set(value): difficulty_progression.start_value = value
var max_discovered_tile_value: int = Difficulty.START_CARD_VALUE
var turn_time: float:
	get: return difficulty_progression.turn_time
	set(value): difficulty_progression.turn_time = value
var round_number: int = Difficulty.TOTAL_ROUNDS
var best_rounds_left := -1
var best_score_time_ms := -1
var endless_unlocked := false
var endless_best_round := -1
var endless_best_time_ms := -1
var classic_no_mistake_rounds_left := -1
var classic_no_mistake_time_ms := -1
var endless_no_mistake_round := -1
var game_mode := GameMode.STANDARD
var challenge_manager := ChallengeManager.new()
var current_challenge: ChallengeData
var challenge_endless := false
var challenge_modifiers := ChallengeModifiers.new()
var difficulty_droughts: Dictionary:
	get: return difficulty_progression.droughts
	set(value): difficulty_progression.droughts = value
var run_mistake_count := 0
var run_lives_lost := 0
var run_completed_rounds := 0
var run_start_round := 1
var started_from_checkpoint := false
var unlocked_checkpoints: Array[int] = []
var checkpoint_snapshots: Dictionary = {}
var checkpoint_highscores: Dictionary = {}
var checkpoint_no_mistake_highscores: Dictionary = {}
var checkpoint_best_round := -1
var checkpoint_no_mistake_best_round := -1
var checkpoint_best_rounds_left := -1
var checkpoint_endless_best_round := -1
var checkpoint_no_mistake_rounds_left := -1
var checkpoint_endless_no_mistake_round := -1
var current_checkpoint_id := 0
var selected_checkpoint_id := 0
var checkpoint_uses_endless_progression := false
var checkpoint_segment_damage_count := 0
var checkpoint_bonus_backlog := 0
var _pending_checkpoint_snapshot: CheckpointSnapshot
var _quick_peek_pending := false
var discovered_bonuses: Array[StringName] = []
var seen_bonuses: Array[StringName] = []
var encountered_special_rules: Array[StringName] = []
var beaten_special_rules: Array[StringName] = []
var newly_discovered_bonuses: Array[StringName] = []
var newly_encountered_rules: Array[StringName] = []
var newly_unlocked_achievements: Array[StringName] = []
var newly_unlocked_fonts: Array[StringName] = []
var newly_unlocked_checkpoints: Array[int] = []
var unread_progression_pages: Array[int] = []
var unread_progression_items: Dictionary = {}
var achievement_manager := AchievementManager.new()
var font_manager := FontManager.new()
var palette_manager := ColorPaletteManager.new()
var _round_mistakes_at_start := 0
var game_started_msec := 0
var run_paused_msec := 0
var run_pause_started_msec := -1
var round_reached_time_ms := 0
var mistakes_left := 3
var maximum_mistakes := 3
var selected_card: PlayingCard
var piles: Array[MemoryPile] = []
var input_locked := true
var rng := RandomNumberGenerator.new()
var hovered_pile: MemoryPile
var drag_placeholder: Control
var _hand_slot_placeholders: Dictionary = {}
var drag_home_index := -1
var overlay_mode := ""
var _last_clock_second := -1
var _urgent_tick_index := 0
var _clock_flash_tween: Tween
var _menu_exit_tween: Tween
var _screen_transition_active := false
var _submenu_swipe_controller := SubmenuSwipeControllerScript.new()
var _run_transition_generation := 0
var _gameplay_generation := 0
var _replay_iris_radius := 0.0
var _replay_board_ready := false
var _splash_screen_index := -1
var round_modifiers := RoundModifiers.new()
var tier_reliefs_applied: int:
	get: return difficulty_progression.tier_reliefs_applied
	set(value): difficulty_progression.tier_reliefs_applied = value
var _debug_action_in_progress := false
var _restart_pile_reveal_pending := false
var _restart_hand_immediate_pending := false
var _debug_round_wins_queued := 0
var _reload_tutorial_hand_pending := false
var _preserve_timer_through_quick_peek := false
var _shared_clock_initialized := false
var _shared_clock_timeout_pending := false
var _shared_clock_mistake_feedback_active := false
var _conveyor_active := false
var _conveyor_left_to_right := true
var _conveyor_spawn_distance := 0.0
var _conveyor_unplayable_spawns := 0
var _lucky_conveyor_queue: Array[int] = []
var _debug_help_enabled := true
var _debug_probability_visible := false
var _hand_cycle_generation := 0
var _pending_interactive_generation := -1
var _regeneration_hand_check_pending := false
var _music_volume_before_mute := 100.0
var _sound_volume_before_mute := 100.0
var _options_page := OPTION_GAMEPLAY
var _adaptive_resolution := false
var _dust_enabled := true
var _background_enabled := true
var dust_pool: DustPool
var deformable_stripe_background: DeformableStripeBackground
var _dust_previous_positions: Dictionary = {}
var _achievement_notifications_enabled := true
var _global_timer_enabled := true
var _achievement_notification_queue: Array[AchievementData] = []
var _achievement_notification_active := false
var _achievement_popup_tween: Tween
var _important_announcement_sources: Dictionary = {}
var _achievement_resume_delay_pending := false
var _timer_display_hidden := false
var _timer_visibility_tween: Tween
var _gameplay_back_cursor_update_queued := false
var _last_reminder_pile: MemoryPile
var drag_companions: Array[PlayingCard] = []
var _companion_offsets: Dictionary = {}
var _companion_home_positions: Dictionary = {}
var _root_action_id := 0
var moving_pile: MemoryPile
var _moving_pile_offset := Vector2.ZERO
var _moving_pile_last_valid_position := Vector2.ZERO
var _moving_pile_pointer := Vector2.ZERO
var _pile_touch_index := -1
var _pile_touch_local_grab := Vector2.ZERO
var _card_touch_index := -1

@export_category("Start Transition")
@export var menu_swipe_duration := 0.62
@export_range(0.1, 0.8, 0.05, "suffix:s") var submenu_swipe_duration := 0.28
@export var gameplay_pop_duration := 0.24
@export var gameplay_pop_stagger := 0.1
@export var gameplay_pop_scale := 0.82
@export_range(0.1, 1.0, 0.05, "suffix:s") var replay_mask_duration := 0.3
@export_range(0.5, 3.0, 0.1, "suffix:s") var pile_value_hold_duration := 1.0
@export_category("Difficulty Announcement")
@export_range(0.0, 0.75, 0.05, "suffix:s")
var extra_difficulty_reveal_delay := 0.2
@export_range(0.0, 2.0, 0.05, "suffix:s")
var extra_difficulty_hold_duration := 0.45
@export_category("Visual Effects")
@export var dust_particles_per_10000_pixels := 6.0:
	set(value):
		dust_particles_per_10000_pixels = maxf(value, 0.0)
		_rebuild_dust_pool()
@export var dust_viscosity := 2.2:
	set(value):
		dust_viscosity = maxf(value, 0.0)
		if is_instance_valid(dust_pool):
			dust_pool.viscosity = dust_viscosity
@export var dust_particle_color := Color("77746d"):
	set(value):
		dust_particle_color = value
		if is_instance_valid(dust_pool):
			dust_pool.particle_color = dust_particle_color
			dust_pool.queue_redraw()
@export var dust_mouse_influence := 0.12
@export var dust_dragged_tile_influence := 1.0
@export var dust_automatic_tile_influence := 0.28
@export var dust_completion_wave_influence := 0.85
@export_category("Achievement Popup")
@export_range(0.0, 2.0, 0.05, "suffix:s")
var achievement_popup_after_announcements_delay := 0.25
@export_category("Editor Display")
@export var start_adaptive_in_editor := false


func _ready() -> void:
	rng.randomize()
	_submenu_swipe_controller.duration = submenu_swipe_duration
	add_child(achievement_manager)
	add_child(challenge_manager)
	add_child(font_manager)
	add_child(palette_manager)
	font_manager.definitions = progression_menu.get_available_fonts()
	palette_manager.definitions = progression_menu.get_available_palettes()
	achievement_manager.definitions = progression_menu.get_achievements()
	var default_font := progression_menu.get_default_font()
	if default_font != null:
		font_manager.selected_font = default_font.id
	var default_palette := progression_menu.get_default_palette()
	if default_palette != null:
		palette_manager.selected_palette = default_palette.id
	achievement_manager.load_progress()
	challenge_manager.load_progress()
	font_manager.load_progress()
	palette_manager.load_progress()
	_load_unread_progression_pages()
	# Unlock newly introduced cosmetic rewards for achievements already earned
	# by an existing save.
	for achievement_id in achievement_manager.unlocked:
		palette_manager.unlock_for_achievement(achievement_id)
	achievement_manager.achievement_unlocked.connect(_on_achievement_unlocked)
	hand_manager.card_selected.connect(_on_card_selected)
	hand_manager.card_drag_started.connect(_on_card_drag_started)
	hand_manager.card_drag_released.connect(_on_card_drag_released)
	hand_manager.card_entered_screen.connect(_on_card_entered_screen)
	hand_manager.card_forced_return_requested.connect(_on_card_forced_return_requested)
	lava_rule_controller.card_entered_lava.connect(_on_lava_card_entered)
	timer_manager.time_updated.connect(_on_time_updated)
	timer_manager.time_expired.connect(_on_time_expired)
	timer_manager.timer_visibility_requested.connect(_on_timer_visibility_requested)
	overlay_button.pressed.connect(_on_overlay_pressed)
	overlay_endless_button.pressed.connect(_on_overlay_endless_pressed)
	overlay_quit_button.pressed.connect(_return_to_menu)
	splash_button.pressed.connect(_on_splash_pressed)
	endless_button.pressed.connect(_on_endless_pressed)
	checkpoint_button.pressed.connect(_start_selected_checkpoint)
	checkpoint_up_button.pressed.connect(_select_next_checkpoint.bind(1))
	checkpoint_down_button.pressed.connect(_select_next_checkpoint.bind(-1))
	checkpoint_button.mouse_entered.connect(_show_selected_checkpoint)
	checkpoint_button.mouse_exited.connect(_refresh_high_score)
	checkpoint_button.focus_entered.connect(_show_selected_checkpoint)
	checkpoint_button.focus_exited.connect(_refresh_high_score)
	checkpoint_button.gui_input.connect(_on_checkpoint_button_input)
	checkpoint_back_button.pressed.connect(_close_checkpoint_menu)
	progression_button.pressed.connect(_open_progression_menu)
	challenge_button.pressed.connect(_open_challenge_selection)
	challenge_selection.challenge_selected.connect(_start_challenge)
	challenge_selection.closed.connect(_on_challenge_selection_closed)
	options_button.pressed.connect(_open_options_menu)
	options_back_button.pressed.connect(_close_options_menu)
	gameplay_options_button.pressed.connect(_show_options_page.bind(OPTION_GAMEPLAY))
	sound_options_button.pressed.connect(_show_options_page.bind(OPTION_SOUND))
	graphics_options_button.pressed.connect(_show_options_page.bind(OPTION_GRAPHICS))
	save_options_button.pressed.connect(_show_options_page.bind(OPTION_SAVE))
	links_options_button.pressed.connect(_show_options_page.bind(OPTION_LINKS))
	adaptive_resolution_button.pressed.connect(_toggle_adaptive_resolution)
	dust_effects_button.pressed.connect(_toggle_dust_effects)
	background_enabled_button.pressed.connect(_toggle_background)
	achievement_notifications_button.pressed.connect(
		_toggle_achievement_notifications
	)
	timer_display_button.pressed.connect(_toggle_timer_display)
	itch_link_button.pressed.connect(_open_external_link.bind(ITCH_URL))
	kofi_link_button.pressed.connect(_open_external_link.bind(KOFI_URL))
	export_save_button.pressed.connect(_open_export_save_dialog)
	import_save_button.pressed.connect(_open_import_save_dialog)
	delete_save_button.pressed.connect(_open_delete_save_confirmation)
	export_save_dialog.file_selected.connect(_export_save_json)
	import_save_dialog.file_selected.connect(_import_save_json)
	delete_save_confirmation.confirmed.connect(_delete_save)
	progression_menu.closed.connect(_on_progression_menu_closed)
	progression_menu.font_selected.connect(_on_progression_font_selected)
	progression_menu.palette_selected.connect(_on_progression_palette_selected)
	progression_menu.page_viewed.connect(_on_progression_page_viewed)
	endless_button.mouse_entered.connect(_show_endless_high_score)
	endless_button.mouse_exited.connect(_refresh_high_score)
	endless_button.focus_entered.connect(_show_endless_high_score)
	endless_button.focus_exited.connect(_refresh_high_score)
	special_rule_manager.rules_announcing.connect(_on_special_rules_announcing)
	special_rule_manager.rules_announcement_finished.connect(
		_on_special_rules_announcement_finished
	)
	special_rule_manager.rules_selected.connect(_on_special_rules_selected)
	bonus_manager.bonus_selected.connect(_on_bonus_selected)
	bonus_manager.bonuses_seen.connect(_on_bonuses_seen)
	bonus_selection.visibility_changed.connect(_on_bonus_selection_visibility_changed)
	redraw_button.pressed.connect(_on_redraw_pressed)
	back_button.pressed.connect(_open_quit_popup)
	quit_continue_button.pressed.connect(_close_quit_popup)
	quit_restart_button.pressed.connect(_restart_from_quit_popup)
	quit_run_button.pressed.connect(_return_to_menu)
	# The game control stays at 256x320 in adaptive mode, so its `resized`
	# signal does not track changes to the expanded viewport.
	get_viewport().size_changed.connect(_resize_dust_distribution)
	# CenterContainer can reposition the fixed game after the background setup.
	# Track that layout pass as well so Artwork remains in viewport space.
	item_rect_changed.connect(_resize_dust_distribution)
	_setup_gameplay_options()
	_setup_audio_controls()
	_style_option_list_buttons()
	_setup_graphics_options()
	_setup_dust_pool()
	_setup_save_dialogs()
	_load_high_score()
	_apply_debug_unlock_everything()
	_apply_debug_checkpoints()
	_refresh_checkpoint_button()
	splash_debug_mode.visible = Debug.is_enabled()
	input_locked = true
	splash.visible = true
	_refresh_debug_help()
	font_manager.select(font_manager.selected_font)
	_apply_tile_font()
	_apply_tile_palette()
	var debug_checkpoint := Debug.start_from_checkpoint()
	if debug_checkpoint > 0:
		call_deferred("start_from_checkpoint", debug_checkpoint)


func _setup_audio_controls() -> void:
	GameOptionsControllerScript.setup_audio(self)


func _style_option_list_buttons() -> void:
	GameOptionsControllerScript.style_buttons(self)


func _setup_gameplay_options() -> void:
	GameOptionsControllerScript.setup_gameplay(self)


func _toggle_achievement_notifications() -> void:
	GameOptionsControllerScript.toggle_achievement_notifications(self)


func _toggle_timer_display() -> void:
	GameOptionsControllerScript.toggle_timer(self)


func _save_gameplay_option(key: String, value: bool) -> void:
	GameOptionsControllerScript.save_gameplay(self, key, value)


func _refresh_gameplay_options() -> void:
	GameOptionsControllerScript.refresh_gameplay(self)


func _setup_graphics_options() -> void:
	GameOptionsControllerScript.setup_graphics(self)


func _setup_dust_pool() -> void:
	GameOptionsControllerScript.setup_dust_pool(self)


func _resize_dust_distribution() -> void:
	GameOptionsControllerScript.resize_dust_distribution(self)


func _dust_particle_target_count() -> int:
	return GameOptionsControllerScript.dust_particle_target_count(self)


func _rebuild_dust_pool() -> void:
	GameOptionsControllerScript.rebuild_dust_pool(self)


func _toggle_dust_effects() -> void:
	GameOptionsControllerScript.toggle_dust(self)


func _refresh_dust_option() -> void:
	GameOptionsControllerScript.refresh_dust(self)


func _toggle_background() -> void:
	GameOptionsControllerScript.toggle_background(self)


func _refresh_background_option() -> void:
	GameOptionsControllerScript.refresh_background(self)


func _is_background_deformation_active() -> bool:
	return _background_enabled and _dust_enabled


func _toggle_debug_unlock_everything() -> void:
	Debug.toggle_unlock_everything()
	get_tree().reload_current_scene()


func _apply_debug_unlock_everything() -> void:
	if not Debug.is_unlock_everything_enabled():
		return
	challenge_manager.debug_unlock_all = true
	max_discovered_tile_value = Difficulty.MAX_CARD_VALUE
	achievement_manager.unlocked.clear()
	for achievement in achievement_manager.definitions:
		achievement_manager.unlocked.append(achievement.id)
	font_manager.unlocked.clear()
	for font_data in font_manager.definitions:
		font_manager.unlocked.append(font_data.id)
	palette_manager.unlocked.clear()
	for palette_data in palette_manager.definitions:
		palette_manager.unlocked.append(palette_data.id)
	discovered_bonuses.clear()
	seen_bonuses.clear()
	for bonus_data in BonusRegistry.create_all():
		discovered_bonuses.append(bonus_data.id)
		seen_bonuses.append(bonus_data.id)
		achievement_manager.bonus_highest_levels[bonus_data.id] = bonus_data.max_level
		achievement_manager.bonuses_maxed_once[bonus_data.id] = true
	encountered_special_rules.clear()
	beaten_special_rules.clear()
	for rule_data in SpecialRuleRegistry.create_all_rules():
		encountered_special_rules.append(rule_data.id)
		beaten_special_rules.append(rule_data.id)
	challenge_manager.completed.clear()
	for challenge_data in challenge_manager.definitions:
		challenge_manager.completed.append(challenge_data.id)


func _set_adaptive_resolution(adaptive: bool) -> void:
	GameOptionsControllerScript.set_adaptive_resolution(self, adaptive)


func _toggle_adaptive_resolution() -> void:
	_set_adaptive_resolution(not _adaptive_resolution)


func _apply_resolution_mode() -> void:
	GameOptionsControllerScript.apply_resolution(self)


func _setup_save_dialogs() -> void:
	GameOptionsControllerScript.setup_save_dialogs(self)


func _open_export_save_dialog() -> void:
	save_status.text = ""
	export_save_dialog.popup_centered_ratio(0.85)


func _open_import_save_dialog() -> void:
	save_status.text = ""
	import_save_dialog.popup_centered_ratio(0.85)


func _open_delete_save_confirmation() -> void:
	delete_save_confirmation.popup_centered(Vector2i(210, 96))


func _export_save_json(path: String) -> void:
	GameOptionsControllerScript.export_save(self, path)


func _import_save_json(path: String) -> void:
	GameOptionsControllerScript.import_save(self, path)


func _delete_save() -> void:
	GameOptionsControllerScript.delete_save(self)


func _on_volume_changed(value: float, bus_name: StringName, config_key: String) -> void:
	GameOptionsControllerScript.volume_changed(
		self, value, bus_name, config_key
	)


func _apply_bus_volume(bus_name: StringName, linear_volume: float) -> void:
	GameOptionsControllerScript.apply_bus_volume(bus_name, linear_volume)


func _process(delta: float) -> void:
	debug_help.visible = (
		Debug.is_enabled()
		and _debug_help_enabled
		and not splash.visible
		and not overlay.visible
	)
	splash_debug_help.visible = (
		Debug.is_enabled()
		and _debug_help_enabled
		and splash.visible
		and not options_menu.visible
		and not checkpoint_menu.visible
		and not progression_menu.visible
		and not challenge_selection.visible
	)
	debug_probability_panel.visible = (
		Debug.is_enabled() and _debug_probability_visible
	)
	if debug_probability_panel.visible:
		debug_probability_panel.text = _difficulty_probability_debug_text()
	if run_time_label.visible:
		run_time_label.text = _format_duration(_total_time_milliseconds())
	if _regeneration_hand_check_pending and not input_locked:
		_regeneration_hand_check_pending = false
		_reroll_unplayable_hand()
	_try_start_touch_card_drag()
	_process_conveyor(delta)
	if (
		moving_pile != null
		and is_instance_valid(moving_pile)
		and _pile_touch_index < 0
	):
		moving_pile.global_position = (
			_moving_pile_pointer - _moving_pile_offset
		).round()
	_emit_motion_dust(delta)
	_update_tile_background_weight()
	if selected_card == null or not is_instance_valid(selected_card) or not selected_card.dragging:
		return
	for companion in drag_companions:
		if is_instance_valid(companion):
			companion.global_position = (
				selected_card.global_position
				+ (_companion_offsets.get(companion, Vector2.ZERO) as Vector2)
			).round()
	if round_modifiers.floor_is_lava_enabled:
		if lava_rule_controller.touches_card(selected_card):
			selected_card.request_forced_return(
				PlayingCard.ForcedReturnReason.LAVA
			)
			return
	var candidate := _pile_at(selected_card.drag_target)
	if candidate == hovered_pile:
		return
	if hovered_pile != null and is_instance_valid(hovered_pile):
		hovered_pile.set_drop_feedback(false)
	hovered_pile = candidate
	if hovered_pile != null:
		hovered_pile.set_drop_feedback(true)
		soft_audio.play_tone(520.0, 0.035, 0.035)


func _emit_motion_dust(delta: float) -> void:
	if not is_instance_valid(dust_pool) or delta <= 0.0:
		return
	var moving_items: Array[Dictionary] = []
	if selected_card != null and is_instance_valid(selected_card) and selected_card.dragging:
		moving_items.append({
			"control": selected_card,
			"impulse": dust_dragged_tile_influence,
		})
		for companion in drag_companions:
			if is_instance_valid(companion):
				moving_items.append({
					"control": companion,
					"impulse": dust_dragged_tile_influence * 0.42,
				})
	if round_modifiers.moving_pile_pattern:
		for pile in piles:
			if is_instance_valid(pile) and pile.visible and not pile.completed:
				moving_items.append({
					"control": pile,
					"impulse": dust_automatic_tile_influence,
				})
	elif moving_pile != null and is_instance_valid(moving_pile):
		moving_items.append({
			"control": moving_pile,
			"impulse": dust_dragged_tile_influence,
		})
	var active_ids: Array[int] = []
	for item in moving_items:
		var control := item["control"] as Control
		var center := control.get_global_rect().abs().get_center()
		var instance_id := control.get_instance_id()
		active_ids.append(instance_id)
		if _dust_previous_positions.has(instance_id):
			var previous := _dust_previous_positions[instance_id] as Vector2
			if previous.distance_squared_to(center) >= 4.0:
				dust_pool.emit_motion(
					center,
					(center - previous) / delta,
					float(item["impulse"])
				)
				deformable_stripe_background.emit_motion(
					center,
					(center - previous) / delta,
					float(item["impulse"])
				)
		_dust_previous_positions[instance_id] = center
	for tracked_id in _dust_previous_positions.keys():
		if not active_ids.has(int(tracked_id)):
			_dust_previous_positions.erase(tracked_id)


func _update_tile_background_weight() -> void:
	if not is_instance_valid(deformable_stripe_background):
		return
	var weighted_tiles: Array[Control] = []
	var strength_multipliers: Dictionary = {}
	for pile in piles:
		if is_instance_valid(pile) and pile.visible:
			weighted_tiles.append(pile)
			strength_multipliers[pile.get_instance_id()] = (
				deformable_stripe_background.pile_weight_multiplier
				* pile.background_weight
			)
	for card in hand_manager.current_cards:
		if is_instance_valid(card) and card.visible:
			weighted_tiles.append(card)
			strength_multipliers[card.get_instance_id()] = (
				deformable_stripe_background.card_weight_multiplier
			)
	var dragged_tile: Control = null
	if selected_card != null and is_instance_valid(selected_card) and selected_card.dragging:
		dragged_tile = selected_card
	elif moving_pile != null and is_instance_valid(moving_pile):
		dragged_tile = moving_pile
	deformable_stripe_background.set_tile_weights(
		weighted_tiles, dragged_tile, strength_multipliers
	)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if is_instance_valid(relief_lighting):
			relief_lighting.follow_pointer(
				mouse_motion.position, get_viewport_rect().size
			)
		if is_instance_valid(dust_pool):
			dust_pool.emit_motion(
				mouse_motion.position,
				mouse_motion.velocity,
				dust_mouse_influence
			)
			deformable_stripe_background.emit_motion(
				mouse_motion.position,
				mouse_motion.velocity,
				dust_mouse_influence
			)
	_update_gameplay_back_hover(event)
	if _is_gameplay_back_pointer_event(event):
		_set_input_as_handled()
		_open_quit_popup()
		return
	if _handle_global_shortcut(event):
		return
	if _handle_debug_shortcut(event):
		# A debug shortcut can reload the scene and detach this node immediately.
		_set_input_as_handled()
		return
	# Opening the confirmation does not pause either run clock. Its full-screen
	# Control blocks board input while the simulation continues normally.
	if quit_popup.visible:
		return
	if round_modifiers.flashlight_enabled:
		if event is InputEventScreenTouch or event is InputEventScreenDrag:
			flashlight_overlay.follow_touch(event.position)
	if _handle_pile_touch_input(event):
		_set_input_as_handled()
		return
	if _handle_card_touch_input(event):
		_set_input_as_handled()
		return
	if moving_pile != null and is_instance_valid(moving_pile):
		if event is InputEventMouseMotion or event is InputEventScreenDrag:
			_moving_pile_pointer = event.position
			moving_pile.global_position = (event.position - _moving_pile_offset).round()
		elif (
			(event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed)
			or (event is InputEventScreenTouch and not event.pressed)
		):
			_moving_pile_pointer = event.position
			moving_pile.global_position = (
				event.position - _moving_pile_offset
			).round()
			_finish_pile_move()
			_set_input_as_handled()
		return
	if selected_card == null or not is_instance_valid(selected_card) or not selected_card.dragging:
		return
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
		and selected_card.drag_state == PlayingCard.DragState.LOCKED_OUT
	):
		var clicked_pile := _pile_at(event.position)
		if clicked_pile != null:
			_on_card_drag_released(selected_card, event.position)
			_set_input_as_handled()
			return
	if event is InputEventMouseMotion:
		selected_card.drag_target = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_on_card_drag_released(selected_card, event.position)
		_set_input_as_handled()


func _set_input_as_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _is_gameplay_back_pointer_event(event: InputEvent) -> bool:
	if splash.visible or overlay.visible or quit_popup.visible or not back_button.visible:
		return false
	return _is_button_pointer_press(event, back_button)


func _update_gameplay_back_hover(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	if splash.visible or overlay.visible or quit_popup.visible or not back_button.visible:
		return
	var hovered := (
		back_button.get_global_rect().has_point(event.position)
	)
	back_button.set_pointer_hovered(hovered)
	if hovered and not _gameplay_back_cursor_update_queued:
		_gameplay_back_cursor_update_queued = true
		_apply_gameplay_back_cursor.call_deferred()


func _apply_gameplay_back_cursor() -> void:
	_gameplay_back_cursor_update_queued = false
	var viewport := get_viewport()
	# This deferred callback can outlive the node's attachment during a scene
	# reload or shutdown.
	if viewport == null:
		return
	var hovered := (
		back_button.visible
		and not splash.visible
		and not overlay.visible
		and back_button.get_global_rect().has_point(
			viewport.get_mouse_position()
		)
	)
	if hovered:
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_POINTING_HAND)


func _is_button_pointer_press(event: InputEvent, button: BaseButton) -> bool:
	var pointer_position := Vector2.ZERO
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
			return false
		pointer_position = event.position
	elif event is InputEventScreenTouch:
		if not event.pressed:
			return false
		pointer_position = event.position
	else:
		return false
	return button.get_global_rect().has_point(pointer_position)


func _handle_global_shortcut(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	match key_event.keycode:
		KEY_ESCAPE:
			if quit_popup.visible:
				_close_quit_popup()
				return true
			if progression_menu.visible:
				progression_menu.close()
				return true
			if options_menu.visible:
				_close_options_menu()
				return true
			if challenge_selection.visible:
				challenge_selection.close()
				return true
			if checkpoint_menu.visible:
				_close_checkpoint_menu()
				return true
			if splash.visible:
				if not OS.has_feature("web"):
					get_tree().quit()
			else:
				_open_quit_popup()
			return true
		KEY_ENTER, KEY_KP_ENTER:
			if quit_popup.visible:
				_return_to_menu()
				return true
		KEY_R:
			if quit_popup.visible:
				_restart_from_quit_popup()
				return true
		KEY_SPACE:
			if progression_menu.visible or options_menu.visible or challenge_selection.visible:
				return false
			if splash.visible or (overlay.visible and overlay_mode == "restart"):
				if overlay.visible:
					_restart_current_mode()
				else:
					start_game()
				return true
		KEY_M:
			_toggle_audio_sliders()
			return true
		KEY_T:
			if not splash.visible and not overlay.visible:
				_toggle_timer_display()
				if _global_timer_enabled:
					run_time_label.text = _format_duration(_total_time_milliseconds())
				return true
	return false


func _return_to_menu() -> void:
	if _screen_transition_active:
		return
	_screen_transition_active = true
	# Stop a round-completion coroutine that may currently be awaiting a bonus
	# choice; it must not resume behind the returning menu.
	_run_transition_generation += 1
	_gameplay_generation += 1
	_debug_round_wins_queued = 0
	input_locked = true
	timer_manager.stop_countdown()
	_splash_screen_index = splash.get_index()
	splash.reparent(menu_transition_layer, true)
	await _play_return_to_menu_transition()
	# The raised menu now covers the popup completely, so hiding it cannot cut
	# the animation short.
	bonus_selection.cancel()
	special_rule_manager.cancel_pending_round()
	quit_popup.visible = false
	await _reset_to_menu_state()
	splash.reparent(screens, true)
	if _splash_screen_index >= 0:
		screens.move_child(splash, _splash_screen_index)
	_screen_transition_active = false


func _reset_to_menu_state() -> void:
	# The raised Splash already presents the complete menu. Reset the run behind
	# it instead of reloading the scene, which would introduce a blank frame.
	_conveyor_active = false
	bonus_selection.cancel()
	active_bonus_bar.visible = false
	_hand_cycle_generation += 1
	_pending_interactive_generation = -1
	await cleanup_special_rule_state()
	await special_rule_manager.end_round(piles)
	bonus_manager.end_run()
	hand_manager.clear_hand(hand_container, true)
	_clear_drag_placeholder()
	for child in drag_layer.get_children():
		child.queue_free()
	for child in piles_board.get_children():
		child.queue_free()
	piles.clear()
	selected_card = null
	hovered_pile = null
	overlay.visible = false
	overlay_mode = ""
	back_button.visible = false
	run_time_label.visible = false
	music_manager.transition_to_menu_music()
	_refresh_checkpoint_button()
	_refresh_high_score()
	_refresh_debug_help()


func _open_quit_popup() -> void:
	if splash.visible or overlay.visible or quit_popup.visible:
		return
	quit_popup.visible = true
	quit_continue_button.release_focus()
	quit_restart_button.release_focus()
	quit_run_button.release_focus()


func _close_quit_popup() -> void:
	quit_popup.visible = false
	back_button.grab_focus()


func _restart_from_quit_popup() -> void:
	_restart_current_mode()


func _restart_current_mode() -> void:
	if _screen_transition_active:
		return
	_screen_transition_active = true
	# Invalidate an in-flight round-completion coroutine immediately. The replay
	# iris is allowed to cover that transition instead of waiting for it to end.
	_run_transition_generation += 1
	_gameplay_generation += 1
	_debug_round_wins_queued = 0
	input_locked = true
	timer_manager.stop_countdown()
	await _mask_replay_transition()
	# Keep the popup visible during the iris close and remove it only while the
	# transition color fully covers the old run.
	bonus_selection.cancel()
	special_rule_manager.cancel_pending_round()
	quit_popup.visible = false
	await cleanup_special_rule_state(false)
	await special_rule_manager.end_round(piles, false)
	_clear_gameplay_pieces_immediately()
	_replay_board_ready = false
	_restart_pile_reveal_pending = true
	_restart_hand_immediate_pending = true
	special_rule_manager.suppress_next_announcement = true
	if game_mode == GameMode.CHECKPOINT:
		# A checkpoint replay is a fresh attempt: discard the old loadout and let
		# the player make the checkpoint's bonus choices again.
		start_from_checkpoint(current_checkpoint_id)
	elif game_mode == GameMode.CHALLENGE:
		start_game(false, current_challenge, challenge_endless)
	else:
		start_game(game_mode == GameMode.ENDLESS)
	# Special-rule cleanup (notably pixelation) is asynchronous. Keep the iris
	# shut until the replacement board exists instead of exposing stale effects.
	var ready_deadline := Time.get_ticks_msec() + 3000
	while (
		not _replay_board_ready
		and not bonus_selection.visible
		and Time.get_ticks_msec() < ready_deadline
	):
		await get_tree().process_frame
	await _unmask_replay_transition()
	_screen_transition_active = false


func _mask_replay_transition() -> void:
	replay_transition_mask.visible = true
	replay_transition_mask.mouse_filter = Control.MOUSE_FILTER_STOP
	replay_transition_mask.modulate.a = 1.0
	var mask_size := replay_transition_mask.size
	var center := replay_transition_mask.get_local_mouse_position().clamp(
		Vector2.ZERO, mask_size
	)
	var material := replay_transition_mask.material as ShaderMaterial
	var center_uv := Vector2(center.x / mask_size.x, center.y / mask_size.y)
	var aspect_ratio := mask_size.x / mask_size.y
	material.set_shader_parameter(&"center_uv", center_uv)
	material.set_shader_parameter(&"aspect_ratio", aspect_ratio)
	_replay_iris_radius = _maximum_iris_radius(center_uv, aspect_ratio) + 0.02
	material.set_shader_parameter(&"radius", _replay_iris_radius)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(
		material, "shader_parameter/radius", 0.0, replay_mask_duration
	)
	await tween.finished


func _unmask_replay_transition() -> void:
	var material := replay_transition_mask.material as ShaderMaterial
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		material,
		"shader_parameter/radius",
		_replay_iris_radius,
		replay_mask_duration
	)
	await tween.finished
	replay_transition_mask.visible = false
	replay_transition_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _maximum_iris_radius(center_uv: Vector2, aspect_ratio: float) -> float:
	var top_left := (Vector2.ZERO - center_uv) * Vector2(aspect_ratio, 1.0)
	var top_right := (Vector2.RIGHT - center_uv) * Vector2(aspect_ratio, 1.0)
	var bottom_left := (Vector2.DOWN - center_uv) * Vector2(aspect_ratio, 1.0)
	var bottom_right := (Vector2.ONE - center_uv) * Vector2(aspect_ratio, 1.0)
	return maxf(
		maxf(top_left.length(), top_right.length()),
		maxf(bottom_left.length(), bottom_right.length())
	)


func _play_return_to_menu_transition() -> void:
	var splash_destination := splash.global_position
	# Position the menu from the viewport boundary, not from the fixed gameplay
	# size: adaptive aspect ratios can expose extra canvas below the game Control.
	splash.global_position.y = get_viewport_rect().end.y + 2.0
	splash.visible = true
	# Commit the off-screen placement before starting the tween. This prevents a
	# single frame at the old position when Splash has just changed CanvasLayer.
	await get_tree().process_frame
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		splash, "global_position:y", splash_destination.y, menu_swipe_duration
	)
	for element in _start_transition_elements():
		element.pivot_offset = element.size * 0.5
		tween.tween_property(
			element, "modulate:a", 0.0, gameplay_pop_duration
		)
		tween.tween_property(
			element,
			"scale",
			Vector2.ONE * gameplay_pop_scale,
			gameplay_pop_duration
		)
	await tween.finished


func _open_progression_menu() -> void:
	progression_menu.open(_progression_snapshot())
	_submenu_swipe_controller.open(progression_menu, get_viewport_rect().size.x)


func _open_options_menu() -> void:
	options_menu.visible = true
	_show_options_page(_options_page)
	_submenu_swipe_controller.open(options_menu, get_viewport_rect().size.x)
	match _options_page:
		OPTION_GAMEPLAY:
			achievement_notifications_button.grab_focus()
		OPTION_SOUND:
			music_volume_slider.grab_focus()
		OPTION_GRAPHICS:
			adaptive_resolution_button.grab_focus()
		OPTION_SAVE:
			export_save_button.grab_focus()
		OPTION_LINKS:
			itch_link_button.grab_focus()


func _show_options_page(page: int) -> void:
	_options_page = clampi(page, OPTION_GAMEPLAY, OPTION_LINKS)
	gameplay_options.visible = _options_page == OPTION_GAMEPLAY
	sound_options.visible = _options_page == OPTION_SOUND
	graphics_options.visible = _options_page == OPTION_GRAPHICS
	save_options.visible = _options_page == OPTION_SAVE
	links_options.visible = _options_page == OPTION_LINKS
	match _options_page:
		OPTION_GAMEPLAY:
			options_page_title.text = "GAMEPLAY"
		OPTION_SOUND:
			options_page_title.text = "SOUND"
		OPTION_GRAPHICS:
			options_page_title.text = "GRAPHICS"
		OPTION_SAVE:
			options_page_title.text = "SAVE DATA"
		OPTION_LINKS:
			options_page_title.text = "LINKS"
	gameplay_options_button.modulate = (
		OPTIONS_SELECTED_COLOR if _options_page == OPTION_GAMEPLAY else Color.WHITE
	)
	sound_options_button.modulate = (
		OPTIONS_SELECTED_COLOR if _options_page == OPTION_SOUND else Color.WHITE
	)
	graphics_options_button.modulate = (
		OPTIONS_SELECTED_COLOR if _options_page == OPTION_GRAPHICS else Color.WHITE
	)
	save_options_button.modulate = (
		OPTIONS_SELECTED_COLOR if _options_page == OPTION_SAVE else Color.WHITE
	)
	links_options_button.modulate = (
		OPTIONS_SELECTED_COLOR if _options_page == OPTION_LINKS else Color.WHITE
	)


func _open_external_link(url: String) -> void:
	if not url.begins_with("https://"):
		push_warning("Refusing to open a non-HTTPS external link.")
		return
	OS.shell_open(url)


func _close_options_menu() -> void:
	if not options_menu.visible:
		return
	await _submenu_swipe_controller.close(options_menu, get_viewport_rect().size.x)
	options_button.grab_focus()


func _on_progression_menu_closed() -> void:
	await _submenu_swipe_controller.close(
		progression_menu, get_viewport_rect().size.x
	)
	progression_button.grab_focus()


func _on_progression_font_selected(font_id: StringName) -> void:
	if font_manager.select(font_id):
		_apply_tile_font()
		progression_menu.refresh(_progression_snapshot())


func _on_progression_palette_selected(palette_id: StringName) -> void:
	if palette_manager.select(palette_id):
		_apply_tile_palette()
		progression_menu.refresh(_progression_snapshot())


func _apply_tile_font() -> void:
	var data := font_manager.find(font_manager.selected_font)
	if data == null:
		return
	hand_manager.value_font = data.font
	hand_manager.value_font_size = data.tile_font_size
	hand_manager.value_font_offset = data.tile_font_offset
	hand_manager.override_hidden_tile_with_font = data.override_hidden_tile_with_font
	for card in hand_manager.current_cards:
		if is_instance_valid(card):
			card.set_value_font(
				data.font,
				data.tile_font_size,
				data.tile_font_offset,
				data.override_hidden_tile_with_font
			)
	for pile in piles:
		if is_instance_valid(pile):
			pile.set_value_font(
				data.font,
				data.tile_font_size,
				data.tile_font_offset,
				data.override_hidden_tile_with_font
			)


func _apply_tile_palette() -> void:
	var data := palette_manager.find(palette_manager.selected_palette)
	if data == null:
		return
	var colors := data.normalized_colors()
	hand_manager.tile_colors = colors
	for card in hand_manager.current_cards:
		if is_instance_valid(card):
			card.set_tile_palette(colors)
	for pile in piles:
		if is_instance_valid(pile):
			pile.set_tile_palette(colors)


func _progression_snapshot() -> Dictionary:
	return ProgressionSnapshotBuilderScript.build(self)


func _load_unread_progression_pages() -> void:
	ProgressionUnreadStoreScript.load(self)


func _mark_progression_page_unread(page: int) -> void:
	ProgressionUnreadStoreScript.mark_page(self, page)


func _mark_progression_item_unread(page: int, item_id: StringName) -> void:
	ProgressionUnreadStoreScript.mark_item(self, page, item_id)


func _is_progression_item_unread(page: int, item_id: StringName) -> bool:
	return ProgressionUnreadStoreScript.is_item_unread(self, page, item_id)


func _on_progression_page_viewed(page: int) -> void:
	ProgressionUnreadStoreScript.mark_page_viewed(self, page)


func _save_unread_progression_pages() -> void:
	ProgressionUnreadStoreScript.save(self)


func _refresh_progression_notification() -> void:
	ProgressionUnreadStoreScript.refresh_notification(self)


func _progression_highscores() -> Array[Dictionary]:
	return ProgressionSnapshotBuilderScript.highscores(self)


func _progression_achievements() -> Array[Dictionary]:
	return ProgressionSnapshotBuilderScript.achievements(self)


func _progression_bonuses() -> Array[Dictionary]:
	return ProgressionSnapshotBuilderScript.bonuses(self)


func _progression_special_rules() -> Array[Dictionary]:
	return ProgressionSnapshotBuilderScript.special_rules(self)


func _progression_fonts() -> Array[Dictionary]:
	return ProgressionSnapshotBuilderScript.fonts(self)


func _progression_palettes() -> Array[Dictionary]:
	return ProgressionSnapshotBuilderScript.palettes(self)


func _toggle_audio_sliders() -> void:
	var sliders_are_muted := (
		is_zero_approx(music_volume_slider.value)
		and is_zero_approx(sound_volume_slider.value)
	)
	if sliders_are_muted:
		music_volume_slider.value = _music_volume_before_mute
		sound_volume_slider.value = _sound_volume_before_mute
		return
	_music_volume_before_mute = music_volume_slider.value
	_sound_volume_before_mute = sound_volume_slider.value
	music_volume_slider.value = 0.0
	sound_volume_slider.value = 0.0


func _handle_debug_shortcut(event: InputEvent) -> bool:
	if not Debug.is_enabled() or not event is InputEventKey:
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	# The main menu only exposes debug actions that operate on menu/progression
	# state. Gameplay controls must not leak through the hidden board; notably R
	# must never restart a run from behind the Splash.
	if splash.visible and key_event.keycode not in [KEY_F1, KEY_U, KEY_H]:
		return false
	# Result screens and modal menus own their explicit shortcuts. Keep all
	# unrelated debug gameplay actions dormant while one of them is open.
	if (
		(overlay.visible or quit_popup.visible or progression_menu.visible
		or options_menu.visible or challenge_selection.visible
		or checkpoint_menu.visible)
		and key_event.keycode != KEY_F1
	):
		return false
	# Round wins are intentionally queueable so rapid debug presses can drive a
	# run through successive rounds while skipping transition animations.
	if key_event.keycode == KEY_E:
		if splash.visible or overlay.visible:
			return false
		_debug_win_round()
		return true
	if _debug_action_in_progress and key_event.keycode != KEY_R:
		return false
	match key_event.keycode:
		KEY_F1:
			_debug_help_enabled = not _debug_help_enabled
			return true
		KEY_U:
			_toggle_debug_unlock_everything()
			return true
		KEY_S:
			if splash.visible or overlay.visible:
				return false
			music_manager.request_next_section()
			_refresh_debug_help()
			return true
		KEY_G:
			Debug.toggle_god_mode()
			_refresh_debug_help()
			return true
		KEY_P:
			_debug_probability_visible = not _debug_probability_visible
			debug_probability_panel.visible = _debug_probability_visible
			if _debug_probability_visible:
				debug_probability_panel.text = _difficulty_probability_debug_text()
			_refresh_debug_help()
			return true
		KEY_V:
			relief_lighting.toggle_debug_boost()
			_refresh_debug_help()
			return true
		KEY_R:
			_debug_reset_game()
			return true
		KEY_H:
			_debug_reset_progression()
			return true
		KEY_L:
			if splash.visible or overlay.visible or input_locked:
				return false
			_debug_lose_life()
			return true
		KEY_K:
			if splash.visible or overlay.visible or input_locked:
				return false
			_debug_die()
			return true
	return false


func _debug_win_round() -> void:
	_debug_round_wins_queued += 1
	# Debug round completion supersedes the current turn. Stop its timer before
	# raising time scale, otherwise it can expire during the few locked transition
	# frames and resolve as delayed damage in a later round.
	timer_manager.stop_countdown()
	_shared_clock_timeout_pending = false
	if skippable_sequence.can_skip:
		skippable_sequence.skip_to_end()
	if _debug_action_in_progress:
		return
	_debug_action_in_progress = true
	var previous_time_scale := Engine.time_scale
	Engine.time_scale = maxf(previous_time_scale, 20.0)
	while _debug_round_wins_queued > 0 and not splash.visible and not overlay.visible:
		timer_manager.stop_countdown()
		_shared_clock_timeout_pending = false
		var transition_frames := 0
		while input_locked and not overlay.visible and transition_frames < 5:
			await get_tree().process_frame
			transition_frames += 1
		if overlay.visible:
			break
		# A queued debug win deliberately supersedes any remaining transition.
		input_locked = false
		_debug_round_wins_queued -= 1
		await _finish_round()
	_debug_round_wins_queued = 0
	Engine.time_scale = previous_time_scale
	_debug_action_in_progress = false


func _debug_lose_life() -> void:
	_debug_action_in_progress = true
	await _handle_mistake(null, false, true)
	_debug_action_in_progress = false


func _debug_die() -> void:
	_debug_action_in_progress = true
	# Use the regular mistake pipeline so audio, counters, discoveries and the
	# game-over transition remain representative of a real run.
	mistakes_left = 1
	await _handle_mistake(null, false, true)
	_debug_action_in_progress = false


func _debug_reset_game() -> void:
	_debug_action_in_progress = true
	await _restart_current_mode()
	_debug_action_in_progress = false


func _debug_reset_progression() -> void:
	best_rounds_left = -1
	best_score_time_ms = -1
	classic_no_mistake_rounds_left = -1
	classic_no_mistake_time_ms = -1
	endless_best_round = -1
	endless_best_time_ms = -1
	endless_no_mistake_round = -1
	endless_unlocked = false
	unlocked_checkpoints.clear()
	checkpoint_snapshots.clear()
	checkpoint_highscores.clear()
	checkpoint_no_mistake_highscores.clear()
	checkpoint_best_round = -1
	checkpoint_no_mistake_best_round = -1
	checkpoint_best_rounds_left = -1
	checkpoint_endless_best_round = -1
	checkpoint_no_mistake_rounds_left = -1
	checkpoint_endless_no_mistake_round = -1
	current_checkpoint_id = 0
	checkpoint_bonus_backlog = 0
	selected_checkpoint_id = 0
	discovered_bonuses.clear()
	max_discovered_tile_value = Difficulty.START_CARD_VALUE
	seen_bonuses.clear()
	encountered_special_rules.clear()
	beaten_special_rules.clear()
	challenge_manager.debug_unlock_all = false
	challenge_manager.completed.clear()
	challenge_manager.highscores.clear()
	challenge_manager.endless_highscores.clear()
	challenge_manager.best_times_ms.clear()
	achievement_manager.unlocked.clear()
	achievement_manager.unlock_dates.clear()
	achievement_manager.bonuses_maxed_once.clear()
	achievement_manager.bonus_highest_levels.clear()
	font_manager.unlocked.clear()
	for font_data in font_manager.definitions:
		if font_data.default_unlocked:
			font_manager.unlocked.append(font_data.id)
	var default_font := progression_menu.get_default_font()
	font_manager.selected_font = (
		default_font.id if default_font != null else &"press_start_2p"
	)
	font_manager.select(font_manager.selected_font)
	palette_manager.unlocked.clear()
	for palette_data in palette_manager.definitions:
		if palette_data.default_unlocked:
			palette_manager.unlocked.append(palette_data.id)
	var default_palette := progression_menu.get_default_palette()
	palette_manager.selected_palette = (
		default_palette.id if default_palette != null else &"arcade"
	)
	palette_manager.select(palette_manager.selected_palette)
	_apply_tile_font()
	_apply_tile_palette()
	var config := ConfigFile.new()
	if config.load("user://pile_down.cfg") == OK:
		# Whole sections are removed so achievements and progression fields added
		# in future versions are reset without extending this debug command.
		for section in [
			"progress", "highscores", "checkpoints", "progression", "challenges"
		]:
			if config.has_section(section):
				config.erase_section(section)
		if config.has_section_key("settings", "selected_font"):
			config.erase_section_key("settings", "selected_font")
		if config.has_section_key("settings", "selected_palette"):
			config.erase_section_key("settings", "selected_palette")
		config.save("user://pile_down.cfg")
	endless_unlocked = Debug.unlock_endless_mode()
	endless_button.visible = endless_unlocked
	_refresh_checkpoint_button()
	_refresh_high_score()


func _refresh_debug_help() -> void:
	if not Debug.is_enabled():
		debug_help.visible = false
		splash_debug_help.visible = false
		return
	var help_text := (
		"[U] TOGGLE UNLOCK EVERYTHING\n"
		+ "[E] WIN CURRENT ROUND\n"
		+ "[S] NEXT MUSIC SECTION\n"
		+ "[G] GOD MODE: %s\n" % ("ON" if Debug.is_god_mode_enabled() else "OFF")
		+ "[R] RESET GAME\n"
		+ "[H] CLEAR GLOBAL PROGRESSION\n"
		+ "[L] LOSE ONE LIFE\n"
		+ "[K] DIE NOW\n"
		+ "[P] DIFFICULTY PROBABILITIES: %s\n" % (
			"ON" if _debug_probability_visible else "OFF"
		)
		+ "[V] RELIEF LIGHT BOOST: %s\n" % (
			"ON" if relief_lighting.debug_boosted else "OFF"
		)
		+ "[T] SHOW RUN TIME\n"
		+ "[M] MUTE AUDIO\n"
		+ "[F1] HIDE DEBUG HELP\n"
		+ "[ESC] BACK TO MENU"
	)
	debug_help.text = help_text
	splash_debug_help.text = help_text
	splash_debug_help.visible = _debug_help_enabled and splash.visible


func _difficulty_probability_debug_text() -> String:
	return difficulty_progression.probability_debug_text(_progression_round())


func start_game(
	endless_mode := false,
	challenge_data: ChallengeData = null,
	challenge_is_endless := false
) -> void:
	_gameplay_generation += 1
	var animate_menu_exit := splash.visible
	back_button.visible = not animate_menu_exit
	current_challenge = challenge_data
	challenge_endless = challenge_is_endless
	_reload_tutorial_hand_pending = (
		challenge_data != null and challenge_data.id == &"reload_required"
	)
	challenge_modifiers = (
		challenge_manager.modifiers_for(current_challenge)
		if current_challenge != null
		else ChallengeModifiers.new()
	)
	_configure_challenge_hand_tray()
	bonus_manager.disabled_bonus_ids.assign(challenge_modifiers.disabled_bonuses)
	special_rule_manager.disabled_rule_ids.assign(challenge_modifiers.disabled_special_rules)
	special_rule_manager.forced_rule_ids.assign(
		current_challenge.forced_rules if current_challenge != null else []
	)
	special_rule_manager.force_rules_every_round = (
		challenge_modifiers.force_special_rules_every_round
	)
	special_rule_manager.forced_rule_count = challenge_modifiers.forced_special_rule_count
	special_rule_manager.disable_rules_on_challenge_first_round = (
		current_challenge != null
		and challenge_modifiers.disable_special_rules_on_first_round
	)
	special_rule_manager.challenge_start_round = (
		current_challenge.start_round if current_challenge != null else 1
	)
	special_rule_manager.challenge_target_round = (
		current_challenge.target_round if current_challenge != null else 1
	)
	special_rule_manager.challenge_endless = challenge_endless
	game_mode = (
		GameMode.CHALLENGE
		if current_challenge != null
		else (GameMode.ENDLESS if endless_mode else GameMode.STANDARD)
	)
	soft_audio.play_start()
	music_manager.set_low_pass_enabled(false, true)
	_hand_cycle_generation += 1
	_pending_interactive_generation = -1
	pile_count = Difficulty.START_PILES
	hand_size = Difficulty.START_HAND_SIZE
	start_value = Difficulty.START_CARD_VALUE
	turn_time = Difficulty.START_TURN_TIME
	tier_reliefs_applied = 0
	difficulty_droughts = _new_difficulty_droughts()
	run_mistake_count = 0
	run_lives_lost = 0
	run_completed_rounds = 0
	started_from_checkpoint = false
	checkpoint_segment_damage_count = 0
	newly_discovered_bonuses.clear()
	newly_encountered_rules.clear()
	newly_unlocked_achievements.clear()
	newly_unlocked_fonts.clear()
	newly_unlocked_checkpoints.clear()
	current_checkpoint_id = 0
	checkpoint_bonus_backlog = 0
	_pending_checkpoint_snapshot = null
	if game_mode == GameMode.CHALLENGE:
		round_number = (
			current_challenge.start_round
			if challenge_endless
			else current_challenge.target_round - current_challenge.start_round
		)
		run_start_round = current_challenge.start_round
		started_from_checkpoint = false
		_apply_debug_progression(current_challenge.start_round)
		_apply_challenge_starting_difficulty(current_challenge)
	elif game_mode == GameMode.ENDLESS:
		round_number = 1
		run_start_round = 1
	else:
		var debug_start_round := Debug.get_start_round(Difficulty.TOTAL_ROUNDS)
		started_from_checkpoint = debug_start_round > 1
		run_start_round = debug_start_round
		round_number = Difficulty.TOTAL_ROUNDS - debug_start_round + 1
		_apply_debug_progression(debug_start_round)
	music_manager.reset_game_sections(tier_reliefs_applied + 1)
	music_manager.transition_to_game_music()
	game_started_msec = Time.get_ticks_msec()
	run_paused_msec = 0
	run_pause_started_msec = game_started_msec
	round_reached_time_ms = 0
	run_time_label.visible = _global_timer_enabled
	overlay.visible = false
	quit_popup.visible = false
	overlay_mode = ""
	bonus_manager.begin_run()
	if current_challenge != null:
		bonus_manager.grant_starting_bonuses(current_challenge.forced_bonuses)
	if animate_menu_exit:
		_prepare_gameplay_start_reveal()
		_update_hud()
		_finish_animated_game_start()
	else:
		splash.visible = false
		start_round()


func _finish_animated_game_start() -> void:
	await _play_start_game_transition()
	start_round()


func _prepare_gameplay_start_reveal() -> void:
	# During the transition, keep ESC behind the sliding splash like the other
	# gameplay elements. Its interactive z-index is restored once gameplay owns
	# the screen.
	back_button.visible = true
	back_button.z_index = 0
	for element in _start_transition_elements():
		element.pivot_offset = element.size * 0.5
		element.modulate.a = 0.0
		element.scale = Vector2.ONE * gameplay_pop_scale


func _play_start_game_transition() -> void:
	if _menu_exit_tween != null and _menu_exit_tween.is_valid():
		_menu_exit_tween.kill()
	var splash_origin := splash.position
	_menu_exit_tween = (
		create_tween()
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_IN)
	)
	_menu_exit_tween.tween_property(
		splash,
		"position:y",
		splash_origin.y + size.y + 8.0,
		menu_swipe_duration
	)
	var elements := _start_transition_elements()
	for index in elements.size():
		var element := elements[index]
		var reveal := (
			element.create_tween()
			.set_parallel()
			.set_trans(Tween.TRANS_BACK)
			.set_ease(Tween.EASE_OUT)
		)
		reveal.tween_property(
			element,
			"modulate:a",
			1.0,
			gameplay_pop_duration
		).set_delay(index * gameplay_pop_stagger)
		reveal.tween_property(
			element,
			"scale",
			Vector2.ONE,
			gameplay_pop_duration
		).set_delay(index * gameplay_pop_stagger)
	await _menu_exit_tween.finished
	splash.visible = false
	splash.position = splash_origin
	back_button.visible = true
	back_button.z_index = 10


func _start_transition_elements() -> Array[Control]:
	return [timer_ring, round_panel, back_button, piles_board, hand_tray]


func _restore_gameplay_transition_elements() -> void:
	# Checkpoint starts do not use the ordinary menu-exit animation. Restore the
	# controls faded by the preceding quit transition before revealing gameplay.
	for element in _start_transition_elements():
		element.modulate.a = 1.0
		element.scale = Vector2.ONE
	back_button.z_index = 10


func start_round() -> void:
	var gameplay_generation := _gameplay_generation
	_resume_run_time()
	input_locked = true
	_emit_difficulty_stats()
	_round_mistakes_at_start = run_mistake_count
	_capture_checkpoint_candidate()
	sticky_fingers_controller.end_round()
	mirror_match_controller.end_round(self)
	_regeneration_hand_check_pending = false
	selected_card = null
	hovered_pile = null
	maximum_mistakes = 3
	_last_clock_second = -1
	_urgent_tick_index = 0
	timer_manager.stop_countdown()
	_shared_clock_initialized = false
	_shared_clock_timeout_pending = false
	_conveyor_active = false
	hand_manager.clear_hand(hand_container)
	_clear_drag_placeholder()
	for child in drag_layer.get_children():
		child.queue_free()
	for child in piles_board.get_children():
		child.queue_free()
	piles.clear()
	_last_reminder_pile = null
	bonus_manager.begin_round()
	round_modifiers = await special_rule_manager.begin_round(_progression_round())
	if gameplay_generation != _gameplay_generation:
		return
	round_modifiers.hide_tile_numbers = challenge_modifiers.hide_tile_numbers
	var rule_intensity := bonus_manager.adaptation_multiplier()
	if round_modifiers.hot_potatoes_enabled:
		round_modifiers.hot_potato_drag_duration /= rule_intensity
	sticky_fingers_controller.begin_round(
		round_modifiers.sticky_fingers_enabled
	)
	if round_modifiers.mirror_match_enabled:
		mirror_match_controller.begin_round(self, round_modifiers)
	maximum_mistakes = (
		1
		if challenge_modifiers.force_single_life
		else round_modifiers.maximum_mistakes_override
		if round_modifiers.maximum_mistakes_override > 0
		else 3 + bonus_manager.spare_lives()
	)
	mistakes_left = maximum_mistakes
	mistakes_dots.set_maximum(maximum_mistakes)
	mistakes_dots.set_reinforced_count(
		0
		if round_modifiers.sudden_death_enabled
		else bonus_manager.spare_lives()
	)
	mistakes_dots.set_safety_net_active(
		bonus_manager.safety_net_available
	)

	for index in pile_count:
		var pile := PILE_SCENE.instantiate() as MemoryPile
		piles_board.add_child(pile)
		var selected_palette_data := palette_manager.find(
			palette_manager.selected_palette
		)
		if selected_palette_data != null:
			pile.set_tile_palette(selected_palette_data.normalized_colors())
		var selected_font_data := font_manager.find(font_manager.selected_font)
		if selected_font_data != null:
			pile.set_value_font(
				selected_font_data.font,
				selected_font_data.tile_font_size,
				selected_font_data.tile_font_offset,
				selected_font_data.override_hidden_tile_with_font
			)
		pile.setup(
			index,
			start_value,
			round_modifiers.stack_direction,
			round_modifiers.roman_numerals_enabled,
			round_modifiers.colorblind_enabled,
			round_modifiers.hide_tile_numbers
		)
		pile.set_movable(bonus_manager.has_bonus(&"pile_mover"))
		pile.pile_selected.connect(_on_pile_selected)
		pile.drag_requested.connect(_on_pile_drag_requested)
		pile.drag_released.connect(_on_pile_drag_released)
		pile.regenerated.connect(_on_pile_regenerated)
		piles.append(pile)
	_layout_piles()
	_replay_board_ready = true
	for index in piles.size():
		piles[index].play_entrance(index * 0.055)
	var open_book_count := bonus_manager.level(&"open_book")
	if open_book_count > 0:
		var open_book_candidates := piles.duplicate()
		open_book_candidates.shuffle()
		for index in mini(open_book_count, open_book_candidates.size()):
			open_book_candidates[index].keep_face_up = true
	_update_hud()
	# Start the readable hold only once the final entrance has completed. The old
	# timing included entrance motion, leaving the number legible for too little
	# time before its flip.
	var last_pile_entrance_delay := maxf(float(piles.size() - 1) * 0.055, 0.0)
	var pile_reveal_duration := (
		last_pile_entrance_delay + 0.25 + pile_value_hold_duration
	)
	if _restart_pile_reveal_pending:
		pile_reveal_duration += RESTART_PILE_REVEAL_BONUS
	_restart_pile_reveal_pending = false
	await get_tree().create_timer(
		0.0 if _debug_action_in_progress else pile_reveal_duration
	).timeout
	if gameplay_generation != _gameplay_generation:
		return
	# Continuous movement owns pile.position, so start it only after every
	# entrance tween has released that property. Position-dependent board
	# effects are generated afterwards from the final movement layout.
	await special_rule_manager.activate_board_effects(piles, _progression_round())
	if gameplay_generation != _gameplay_generation:
		return
	if round_modifiers.floor_is_lava_enabled:
		lava_rule_controller.generate(
			_progression_round(),
			piles,
			hand_container,
			timer_ring,
			lava_layer,
			rng
		)
	for pile in piles:
		if is_instance_valid(pile):
			pile.hide_value(true)
	await get_tree().create_timer(0.0 if _debug_action_in_progress else 0.26).timeout
	if gameplay_generation != _gameplay_generation:
		return
	_begin_turn()


func _layout_piles() -> void:
	if piles.is_empty() or piles_board.size.x <= 0.0:
		return
	var piece_size := 37.0
	var gap := 7.0
	var positions := PileLayoutManager.positions_for_2d(pile_count, piece_size, gap)
	var center := piles_board.size * 0.5
	var slots: Array[Vector2] = []
	for index in mini(piles.size(), positions.size()):
		var pile := piles[index]
		pile.custom_minimum_size = Vector2(34.0, 37.0)
		pile.size = Vector2(34.0, 37.0)
		pile.position = (center + positions[index] - Vector2(17.0, 18.0)).round()
		slots.append(pile.position)
	pile_manager.configure(piles_board, piles, slots)


func _begin_turn(
	hand_prepared := false,
	enter_from_right := false,
	preserve_timer := false
) -> void:
	if _all_piles_complete():
		# Debug round skipping can reach this point while the previous completed
		# board is being replaced; never leave the transition permanently locked.
		input_locked = false
		return
	selected_card = null
	input_locked = true
	if not hand_prepared:
		if enter_from_right:
			_generate_next_hand(
				_hand_cycle_generation, true, true, not preserve_timer
			)
		else:
			await _prepare_next_hand(true, false)
	if _quick_peek_pending:
		return
	if enter_from_right:
		_pending_interactive_generation = _hand_cycle_generation
		# Deferred entrance methods mark themselves running after layout. Wait
		# one frame before deciding that a hand contains retained cards only.
		await get_tree().process_frame
		if _pending_interactive_generation != _hand_cycle_generation:
			return
		if not hand_manager.current_cards.any(
			func(card: PlayingCard) -> bool:
				return (
					is_instance_valid(card)
					and card._entrance_animation_running
				)
		):
			_pending_interactive_generation = -1
			input_locked = false
			hand_manager.unlock_hand()
			_resolve_pending_shared_clock_timeout()
			return
	input_locked = false
	hand_manager.unlock_hand()
	_resolve_pending_shared_clock_timeout()


func _prepare_next_hand(clear_existing: bool, enter_from_right: bool) -> void:
	var requested_generation := _hand_cycle_generation
	if _restart_hand_immediate_pending:
		_restart_hand_immediate_pending = false
	elif not _debug_action_in_progress:
		await music_manager.wait_for_next_hand_beat()
	_generate_next_hand(requested_generation, clear_existing, enter_from_right)


func _generate_next_hand(
	requested_generation: int,
	clear_existing: bool,
	enter_from_right: bool,
	start_timer := true
) -> void:
	if requested_generation != _hand_cycle_generation or _all_piles_complete():
		return
	var wandering_cards := round_modifiers.wandering_hand_cards
	if clear_existing:
		_clear_all_hand_slot_placeholders()
	if challenge_modifiers.conveyor_hand:
		if not _conveyor_active:
			_start_conveyor()
		_start_turn_countdown(bonus_manager.next_hand_time(turn_time))
		redraw_button.visible = false
		_quick_peek_pending = false
		return
	var force_reload_tutorial_hand := _reload_tutorial_hand_pending
	_reload_tutorial_hand_pending = false
	hand_manager.generate_hand(
		drag_layer if wandering_cards else hand_container,
		hand_size,
		start_value,
		_playable_values_with_duplicates(),
		round_modifiers.stack_direction == RoundModifiers.StackDirection.UP,
		round_modifiers.hover_reveal_enabled,
		round_modifiers.roman_numerals_enabled,
		not wandering_cards,
		clear_existing,
		enter_from_right,
		round_modifiers,
		bonus_manager.joker_chance(),
		bonus_manager.consume_forced_joker(),
		bonus_manager.lucky_hand_chance(),
		bonus_manager.level(&"lucky_hand"),
		bonus_manager.level(&"double_down"),
		bonus_manager.level(&"deja_vu"),
		piles,
		challenge_modifiers.guarantee_playable_hand,
		force_reload_tutorial_hand
	)
	if wandering_cards:
		_draw_wandering_hand()
	var challenge_reload := (
		game_mode == GameMode.CHALLENGE
		and current_challenge.id == &"reload_required"
	)
	redraw_button.set_as_hand_slot(hand_container, false)
	redraw_button.visible = (
		(challenge_reload or bonus_manager.redraws_left > 0)
		and not wandering_cards
	)
	# Reload is always visible in its challenge, so its hover feedback is the
	# icon highlight rather than a tooltip popup over the hand.
	redraw_button.tooltip_text = "" if challenge_reload else "REDRAW"
	redraw_button.set_remaining(
		bonus_manager.redraws_left,
		bonus_manager.level(&"redraw") >= 2
	)
	_quick_peek_pending = bonus_manager.should_trigger_quick_peek()
	if _quick_peek_pending:
		input_locked = true
		hand_manager.lock_hand()
		call_deferred("_run_quick_peek")
	elif start_timer:
		_start_turn_countdown(bonus_manager.next_hand_time(turn_time))


func _draw_wandering_hand() -> void:
	var occupied: Array[Rect2] = []
	for pile in piles:
		if is_instance_valid(pile) and not pile.completed:
			occupied.append(pile.get_global_rect().abs().grow(5.0))
	for index in hand_manager.current_cards.size():
		var card := hand_manager.current_cards[index]
		if not is_instance_valid(card):
			continue
		var position_candidate := Vector2.ZERO
		for attempt in 24:
			position_candidate = Vector2(
				rng.randi_range(38, 184),
				rng.randi_range(58, 190)
			)
			var card_rect := Rect2(position_candidate, Vector2(34.0, 37.0))
			if not occupied.any(func(rect: Rect2) -> bool: return rect.intersects(card_rect)):
				break
		card.global_position = position_candidate.round()
		occupied.append(card.get_global_rect().abs().grow(5.0))
		card.play_wandering_entrance(
			index,
			position_candidate.round(),
			size,
			index * 0.055
		)


func _start_conveyor() -> void:
	_conveyor_active = true
	_conveyor_spawn_distance = 0.0
	_conveyor_unplayable_spawns = 0
	_lucky_conveyor_queue.clear()
	# Cards enter directly from the right in the hand lane, then cross over the
	# life counter before leaving on the left.
	_conveyor_left_to_right = false
	_spawn_conveyor_card()


func _process_conveyor(delta: float) -> void:
	if not _conveyor_active or overlay.visible or splash.visible:
		return
	var speed := Difficulty.get_conveyor_speed(
		_progression_round(),
		challenge_modifiers.conveyor_speed
		if challenge_modifiers.conveyor_speed >= 0.0
		else Difficulty.CONVEYOR_BASE_SPEED
	)
	var direction := 1.0 if _conveyor_left_to_right else -1.0
	for card in hand_manager.current_cards.duplicate():
		if not is_instance_valid(card) or not card.has_meta(&"conveyor_card"):
			continue
		if (
			card == selected_card
			or card.dragging
			or card.drag_state != PlayingCard.DragState.IDLE
		):
			continue
		if card.has_meta(&"conveyor_exiting_down"):
			card.global_position.y += (
				speed * Difficulty.CONVEYOR_EXIT_SPEED_MULTIPLIER * delta
			)
		else:
			card.global_position.x += speed * direction * delta
			if (
				not _conveyor_left_to_right
				and card.get_global_rect().get_center().x
				<= hand_tray.conveyor_turn_point_x
			):
				card.global_position.x = (
					hand_tray.conveyor_turn_point_x - card.size.x * 0.5
				)
				card.set_meta(&"conveyor_exiting_down", true)
		var outside: bool = (
			card.global_position.y > get_viewport_rect().size.y + card.size.y
			if card.has_meta(&"conveyor_exiting_down")
			else card.global_position.x > get_viewport_rect().size.x + card.size.x
		)
		if outside:
			hand_manager.forget_card(card)
			card.queue_free()
	_conveyor_spawn_distance += speed * delta
	while _conveyor_spawn_distance >= Difficulty.CONVEYOR_MIN_CARD_SPACING:
		_spawn_conveyor_card()
		_conveyor_spawn_distance -= Difficulty.CONVEYOR_MIN_CARD_SPACING
	_refresh_conveyor_pointer_hover()


func _refresh_conveyor_pointer_hover() -> void:
	var card_under_pointer := false
	for card in hand_manager.current_cards:
		if (
			is_instance_valid(card)
			and card.has_meta(&"conveyor_card")
			and card.refresh_pointer_hover()
		):
			card_under_pointer = true
	if hand_tray.get_global_rect().has_point(get_global_mouse_position()):
		DisplayServer.cursor_set_shape(
			DisplayServer.CURSOR_POINTING_HAND
			if card_under_pointer
			else DisplayServer.CURSOR_ARROW
		)


func _spawn_conveyor_card() -> PlayingCard:
	var playable_values := _playable_values_with_duplicates()
	if playable_values.is_empty():
		return null
	var force_playable := (
		_conveyor_unplayable_spawns
		>= (
			challenge_modifiers.conveyor_guaranteed_interval
			if challenge_modifiers.conveyor_guaranteed_interval > 0
			else Difficulty.CONVEYOR_MAX_UNPLAYABLE_SPAWNS
		)
	)
	var useful_card_visible := false
	for existing_card in hand_manager.active_cards():
		if (
			existing_card.has_meta(&"conveyor_card")
			and not existing_card.has_meta(&"conveyor_exiting_down")
			and not existing_card.dragging
			and playable_values.has(existing_card.card_value)
		):
			useful_card_visible = true
			break
	# Random junk is allowed only while a solution is already on screen. The
	# player can miss that card, but can never lose because no solution spawned.
	force_playable = force_playable or not useful_card_visible
	var lucky := (
		bonus_manager.lucky_hand_chance() > 0.0
		and rng.randf() < bonus_manager.lucky_hand_chance()
	)
	var value := rng.randi_range(
		1 if round_modifiers.stack_direction == RoundModifiers.StackDirection.UP else 0,
		start_value if round_modifiers.stack_direction == RoundModifiers.StackDirection.UP else start_value - 1
	)
	var spawn_high_tile := (
		not force_playable
		and not lucky
		and round_modifiers.stack_direction == RoundModifiers.StackDirection.DOWN
		and start_value < Difficulty.MAX_CARD_VALUE
		and rng.randf() < Difficulty.CONVEYOR_HIGH_TILE_CHANCE
	)
	if spawn_high_tile:
		value = rng.randi_range(start_value + 1, Difficulty.MAX_CARD_VALUE)
	if lucky and _lucky_conveyor_queue.is_empty():
		var lucky_value := hand_manager.get_most_advanced_value(
			playable_values,
			round_modifiers.stack_direction == RoundModifiers.StackDirection.UP
		)
		_lucky_conveyor_queue.append(lucky_value)
		for copy_index in mini(
			bonus_manager.level(&"deja_vu"),
			maxi(playable_values.count(lucky_value) - 1, 0)
		):
			_lucky_conveyor_queue.append(lucky_value)
		var step := (
			1
			if round_modifiers.stack_direction == RoundModifiers.StackDirection.UP
			else -1
		)
		for chain_index in bonus_manager.level(&"double_down"):
			var chain_value := lucky_value + step * (chain_index + 1)
			if chain_value >= 0 and chain_value <= start_value:
				_lucky_conveyor_queue.append(chain_value)
	if not _lucky_conveyor_queue.is_empty():
		value = _lucky_conveyor_queue.pop_front()
	elif force_playable:
		value = hand_manager.get_most_advanced_value(
			playable_values,
			round_modifiers.stack_direction == RoundModifiers.StackDirection.UP
		)
	if playable_values.has(value):
		_conveyor_unplayable_spawns = 0
	else:
		_conveyor_unplayable_spawns += 1
	var card := hand_manager._create_card(
		drag_layer,
		value,
		false,
		round_modifiers.hover_reveal_enabled,
		round_modifiers.roman_numerals_enabled,
		round_modifiers,
		false,
		false
	)
	card.set_meta(&"conveyor_card", true)
	_return_card_to_conveyor(card)
	return card


func _return_card_to_conveyor(card: PlayingCard) -> void:
	if not is_instance_valid(card):
		return
	if card.get_parent() != drag_layer:
		card.reparent(drag_layer, false)
	var tray_rect := hand_tray.get_global_rect()
	# Spawn the whole tile beyond the right edge. It only becomes visible after
	# the belt has physically carried it onto the screen.
	var entry_x := get_viewport_rect().size.x + 2.0
	for other in hand_manager.current_cards:
		if (
			is_instance_valid(other)
			and other != card
			and other.has_meta(&"conveyor_card")
			and absf(other.global_position.x - entry_x)
			< Difficulty.CONVEYOR_MIN_CARD_SPACING
		):
			entry_x += (
				-Difficulty.CONVEYOR_MIN_CARD_SPACING
				if _conveyor_left_to_right
				else Difficulty.CONVEYOR_MIN_CARD_SPACING
			)
	card.global_position = Vector2(
		entry_x,
		tray_rect.get_center().y
		+ Difficulty.CONVEYOR_CARD_VERTICAL_OFFSET
		- card.size.y * 0.5
	)
	card.set_meta(&"conveyor_card", true)
	card.remove_meta(&"conveyor_exiting_down")


func _configure_challenge_hand_tray() -> void:
	hand_tray.set_conveyor_enabled(challenge_modifiers.conveyor_hand)


func _on_card_selected(card: PlayingCard) -> void:
	if input_locked:
		return
	if (
		selected_card == card
		and card.drag_state == PlayingCard.DragState.LOCKED_OUT
	):
		return
	if (
		selected_card != null
		and is_instance_valid(selected_card)
		and selected_card != card
		and (
			selected_card.drag_state == PlayingCard.DragState.LOCKED_OUT
			or selected_card.dragging
			or selected_card._drag_starting
			or selected_card.get_parent() == drag_layer
		)
	):
		hand_manager.select_card(selected_card)
		return
	selected_card = card


func _on_card_entered_screen(card: PlayingCard) -> void:
	if (
		_pending_interactive_generation != _hand_cycle_generation
		or not hand_manager.current_cards.has(card)
	):
		return
	_pending_interactive_generation = -1
	selected_card = null
	input_locked = false
	hand_manager.unlock_hand()


func _on_card_drag_started(card: PlayingCard, tactile := false) -> void:
	if input_locked:
		return
	# A single hand may only own one drag transition. Without this guard,
	# rapid presses can reparent several cards before the first release and
	# leave them outside the container's layout.
	if card.drag_state != PlayingCard.DragState.IDLE or card._drag_starting:
		return
	if (
		selected_card != null
		and is_instance_valid(selected_card)
		and selected_card != card
		and (
			selected_card.dragging
			or selected_card._drag_starting
			or selected_card.get_parent() == drag_layer
		)
	):
		card.flash_error()
		return
	# A Sticky Fingers card remains under the pointer. Every click therefore
	# reaches its button again, but must not create another hand placeholder.
	if (
		selected_card == card
		and card.drag_state == PlayingCard.DragState.LOCKED_OUT
	):
		return
	if (
		selected_card != null
		and is_instance_valid(selected_card)
		and selected_card != card
		and selected_card.drag_state == PlayingCard.DragState.LOCKED_OUT
	):
		card.flash_error()
		return
	selected_card = card
	if round_modifiers.wandering_hand_cards or challenge_modifiers.conveyor_hand:
		drag_home_index = -1
		_clear_drag_placeholder()
	else:
		_remove_orphan_drag_placeholders()
		drag_home_index = card.get_index()
		drag_placeholder = _create_hand_slot_placeholder(card)
	hand_manager.lock_all_cards_except(card)
	_prepare_drag_companions(card)
	card.prepare_external_drag(tactile)
	var start_position := card.global_position
	if card.get_parent() != drag_layer:
		card.reparent(drag_layer, false)
	card.global_position = start_position
	card.begin_external_drag(card.drag_target, tactile)
	if challenge_modifiers.commit_selected_cards:
		card.begin_commit()
		if challenge_modifiers.hide_selected_card_value:
			for companion in drag_companions:
				if is_instance_valid(companion):
					companion.begin_commit()
	soft_audio.play_tone(330.0, 0.045, 0.035)


func _prepare_drag_companions(main_card: PlayingCard) -> void:
	drag_companions.clear()
	_companion_offsets.clear()
	_companion_home_positions.clear()
	var level := bonus_manager.level(&"bring_a_friend")
	if level <= 0 or round_modifiers.wandering_hand_cards:
		return
	var cards := hand_manager.active_cards()
	var main_index := cards.find(main_card)
	if main_index < 0:
		return
	var candidates: Array[PlayingCard] = []
	if level == 1:
		if main_index + 1 < cards.size():
			candidates.append(cards[main_index + 1])
		elif main_index > 0:
			candidates.append(cards[main_index - 1])
	elif level == 2:
		if main_index > 0:
			candidates.append(cards[main_index - 1])
		if main_index + 1 < cards.size():
			candidates.append(cards[main_index + 1])
	else:
		for card in cards:
			if card != main_card:
				candidates.append(card)
	for index in candidates.size():
		var companion := candidates[index]
		_companion_home_positions[companion] = companion.hand_return_position()
		_create_hand_slot_placeholder(companion)
		companion.set_selectable(false)
		companion.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var start_position := companion.global_position
		companion.reparent(drag_layer, false)
		companion.global_position = start_position
		drag_layer.move_child(companion, 0)
		drag_companions.append(companion)
		var centered_x := (float(index) - float(candidates.size() - 1) * 0.5) * 23.0
		_companion_offsets[companion] = Vector2(centered_x, 16.0 + absf(centered_x) * 0.08)


func _resolve_companion_drops(anchor_pile: MemoryPile) -> Array[MemoryPile]:
	var placed_piles: Array[MemoryPile] = []
	var companions := drag_companions.duplicate()
	drag_companions.clear()
	for companion_variant in companions:
		var companion := companion_variant as PlayingCard
		if not is_instance_valid(companion) or companion.placement_confirmed:
			continue
		var target := _find_nearby_companion_pile(
			companion, anchor_pile, placed_piles
		)
		if target != null:
			await _stack_card(
				companion, target,
				PlacementContext.new(PlacementContext.Source.BRING_A_FRIEND, _root_action_id)
			)
			placed_piles.append(target)
		else:
			await _return_companion_to_hand(companion)
	hand_container.queue_sort()
	await get_tree().process_frame
	_record_stable_hand_layout()
	_companion_offsets.clear()
	_companion_home_positions.clear()
	return placed_piles


func _find_nearby_companion_pile(
	companion: PlayingCard,
	anchor_pile: MemoryPile,
	already_used: Array[MemoryPile]
) -> MemoryPile:
	if anchor_pile == null or not is_instance_valid(anchor_pile):
		return null
	var anchor_center := anchor_pile.global_position + anchor_pile.size * 0.5
	var compatible := pile_manager.find_piles_accepting_value(companion.card_value)
	compatible.erase(anchor_pile)
	for used_pile in already_used:
		compatible.erase(used_pile)
	compatible = compatible.filter(
		func(candidate: MemoryPile) -> bool:
			var candidate_center := candidate.global_position + candidate.size * 0.5
			return (
				candidate_center.distance_to(anchor_center)
				<= Difficulty.BRING_A_FRIEND_NEIGHBOR_RADIUS
			)
	)
	compatible.sort_custom(
		func(first: MemoryPile, second: MemoryPile) -> bool:
			var first_center := first.global_position + first.size * 0.5
			var second_center := second.global_position + second.size * 0.5
			var first_distance := first_center.distance_squared_to(anchor_center)
			var second_distance := second_center.distance_squared_to(anchor_center)
			if is_equal_approx(first_distance, second_distance):
				return first.pile_index < second.pile_index
			return first_distance < second_distance
	)
	return compatible.front() if not compatible.is_empty() else null


func _return_drag_companions() -> void:
	var companions := drag_companions.duplicate()
	drag_companions.clear()
	for companion_variant in companions:
		var companion := companion_variant as PlayingCard
		if is_instance_valid(companion):
			await _return_companion_to_hand(companion)
	hand_container.queue_sort()
	await get_tree().process_frame
	_record_stable_hand_layout()
	_companion_offsets.clear()
	_companion_home_positions.clear()


func _return_companion_to_hand(card: PlayingCard) -> void:
	var destination := (
		_companion_home_positions.get(card, card.hand_return_position()) as Vector2
	)
	var placeholder := _valid_hand_slot_placeholder(card)
	var slot_index := (
		placeholder.get_index()
		if is_instance_valid(placeholder) and placeholder.get_parent() == hand_container
		else -1
	)
	await card.animate_return(destination, 0.2)
	_remove_hand_slot_placeholder(card)
	card.reparent(hand_container, false)
	if slot_index >= 0:
		hand_container.move_child(card, mini(slot_index, hand_container.get_child_count() - 1))
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.reset_hand_pose()
	card.set_selectable(not input_locked)


func _on_card_drag_released(card: PlayingCard, release_position: Vector2) -> void:
	if input_locked or card != selected_card or not card.dragging:
		return
	_card_touch_index = -1
	var target := _pile_at(release_position)
	if hovered_pile != null and is_instance_valid(hovered_pile):
		hovered_pile.set_drop_feedback(false)
	hovered_pile = null
	if target == null:
		if (
			round_modifiers.sticky_fingers_enabled
			or challenge_modifiers.commit_selected_cards
		):
			card.keep_attached_to_pointer()
			hand_manager.finish_all_card_entrances(card)
			hand_manager.lock_all_cards_except(card)
			return
		card.finish_drag()
		await _return_drag_companions()
		if challenge_modifiers.conveyor_hand:
			await _discard_rejected_conveyor_card(card)
			selected_card = null
			hand_manager.clear_selection()
			hand_manager.unlock_hand()
			return
		await _return_card_to_hand(card)
		card.set_selectable(true)
		selected_card = null
		hand_manager.clear_selection()
		hand_manager.unlock_hand()
	elif card.is_joker or target.can_accept(card.card_value):
		card.finish_drag()
		await _place_selected_card(target)
	else:
		card.finish_drag()
		await _return_drag_companions()
		await _handle_mistake(target)


func _on_pile_selected(pile: MemoryPile) -> void:
	if (
		input_locked
		or selected_card == null
		or not is_instance_valid(selected_card)
		or selected_card.drag_state != PlayingCard.DragState.LOCKED_OUT
	):
		return
	_on_card_drag_released(
		selected_card,
		pile.global_position + pile.size * 0.5
	)


func _on_pile_drag_requested(pile: MemoryPile, pointer_position: Vector2) -> void:
	if (
		input_locked
		or not bonus_manager.has_bonus(&"pile_mover")
		or selected_card != null
		or pile.completed
		or moving_pile != null
	):
		return
	moving_pile = pile
	_pile_touch_index = -1
	_moving_pile_pointer = pointer_position
	_moving_pile_offset = pointer_position - pile.global_position
	_moving_pile_last_valid_position = pile.position
	special_rule_manager.moving_pile_pattern.begin_manual_move(pile)
	pile.move_to_front()


func _on_pile_drag_released(pile: MemoryPile, pointer_position: Vector2) -> void:
	if pile == moving_pile:
		_moving_pile_pointer = pointer_position
		moving_pile.global_position = (
			pointer_position - _moving_pile_offset
		).round()
		_finish_pile_move()


func _finish_pile_move() -> void:
	if moving_pile == null or not is_instance_valid(moving_pile):
		moving_pile = null
		_pile_touch_index = -1
		return
	var requested_position := moving_pile.position
	moving_pile.position = _nearest_valid_pile_position(
		moving_pile,
		requested_position,
		_moving_pile_last_valid_position
	)
	pile_manager.refresh_slots_from_current_positions()
	special_rule_manager.moving_pile_pattern.finish_manual_move(moving_pile)
	moving_pile = null
	_pile_touch_index = -1


func _nearest_valid_pile_position(
	pile: MemoryPile,
	requested_position: Vector2,
	fallback_position: Vector2
) -> Vector2:
	var movement_bounds := _pile_movement_bounds(pile)
	var minimum := movement_bounds.position
	var maximum := movement_bounds.end
	var clamped_request := Vector2(
		clampf(requested_position.x, minimum.x, maximum.x),
		clampf(requested_position.y, minimum.y, maximum.y)
	)
	pile.position = clamped_request.round()
	if _is_valid_pile_position(pile):
		return pile.position

	# A coarse board-wide pass finds the closest legal region without making
	# release time depend on the distance from an invalid drop. The local
	# pixel pass below then removes the small grid approximation.
	const SEARCH_STEP := 4
	var found := false
	var best_position := fallback_position
	var best_distance_squared := INF
	for y in range(floori(minimum.y), ceili(maximum.y) + 1, SEARCH_STEP):
		for x in range(floori(minimum.x), ceili(maximum.x) + 1, SEARCH_STEP):
			var candidate := Vector2(x, y)
			var distance_squared := candidate.distance_squared_to(clamped_request)
			if distance_squared >= best_distance_squared:
				continue
			pile.position = candidate
			if _is_valid_pile_position(pile):
				found = true
				best_position = candidate
				best_distance_squared = distance_squared

	if found:
		var refine_minimum := (best_position - Vector2.ONE * SEARCH_STEP).max(minimum)
		var refine_maximum := (best_position + Vector2.ONE * SEARCH_STEP).min(maximum)
		for y in range(floori(refine_minimum.y), ceili(refine_maximum.y) + 1):
			for x in range(floori(refine_minimum.x), ceili(refine_maximum.x) + 1):
				var candidate := Vector2(x, y)
				var distance_squared := candidate.distance_squared_to(clamped_request)
				if distance_squared >= best_distance_squared:
					continue
				pile.position = candidate
				if _is_valid_pile_position(pile):
					best_position = candidate
					best_distance_squared = distance_squared
		return best_position

	pile.position = fallback_position
	return fallback_position


func _pile_movement_bounds(pile: MemoryPile) -> Rect2:
	# PilesBoard is a direct child of the game Control and does not clip its
	# children. Negative/local positions therefore safely expose the margins
	# around the original compact board.
	const SCREEN_MARGIN := 2.0
	var minimum := -piles_board.position + Vector2.ONE * SCREEN_MARGIN
	var maximum := (
		size
		- piles_board.position
		- pile.size
		- Vector2.ONE * SCREEN_MARGIN
	)
	return Rect2(minimum, (maximum - minimum).max(Vector2.ZERO))


func _is_valid_pile_position(pile: MemoryPile) -> bool:
	var candidate_rect := _transformed_control_rect(pile)
	var screen_rect := _transformed_control_rect(self).grow(-2.0)
	if not screen_rect.encloses(candidate_rect):
		return false
	var forbidden_controls: Array[Control] = [
		hand_tray,
	]
	for forbidden in forbidden_controls:
		if (
			forbidden.visible
			and candidate_rect.intersects(_transformed_control_rect(forbidden))
		):
			return false
	for other in piles:
		if not is_instance_valid(other) or other == pile or other.completed:
			continue
		var center := candidate_rect.get_center()
		var other_center := _transformed_control_rect(other).get_center()
		if center.distance_to(other_center) < Difficulty.MINIMUM_PILE_DISTANCE:
			return false
	if round_modifiers.floor_is_lava_enabled and lava_rule_controller.touches_rect(candidate_rect):
		return false
	return true


func _handle_pile_touch_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if moving_pile != null:
				return _pile_touch_index == touch.index
			if (
				input_locked
				or not bonus_manager.has_bonus(&"pile_mover")
				or selected_card != null
			):
				return false
			var touched_pile := _pile_at(touch.position)
			if touched_pile == null:
				return false
			moving_pile = touched_pile
			_pile_touch_index = touch.index
			_moving_pile_pointer = touch.position
			_moving_pile_last_valid_position = touched_pile.position
			_pile_touch_local_grab = (
				touched_pile.get_global_transform().affine_inverse()
				* touch.position
			)
			special_rule_manager.moving_pile_pattern.begin_manual_move(
				touched_pile
			)
			touched_pile.move_to_front()
			return true
		if (
			moving_pile != null
			and is_instance_valid(moving_pile)
			and _pile_touch_index == touch.index
		):
			_update_touch_pile_position(touch.position)
			_finish_pile_move()
			return true
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if (
			moving_pile != null
			and is_instance_valid(moving_pile)
			and _pile_touch_index == drag.index
		):
			_update_touch_pile_position(drag.position)
			return true
	return false


func _update_touch_pile_position(pointer_position: Vector2) -> void:
	if moving_pile == null or not is_instance_valid(moving_pile):
		return
	_moving_pile_pointer = pointer_position
	var parent_item := moving_pile.get_parent() as CanvasItem
	if parent_item == null:
		return
	var pointer_in_parent := (
		parent_item.get_global_transform().affine_inverse()
		* pointer_position
	)
	var grab_offset := moving_pile.get_transform().basis_xform(
		_pile_touch_local_grab
	)
	moving_pile.position = pointer_in_parent - grab_offset


func _handle_card_touch_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if selected_card != null and is_instance_valid(selected_card):
				if (
					challenge_modifiers.commit_selected_cards
					and selected_card.drag_state == PlayingCard.DragState.LOCKED_OUT
				):
					_card_touch_index = touch.index
					selected_card.touch_index = touch.index
					selected_card.drag_state = PlayingCard.DragState.DRAGGING
					selected_card.update_touch_drag(touch.position)
					return true
				return _card_touch_index == touch.index
			if input_locked:
				return false
			var touched_card := _card_at_touch_position(touch.position)
			if touched_card == null:
				return false
			_card_touch_index = touch.index
			touched_card.drag_target = touch.position
			_on_card_selected(touched_card)
			touched_card.begin_touch_interaction(touch.index, touch.position)
			return true
		if (
			selected_card != null
			and is_instance_valid(selected_card)
			and _card_touch_index == touch.index
		):
			if selected_card.dragging:
				selected_card.update_touch_drag(touch.position)
				_on_card_drag_released(selected_card, touch.position)
			else:
				selected_card.update_touch_interaction(touch.position)
				selected_card.finish_touch_tap()
				_card_touch_index = -1
				selected_card = null
				hand_manager.clear_selection()
			return true
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if (
			selected_card != null
			and is_instance_valid(selected_card)
			and _card_touch_index == drag.index
		):
			if selected_card.dragging:
				selected_card.update_touch_drag(drag.position)
			else:
				selected_card.update_touch_interaction(drag.position)
				_try_start_touch_card_drag()
			return true
	return false


func _try_start_touch_card_drag() -> void:
	if (
		_card_touch_index < 0
		or selected_card == null
		or not is_instance_valid(selected_card)
		or selected_card.dragging
		or not selected_card.touch_drag_is_ready()
	):
		return
	selected_card.drag_target = selected_card.touch_position
	_on_card_drag_started(selected_card, true)
	if selected_card.dragging:
		selected_card.update_touch_drag(selected_card.touch_position)


func _card_at_touch_position(touch_position: Vector2) -> PlayingCard:
	for index in range(hand_manager.current_cards.size() - 1, -1, -1):
		var card := hand_manager.current_cards[index]
		if (
			not is_instance_valid(card)
			or not card.visible
			or not card.selectable
			or card.placement_confirmed
		):
			continue
		var local_point := (
			card.get_global_transform().affine_inverse()
			* touch_position
		)
		if Rect2(Vector2.ZERO, card.size).has_point(local_point):
			return card
	return null


func _transformed_control_rect(control: Control) -> Rect2:
	var transform := control.get_global_transform()
	var corners: Array[Vector2] = [
		transform * Vector2.ZERO,
		transform * Vector2(control.size.x, 0.0),
		transform * control.size,
		transform * Vector2(0.0, control.size.y),
	]
	var minimum := corners[0]
	var maximum := corners[0]
	for corner in corners:
		minimum = minimum.min(corner)
		maximum = maximum.max(corner)
	return Rect2(minimum, maximum - minimum)


func _on_card_forced_return_requested(card: PlayingCard, _reason: int) -> void:
	if (
		input_locked
		or card != selected_card
		or not is_instance_valid(card)
		or card.placement_confirmed
	):
		return
	input_locked = true
	_card_touch_index = -1
	if hovered_pile != null and is_instance_valid(hovered_pile):
		hovered_pile.set_drop_feedback(false)
	hovered_pile = null
	await _return_drag_companions()
	await _return_card_to_hand(card, 0.2)
	card.complete_forced_return()
	card.set_selectable(true)
	selected_card = null
	hand_manager.clear_selection()
	input_locked = false
	hand_manager.unlock_hand()
	if timer_manager.time_left <= 0.0:
		await _handle_mistake(null, true)


func _on_pile_regenerated(_pile: MemoryPile, _delta: int) -> void:
	_regeneration_hand_check_pending = true


func _reroll_unplayable_hand() -> void:
	if not challenge_modifiers.guarantee_playable_hand:
		return
	if hand_manager.current_cards.is_empty():
		return
	var playable_values := _playable_values()
	if playable_values.is_empty():
		return
	for card in hand_manager.current_cards:
		if is_instance_valid(card) and card.visible and playable_values.has(card.card_value):
			return

	_hand_cycle_generation += 1
	_pending_interactive_generation = _hand_cycle_generation
	selected_card = null
	input_locked = true
	timer_manager.stop_countdown()
	_start_discard_current_hand()
	_generate_next_hand(_hand_cycle_generation, false, true)


func _place_selected_card(pile: MemoryPile) -> void:
	_hand_cycle_generation += 1
	var placement_generation := _hand_cycle_generation
	input_locked = true
	if challenge_modifiers.shared_round_clock:
		timer_manager.add_time(bonus_manager.shared_clock_time_bonus(turn_time))
	else:
		bonus_manager.bank_remaining_time(timer_manager.time_left)
		timer_manager.stop_countdown()
	hand_manager.lock_hand()
	var card := selected_card
	var placed_value := pile.expected_value() if card.is_joker else card.card_value
	var origin := card.global_position
	_root_action_id += 1
	var context := PlacementContext.new(PlacementContext.Source.PLAYER, _root_action_id)
	var combo_summary := HandComboSummary.new()
	combo_summary.root_action_id = context.root_action_id
	combo_summary.bonus_levels = bonus_manager.active_levels()
	var affected_piles: Array[MemoryPile] = []
	await _stack_card(card, pile, context)
	affected_piles.append(pile)
	combo_summary.bring_a_friend_total_companions = drag_companions.size()
	var companion_piles := await _resolve_companion_drops(pile)
	combo_summary.bring_a_friend_count = companion_piles.size()
	combo_summary.bring_a_friend_all_succeeded = (
		combo_summary.bring_a_friend_total_companions > 0
		and combo_summary.bring_a_friend_count
		== combo_summary.bring_a_friend_total_companions
	)
	for companion_pile in companion_piles:
		if not affected_piles.has(companion_pile):
			affected_piles.append(companion_pile)
	if bonus_manager.has_bonus(&"deja_vu"):
		var deja_piles := await _resolve_deja_vu(
			placed_value, pile, bonus_manager.level(&"deja_vu"), origin, context.root_action_id
		)
		combo_summary.deja_vu_count = deja_piles.size()
		for deja_pile in deja_piles:
			if not affected_piles.has(deja_pile):
				affected_piles.append(deja_pile)
	if bonus_manager.has_bonus(&"double_down") and not pile.completed:
		combo_summary.double_down_count = await _resolve_double_down(
			pile, bonus_manager.level(&"double_down"), origin, context.root_action_id
		)
	if not affected_piles.has(pile):
		affected_piles.append(pile)
	await _finalize_placement_action(affected_piles)
	achievement_manager.hand_combo_resolved.emit(combo_summary)
	if _all_piles_complete():
		await _finish_round()
		return
	if challenge_modifiers.conveyor_hand:
		selected_card = null
		input_locked = false
		hand_manager.unlock_hand()
		_start_turn_countdown(bonus_manager.next_hand_time(turn_time))
		return
	_start_discard_current_hand()
	if placement_generation == _hand_cycle_generation:
		await _begin_turn(false, true)


func _stack_card(
	card: PlayingCard,
	pile: MemoryPile,
	context: PlacementContext
) -> void:
	if not is_instance_valid(card) or not is_instance_valid(pile) or pile.completed:
		return
	if card.get_parent() == hand_container:
		var previous_global_position := card.global_position
		_create_hand_slot_placeholder(card)
		card.reparent(drag_layer, false)
		card.global_position = previous_global_position
	card.confirm_drop()
	var destination := pile.global_position + (pile.size - card.size) * 0.5
	var placement_duration := (
		Difficulty.BONUS_CHAIN_PLACEMENT_DURATION
		if (
			context.source == PlacementContext.Source.DOUBLE_DOWN
			or context.source == PlacementContext.Source.DEJA_VU
		)
		else Difficulty.AUTOMATIC_PLACEMENT_DURATION
	)
	await card.animate_valid_drop(destination, placement_duration)
	var placed_value := pile.expected_value() if card.is_joker else card.card_value
	pile.place(placed_value)
	deformable_stripe_background.emit_tile_impact_wave(
		pile.get_global_rect().abs().get_center()
	)
	if bonus_manager.has_bonus(&"last_reminder") and not pile.is_complete_value():
		if (
			_last_reminder_pile != null
			and is_instance_valid(_last_reminder_pile)
			and _last_reminder_pile != pile
			and not _last_reminder_pile.bonus_highlight
		):
			_last_reminder_pile.keep_face_up = false
			_last_reminder_pile.set_bonus_revealed(false)
		pile.keep_face_up = true
		_last_reminder_pile = pile
	card_placed.emit(card, pile)
	soft_audio.play_tone(610.0, 0.075, 0.055)
	card.visible = false
	hand_manager.forget_card(card)
	card.queue_free()


func _resolve_deja_vu(
	played_value: int,
	original_pile: MemoryPile,
	maximum_copies: int,
	origin: Vector2,
	root_action_id: int
) -> Array[MemoryPile]:
	var matching_cards := hand_manager.find_cards_with_value(played_value)
	var compatible_piles := pile_manager.find_piles_accepting_value(played_value)
	compatible_piles.erase(original_pile)
	matching_cards.sort_custom(
		func(first: PlayingCard, second: PlayingCard) -> bool:
			return first.global_position.distance_squared_to(origin) < second.global_position.distance_squared_to(origin)
	)
	var used: Array[MemoryPile] = []
	for card in matching_cards:
		if used.size() >= maximum_copies or compatible_piles.is_empty():
			break
		compatible_piles.sort_custom(
			func(first: MemoryPile, second: MemoryPile) -> bool:
				var card_center := card.global_position + card.size * 0.5
				var first_distance := card_center.distance_squared_to(first.global_position + first.size * 0.5)
				var second_distance := card_center.distance_squared_to(second.global_position + second.size * 0.5)
				if is_equal_approx(first_distance, second_distance):
					return first.pile_index < second.pile_index
				return first_distance < second_distance
		)
		var target := compatible_piles.pop_front() as MemoryPile
		await _stack_card(
			card, target,
			PlacementContext.new(PlacementContext.Source.DEJA_VU, root_action_id)
		)
		used.append(target)
	return used


func _resolve_double_down(
	pile: MemoryPile,
	maximum_bonus_cards: int,
	origin: Vector2,
	root_action_id: int
) -> int:
	var played_count := 0
	while played_count < maximum_bonus_cards and not pile.is_complete_value():
		var matching_card := hand_manager.find_card_with_value(pile.expected_value(), origin)
		if matching_card == null:
			break
		await _stack_card(
			matching_card, pile,
			PlacementContext.new(PlacementContext.Source.DOUBLE_DOWN, root_action_id)
		)
		played_count += 1
	return played_count


func _finalize_placement_action(affected_piles: Array[MemoryPile]) -> void:
	for pile in affected_piles:
		if not is_instance_valid(pile):
			continue
		if pile.is_complete_value() and not pile.completed:
			await _complete_pile(pile)
	for pile in affected_piles:
		if is_instance_valid(pile) and not pile.completed:
			await get_tree().create_timer(0.08).timeout
			await pile.hide_value(true)
	await _after_valid_card_played()


func _complete_pile(pile: MemoryPile) -> void:
	if pile.completed:
		return
	soft_audio.play_tone(760.0, 0.14, 0.06)
	if is_instance_valid(dust_pool):
		dust_pool.emit_wave(
			pile.get_global_rect().abs().get_center(),
			dust_completion_wave_influence
		)
		deformable_stripe_background.emit_wave(
			pile.get_global_rect().abs().get_center(),
			dust_completion_wave_influence
		)
	await pile.complete_animation(_is_background_deformation_active())
	var recovered := bonus_manager.recover_on_completed_pile(
		mistakes_left,
		maximum_mistakes
	)
	if recovered != mistakes_left:
		mistakes_left = recovered
		_update_hud()


func _after_valid_card_played() -> void:
	await special_rule_manager.after_card_played(piles, _progression_round())
	if round_modifiers.musical_stacks_enabled:
		var movement_duration := 0.4 / bonus_manager.adaptation_multiplier()
		if round_modifiers.moving_pile_pattern:
			await special_rule_manager.moving_pile_pattern.permute_paths(
				piles,
				round_modifiers.musical_stacks_direction,
				movement_duration
			)
		else:
			await pile_manager.rotate_active_piles(
				round_modifiers.musical_stacks_direction,
				movement_duration
			)


func _handle_mistake(
	pile: MemoryPile = null,
	caused_by_timeout := false,
	force_damage := false,
	instant_death := false
) -> void:
	if input_locked:
		return
	input_locked = true
	var shared_clock_time := timer_manager.time_left
	timer_manager.stop_countdown()
	hand_manager.lock_hand()
	run_mistake_count += 1
	var protected_by_safety_net := (
		false if force_damage else bonus_manager.consume_safety_net()
	)
	if force_damage or (not Debug.is_god_mode_enabled() and not protected_by_safety_net):
		mistakes_left = 0 if instant_death else mistakes_left - 1
		run_lives_lost += 1
		checkpoint_segment_damage_count += 1
		achievement_manager.life_lost.emit()
	mistake_made.emit()
	if protected_by_safety_net:
		soft_audio.play_safety_net_break()
	elif caused_by_timeout:
		soft_audio.play_timeout_error()
	else:
		soft_audio.play_error()
	if mistakes_left <= 0:
		music_manager.set_low_pass_enabled(true)
	if protected_by_safety_net:
		await mistakes_dots.play_safety_net_break()
	else:
		await mistakes_dots.play_damage(mistakes_left)
	_update_hud()
	await _return_drag_companions()
	if selected_card != null and is_instance_valid(selected_card) and selected_card.get_parent() == drag_layer:
		if challenge_modifiers.conveyor_hand and not caused_by_timeout:
			await _discard_rejected_conveyor_card(selected_card)
		else:
			await _return_card_to_hand(selected_card, 0.14)
	if mistakes_left <= 0:
		await get_tree().create_timer(DEATH_POPUP_DELAY).timeout
		await _reveal_piles_before_game_over()
		_start_discard_current_hand()
		await _finish_game()
	else:
		selected_card = null
		hand_manager.clear_selection()
		if bonus_manager.has_bonus(&"mistake_reveal"):
			await _run_bonus_pile_flash(
				Difficulty.MISTAKE_REVEAL_DURATIONS[
					bonus_manager.level(&"mistake_reveal")
				]
			)
		var wait_for_shared_clock_feedback := (
			challenge_modifiers.shared_round_clock
			and pile != null
			and is_instance_valid(pile)
			and not pile.completed
		)
		# Input returns before the pile feedback finishes so another tile can be
		# dragged immediately. Shared Clock itself remains frozen until the
		# animation has fully resolved.
		_shared_clock_mistake_feedback_active = wait_for_shared_clock_feedback
		input_locked = false
		hand_manager.unlock_hand()
		if wait_for_shared_clock_feedback:
			await _reveal_mistake_pile(pile)
			_shared_clock_mistake_feedback_active = false
		if challenge_modifiers.shared_round_clock:
			if not caused_by_timeout and not input_locked and not overlay.visible:
				timer_manager.time_left = maxf(
					shared_clock_time - Difficulty.SHARED_CLOCK_LIFE_PENALTY,
					0.0
				)
				_start_turn_countdown()
		else:
			_start_turn_countdown()
		if (
			not challenge_modifiers.shared_round_clock
			and pile != null
			and is_instance_valid(pile)
			and not pile.completed
		):
			_reveal_mistake_pile(pile)


func _reveal_mistake_pile(pile: MemoryPile) -> void:
	await pile.flash_invalid()
	if is_instance_valid(pile) and not pile.completed:
		await pile.reveal_value_temporarily(0.65)


func _reveal_piles_before_game_over() -> void:
	var final_tween: Tween
	for pile in piles:
		if not is_instance_valid(pile) or not pile.visible or pile.completed:
			continue
		final_tween = pile.reveal_for_game_over()
	if final_tween != null and final_tween.is_valid():
		await final_tween.finished
	await get_tree().create_timer(DEATH_PILE_REVEAL_HOLD_DURATION).timeout


func _discard_rejected_conveyor_card(card: PlayingCard) -> void:
	card.finish_drag()
	card.end_commit()
	card.set_selectable(false)
	_clear_drag_placeholder()
	var tween := (
		card.create_tween()
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_IN)
		.set_parallel()
	)
	tween.tween_property(card, "global_position:y", card.global_position.y + 20.0, 0.24)
	tween.tween_property(card, "modulate:a", 0.0, 0.2)
	tween.tween_property(card, "scale", Vector2(0.72, 0.72), 0.24)
	tween.tween_property(card, "rotation", -0.12, 0.24)
	await tween.finished
	hand_manager.forget_card(card)
	card.queue_free()


func _return_card_to_hand(card: PlayingCard, duration := 0.26) -> void:
	if challenge_modifiers.conveyor_hand:
		card.end_commit()
		_return_card_to_conveyor(card)
		card.set_selectable(not input_locked)
		return
	var destination := card.hand_return_position()
	await card.animate_return(destination, duration)
	if round_modifiers.wandering_hand_cards:
		_clear_drag_placeholder()
		card.scale = Vector2.ONE
		card.set_selectable(not input_locked)
		card.enable_wandering(maxi(hand_manager.current_cards.find(card), 0), true)
		return
	# Remove the spacer synchronously before putting the card back. Otherwise
	# both controls occupy the HBox for one frame and rapid drags can capture
	# that transient, shifted layout as a new home position.
	_clear_drag_placeholder()
	card.reparent(hand_container, false)
	_restore_hand_child_order()
	hand_container.queue_sort()
	await get_tree().process_frame
	card.reset_hand_pose()
	card.position.y = 0.0
	card.record_hand_position()
	card.set_selectable(not input_locked)
	if round_modifiers.wandering_hand_cards:
		card.call_deferred("enable_wandering", maxi(card.get_index(), 0))


func _clear_drag_placeholder() -> void:
	if is_instance_valid(drag_placeholder):
		var placeholder_card_id := 0
		for card_id in _hand_slot_placeholders:
			var stored_placeholder: Variant = _hand_slot_placeholders[card_id]
			if (
				is_instance_valid(stored_placeholder)
				and stored_placeholder == drag_placeholder
			):
				placeholder_card_id = int(card_id)
				break
		if placeholder_card_id != 0:
			_hand_slot_placeholders.erase(placeholder_card_id)
		if drag_placeholder.get_parent() != null:
			drag_placeholder.get_parent().remove_child(drag_placeholder)
		drag_placeholder.queue_free()
	drag_placeholder = null
	drag_home_index = -1


func _create_hand_slot_placeholder(card: PlayingCard) -> Control:
	var existing := _valid_hand_slot_placeholder(card)
	if existing != null:
		return existing
	var placeholder := Control.new()
	placeholder.name = "HandSlotPlaceholder"
	placeholder.set_meta(&"hand_drag_placeholder", true)
	placeholder.custom_minimum_size = card.size
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var slot_index := card.get_index()
	hand_container.add_child(placeholder)
	hand_container.move_child(placeholder, slot_index)
	_hand_slot_placeholders[card.get_instance_id()] = placeholder
	return placeholder


func _remove_hand_slot_placeholder(card: PlayingCard) -> void:
	var placeholder := _valid_hand_slot_placeholder(card)
	_hand_slot_placeholders.erase(card.get_instance_id())
	if placeholder == null:
		return
	if placeholder == drag_placeholder:
		drag_placeholder = null
		drag_home_index = -1
	if placeholder.get_parent() != null:
		placeholder.get_parent().remove_child(placeholder)
	placeholder.queue_free()


func _valid_hand_slot_placeholder(card: PlayingCard) -> Control:
	var placeholder_variant: Variant = _hand_slot_placeholders.get(
		card.get_instance_id()
	)
	if not is_instance_valid(placeholder_variant):
		return null
	return placeholder_variant as Control


func _clear_all_hand_slot_placeholders() -> void:
	for placeholder_variant in _hand_slot_placeholders.values():
		if not is_instance_valid(placeholder_variant):
			continue
		var placeholder := placeholder_variant as Control
		if placeholder.get_parent() != null:
			placeholder.get_parent().remove_child(placeholder)
		placeholder.queue_free()
	_hand_slot_placeholders.clear()
	drag_placeholder = null
	drag_home_index = -1


func _remove_orphan_drag_placeholders() -> void:
	for child in hand_container.get_children():
		if (
			child != drag_placeholder
			and child.has_meta(&"hand_drag_placeholder")
		):
			hand_container.remove_child(child)
			child.queue_free()
	_hand_slot_placeholders.clear()
	if is_instance_valid(drag_placeholder) and selected_card != null:
		_hand_slot_placeholders[selected_card.get_instance_id()] = drag_placeholder
	hand_container.queue_sort()


func _restore_hand_child_order() -> void:
	var child_index := 0
	for logical_card in hand_manager.current_cards:
		if not is_instance_valid(logical_card) or not logical_card.visible:
			continue
		if logical_card == selected_card and is_instance_valid(drag_placeholder):
			if drag_placeholder.get_parent() == hand_container:
				hand_container.move_child(drag_placeholder, child_index)
				child_index += 1
			continue
		if logical_card.get_parent() == hand_container:
			hand_container.move_child(logical_card, child_index)
			child_index += 1


func _record_stable_hand_layout() -> void:
	for card in hand_manager.current_cards:
		if (
			is_instance_valid(card)
			and card.visible
			and card.get_parent() == hand_container
			and not card.dragging
		):
			card.record_hand_position()


func _discard_current_hand(preserve_unused_jokers := true) -> void:
	await hand_manager.discard_hand(
		hand_container,
		drag_layer,
		preserve_unused_jokers
	)
	_clear_drag_placeholder()


func _start_discard_current_hand() -> void:
	hand_manager.discard_hand(hand_container, drag_layer)
	_clear_drag_placeholder()


func _pile_at(global_point: Vector2) -> MemoryPile:
	for pile in piles:
		if (
			not pile.completed
			and pile.visible
			and pile.contains_global_point(global_point, 8.0)
		):
			return pile
	return null


func _on_time_expired() -> void:
	if _debug_action_in_progress or _debug_round_wins_queued > 0:
		timer_manager.stop_countdown()
		_shared_clock_timeout_pending = false
		return
	if input_locked:
		if challenge_modifiers.shared_round_clock:
			_shared_clock_timeout_pending = true
		return
	await _handle_mistake(
		null,
		true,
		challenge_modifiers.shared_round_clock,
		challenge_modifiers.shared_round_clock
	)


func _resolve_pending_shared_clock_timeout() -> void:
	if not _shared_clock_timeout_pending or input_locked:
		return
	_shared_clock_timeout_pending = false
	_handle_mistake(null, true, true, true)


func _on_lava_card_entered(card: PlayingCard) -> void:
	if card == selected_card and not input_locked:
		card.request_forced_return(PlayingCard.ForcedReturnReason.LAVA)


func _on_redraw_pressed() -> void:
	var challenge_reload := (
		game_mode == GameMode.CHALLENGE
		and current_challenge.id == &"reload_required"
	)
	if input_locked or (not challenge_reload and not bonus_manager.consume_redraw()):
		return
	input_locked = true
	redraw_button.set_remaining(
		bonus_manager.redraws_left,
		bonus_manager.level(&"redraw") >= 2
	)
	redraw_button.play_used_animation()
	timer_manager.stop_countdown()
	if challenge_reload and timer_manager.time_left < 1.0:
		timer_manager.add_time(challenge_modifiers.reload_low_time_bonus)
	if challenge_modifiers.shared_round_clock:
		timer_manager.add_time(Difficulty.SHARED_CLOCK_RELOAD_TIME_BONUS)
	_hand_cycle_generation += 1
	await _discard_current_hand()
	_preserve_timer_through_quick_peek = challenge_reload
	await _begin_turn(false, true, challenge_reload)
	if challenge_reload and not _quick_peek_pending and not overlay.visible:
		_preserve_timer_through_quick_peek = false
		timer_manager.resume_countdown()
	redraw_button.visible = challenge_reload or bonus_manager.redraws_left > 0


func cleanup_special_rule_state(animated := true) -> void:
	input_locked = true
	sticky_fingers_controller.end_round()
	mirror_match_controller.end_round(self)
	timer_manager.stop_countdown()
	if animated:
		await _return_drag_companions()
	else:
		drag_companions.clear()
		_companion_offsets.clear()
		_companion_home_positions.clear()
	if moving_pile != null and is_instance_valid(moving_pile):
		moving_pile.position = _moving_pile_last_valid_position
	moving_pile = null
	_pile_touch_index = -1
	_card_touch_index = -1
	if selected_card != null and is_instance_valid(selected_card):
		selected_card.cancel_drag_timers()
		if animated and selected_card.get_parent() == drag_layer:
			await _return_card_to_hand(selected_card, 0.16)
	hand_manager.cancel_all_drags()
	hand_manager.stop_all_card_timers()
	hand_manager.reveal_all_hand_cards()
	hand_manager.refresh_all_card_themes(false)
	pile_manager.stop_all_movements()
	pile_manager.refresh_all_card_themes(false)
	lava_rule_controller.clear(animated)
	_on_timer_visibility_requested(true)
	mistakes_dots.set_maximum(3)
	selected_card = null
	hovered_pile = null


func _clear_gameplay_pieces_immediately() -> void:
	for card in hand_manager.current_cards:
		if is_instance_valid(card):
			card.queue_free()
	hand_manager.current_cards.clear()
	for child in hand_container.get_children():
		if child is PlayingCard:
			child.queue_free()
	for child in drag_layer.get_children():
		child.queue_free()
	_clear_all_hand_slot_placeholders()


func _finish_round() -> void:
	input_locked = true
	var transition_generation := _run_transition_generation
	var completed_round_number := _progression_round()
	var completed_rule_ids: Array[StringName] = []
	for rule in special_rule_manager.active_rules:
		completed_rule_ids.append(rule.id)
	_pause_run_time()
	timer_manager.stop_countdown()
	await cleanup_special_rule_state()
	if transition_generation != _run_transition_generation:
		return
	# Clear the remaining hand as part of the victory sequence. Jokers persist
	# between hands, but never carry over into the next round.
	await _discard_current_hand(false)
	if transition_generation != _run_transition_generation:
		return
	_clear_all_hand_slot_placeholders()
	await special_rule_manager.end_round(piles)
	if transition_generation != _run_transition_generation:
		return
	round_completed.emit()
	run_completed_rounds += 1
	for rule_id in completed_rule_ids:
		if not beaten_special_rules.has(rule_id):
			beaten_special_rules.append(rule_id)
	_save_discoveries()
	achievement_manager.special_rule_round_completed.emit(
		completed_rule_ids, beaten_special_rules
	)
	achievement_manager.round_completed.emit(
		_build_run_summary(false), completed_round_number, completed_rule_ids
	)
	var checkpoint_unlocked := (
		false
		if game_mode == GameMode.CHALLENGE
		else _unlock_completed_checkpoint(completed_round_number)
	)
	if checkpoint_unlocked:
		achievement_manager.checkpoint_unlocked.emit(
			int(completed_round_number / Difficulty.CHECKPOINT_INTERVAL),
			unlocked_checkpoints
		)
		await _show_checkpoint_unlocked(
			int(completed_round_number / Difficulty.CHECKPOINT_INTERVAL)
		)
		if transition_generation != _run_transition_generation:
			return
	soft_audio.play_tone(680.0, 0.16, 0.055)
	await _show_round_wave()
	if transition_generation != _run_transition_generation:
		return
	if (
		game_mode in [GameMode.ENDLESS, GameMode.CHECKPOINT]
		or (game_mode == GameMode.CHALLENGE and challenge_endless)
	):
		round_number += 1
	else:
		round_number -= 1
	round_reached_time_ms = _total_time_milliseconds()
	_update_hud()
	if game_mode == GameMode.STANDARD and round_number <= 0:
		await _finish_game(true)
		return
	if (
		game_mode == GameMode.CHALLENGE
		and not challenge_endless
		and round_number <= 0
	):
		await _finish_game(true)
		return
	if (
		game_mode == GameMode.CHECKPOINT
		and not checkpoint_uses_endless_progression
		and round_number > Difficulty.TOTAL_ROUNDS
	):
		await _finish_game(true)
		return
	await bonus_manager.offer_if_due(completed_round_number)
	if transition_generation != _run_transition_generation:
		return
	await _offer_checkpoint_backlog_bonus(completed_round_number)
	if transition_generation != _run_transition_generation:
		return
	var change := _advance_difficulty(_progression_round())
	_emit_difficulty_stats()
	if change == "TIER RELIEF":
		music_manager.request_next_section()
	if change.is_empty():
		if _debug_round_wins_queued > 0:
			return
		start_round()
		return
	_pause_achievement_notifications(&"difficulty")
	var change_lines := change.split("\n", false)
	transient_label.text = change_lines[0]
	transient_label.visible = true
	transient_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(transient_label, "modulate:a", 1.0, 0.2)
	if change_lines.size() > 1:
		tween.tween_interval(extra_difficulty_reveal_delay)
		tween.tween_callback(
			func() -> void: transient_label.text = "\n".join(change_lines)
		)
		tween.tween_interval(
			maxf(0.75 - extra_difficulty_reveal_delay, 0.0)
			+ extra_difficulty_hold_duration
		)
	else:
		tween.tween_interval(0.75)
	tween.tween_property(transient_label, "modulate:a", 0.0, 0.2)
	skippable_sequence.begin(tween)
	if _debug_round_wins_queued > 0:
		skippable_sequence.call_deferred("skip_to_end")
	await tween.finished
	if transition_generation != _run_transition_generation:
		skippable_sequence.finish()
		transient_label.visible = false
		_resume_achievement_notifications(&"difficulty")
		return
	skippable_sequence.finish()
	transient_label.visible = false
	_resume_achievement_notifications(&"difficulty")
	if _debug_round_wins_queued > 0:
		return
	start_round()


func _show_round_wave() -> void:
	# The deformable background emits its own completion wave.
	if _is_background_deformation_active():
		return
	_pause_achievement_notifications(&"round_wave")
	var wave := %RoundWave as Control
	wave.visible = true
	wave.scale = Vector2(0.2, 0.2)
	wave.modulate.a = 0.45
	var tween := create_tween().set_parallel()
	tween.tween_property(wave, "scale", Vector2(2.4, 2.4), 0.55)
	tween.tween_property(wave, "modulate:a", 0.0, 0.55)
	skippable_sequence.begin(tween)
	if _debug_round_wins_queued > 0:
		skippable_sequence.call_deferred("skip_to_end")
	await tween.finished
	skippable_sequence.finish()
	wave.visible = false
	_resume_achievement_notifications(&"round_wave")


func _finish_game(completed_all_rounds := false) -> void:
	_end_gameplay_for_result_screen()
	music_manager.set_low_pass_enabled(true)
	var finite_victory := _is_finite_mode_victory(completed_all_rounds)
	if finite_victory:
		soft_audio.play_victory()
		if game_mode == GameMode.STANDARD:
			_unlock_endless_mode()
	else:
		soft_audio.play_game_over()
	# The death screen represents the whole run, including the round in which
	# the player died. `round_reached_time_ms` only tracks completed rounds.
	var score_time_ms := _total_time_milliseconds()
	achievement_manager.run_completed.emit(
		_build_run_summary(completed_all_rounds)
	)
	var formatted_time := _format_duration(score_time_ms)
	var high_score_kind := ""
	match game_mode:
		GameMode.ENDLESS:
			high_score_kind = _update_endless_high_score(round_number, score_time_ms)
		GameMode.CHECKPOINT:
			high_score_kind = _update_checkpoint_high_score(round_number)
		GameMode.CHALLENGE:
			var challenge_high_score := challenge_manager.record_result(
				current_challenge,
				_progression_round(),
				challenge_endless,
				score_time_ms
			)
			if challenge_high_score:
				high_score_kind = challenge_manager.last_record_kind
			if completed_all_rounds and not challenge_endless:
				achievement_manager.record_challenge_completion(
					current_challenge.id,
					challenge_manager.completed,
					challenge_manager.definitions
				)
		_:
			high_score_kind = _update_high_score(round_number, score_time_ms)
	if game_mode != GameMode.CHALLENGE:
		_update_no_mistake_high_score(round_number, score_time_ms)
	game_over.emit()
	overlay_unlocks.visible = false
	overlay_unlocks.text = ""
	overlay_high_score.visible = not high_score_kind.is_empty()
	if finite_victory:
		overlay_title.text = (
			"[center][color=#FFD700][wave amp=35.0 freq=4.0 connected=1]YOU WIN ![/wave][/color][/center]"
		)
		overlay_details.text = "[center]in %s[/center]" % formatted_time
	elif game_mode == GameMode.CHALLENGE and challenge_endless:
		overlay_title.text = "[center]%s[/center]" % current_challenge.title
		overlay_details.text = "[center]ENDLESS\nROUND %d\nin %s[/center]" % [
			round_number, formatted_time
		]
	elif game_mode == GameMode.CHALLENGE:
		var challenge_rounds_text := "%d ROUNDS LEFT" % maxi(round_number, 0)
		var challenge_time_text := "in %s" % formatted_time
		if high_score_kind == "ROUND":
			challenge_rounds_text = (
				"[color=#4D82C2]%s[/color]" % challenge_rounds_text
			)
		elif high_score_kind == "TIME":
			challenge_time_text = (
				"[color=#4D82C2]%s[/color]" % challenge_time_text
			)
		overlay_title.text = "[center]%s[/center]" % challenge_rounds_text
		overlay_details.text = "[center]%s[/center]" % challenge_time_text
	elif not high_score_kind.is_empty():
		var rounds_text := (
			_checkpoint_result_text(round_number)
			if game_mode == GameMode.CHECKPOINT
			else (
				"ROUND %d" % round_number
				if game_mode == GameMode.ENDLESS
				else "%d ROUNDS LEFT" % round_number
			)
		)
		var time_text := (
			"CHECKPOINT RUN"
			if game_mode == GameMode.CHECKPOINT
			else "in %s" % formatted_time
		)
		if high_score_kind == "ROUND":
			rounds_text = "[color=#4D82C2]%s[/color]" % rounds_text
		else:
			time_text = "[color=#4D82C2]%s[/color]" % time_text
		overlay_title.text = "[center]%s[/center]" % rounds_text
		overlay_details.text = "[center]%s[/center]" % time_text
	elif game_mode == GameMode.ENDLESS:
		overlay_title.text = "[center]ROUND %d[/center]" % round_number
		overlay_details.text = "[center]in %s[/center]" % formatted_time
	elif game_mode == GameMode.CHECKPOINT:
		overlay_title.text = "[center]%s[/center]" % _checkpoint_result_text(round_number)
		overlay_details.text = "[center]CHECKPOINT RUN[/center]"
	else:
		overlay_title.text = "[center]%d ROUNDS LEFT[/center]" % round_number
		overlay_details.text = "[center]in %s[/center]" % formatted_time
	_append_new_progression_summary()
	overlay_button.text = "REPLAY"
	overlay_endless_button.visible = (
		completed_all_rounds
		and (
			game_mode == GameMode.STANDARD
			or (
				game_mode == GameMode.CHALLENGE
				and not challenge_endless
				and current_challenge.allow_endless
			)
		)
	)
	overlay_mode = "restart"
	_show_game_over_overlay(not completed_all_rounds)
	# Cleanup can include rule-specific animations. Run it only after the result
	# is visible so the third mistake always produces immediate feedback.
	await cleanup_special_rule_state()
	await special_rule_manager.end_round(piles)


func _end_gameplay_for_result_screen() -> void:
	# A result overlay is terminal for the current run. Invalidate every pending
	# gameplay continuation, including accelerated debug wins, before building
	# the screen so none can start a hand or apply delayed timeout damage behind it.
	_run_transition_generation += 1
	_gameplay_generation += 1
	_hand_cycle_generation += 1
	_debug_round_wins_queued = 0
	_pending_interactive_generation = -1
	_shared_clock_timeout_pending = false
	_shared_clock_mistake_feedback_active = false
	_quick_peek_pending = false
	_preserve_timer_through_quick_peek = false
	_conveyor_active = false
	input_locked = true
	timer_manager.stop_countdown()
	hand_manager.lock_hand()
	selected_card = null
	hovered_pile = null
	hand_manager.clear_selection()


func _is_finite_mode_victory(completed_all_rounds: bool) -> bool:
	if not completed_all_rounds:
		return false
	return (
		game_mode == GameMode.STANDARD
		or (game_mode == GameMode.CHECKPOINT and not checkpoint_uses_endless_progression)
		or (game_mode == GameMode.CHALLENGE and not challenge_endless)
	)


func _show_game_over_overlay(animate_death: bool) -> void:
	back_button.visible = false
	overlay.visible = true
	overlay_scrim.modulate.a = 1.0
	overlay_panel.modulate.a = 1.0
	overlay_panel.scale = Vector2.ONE
	if not animate_death:
		return
	overlay_scrim.modulate.a = 0.0
	overlay_panel.modulate.a = 0.0
	overlay_panel.scale = Vector2(0.42, 0.42)
	overlay_panel.pivot_offset = overlay_panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(overlay_scrim, "modulate:a", 1.0, 0.18)
	tween.tween_property(overlay_panel, "modulate:a", 1.0, 0.12)
	tween.tween_property(
		overlay_panel,
		"scale",
		Vector2.ONE,
		0.3
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _append_new_checkpoint_summary() -> void:
	_append_new_progression_summary()


func _append_new_progression_summary() -> void:
	var lines := PackedStringArray()
	var checkpoint_line := _new_checkpoint_summary_line()
	if not checkpoint_line.is_empty():
		lines.append(_progression_icon_line(
			PROGRESSION_CHECKPOINT_ICON, PackedStringArray([checkpoint_line])
		))
	var bonus_titles := _new_bonus_titles()
	if not bonus_titles.is_empty():
		lines.append(_progression_icon_line(PROGRESSION_BONUS_ICON, bonus_titles))
	var rule_titles := _new_rule_titles()
	if not rule_titles.is_empty():
		lines.append(_progression_icon_line(PROGRESSION_RULE_ICON, rule_titles))
	var achievement_titles := _new_achievement_titles()
	if not achievement_titles.is_empty():
		lines.append(
			_progression_icon_line(
				PROGRESSION_ACHIEVEMENT_ICON, achievement_titles
			)
		)
	if lines.is_empty():
		overlay_unlocks.visible = false
		overlay_unlocks.text = ""
		return
	overlay_unlocks.text = "[center]%s[/center]" % "\n".join(lines)
	overlay_unlocks.visible = true


func _progression_icon_line(icon_path: String, titles: PackedStringArray) -> String:
	return "+ [img=16x16]%s[/img] %s" % [
		icon_path, " + ".join(titles),
	]


func _new_checkpoint_summary_line() -> String:
	if newly_unlocked_checkpoints.is_empty():
		return ""
	var checkpoint_ids: Array[int] = []
	for checkpoint_id in newly_unlocked_checkpoints:
		if not checkpoint_ids.has(checkpoint_id):
			checkpoint_ids.append(checkpoint_id)
	checkpoint_ids.sort()
	var labels := PackedStringArray()
	for checkpoint_id in checkpoint_ids:
		labels.append(str(checkpoint_id))
	var heading := "CHECKPOINTS" if checkpoint_ids.size() > 1 else "CHECKPOINT"
	return "%s: %s" % [
		heading, " + ".join(labels),
	]


func _new_bonus_titles() -> PackedStringArray:
	var titles := PackedStringArray()
	for bonus_id in newly_discovered_bonuses:
		for data in bonus_manager.definitions:
			if data.id == bonus_id and not titles.has(data.title):
				titles.append(data.title)
				break
	return titles


func _new_rule_titles() -> PackedStringArray:
	var titles := PackedStringArray()
	for rule_id in newly_encountered_rules:
		for data in SpecialRuleRegistry.create_all_rules():
			if data.id == rule_id and not titles.has(data.title):
				titles.append(data.title)
				break
	return titles


func _new_achievement_titles() -> PackedStringArray:
	var titles := PackedStringArray()
	for achievement_id in newly_unlocked_achievements:
		var data := achievement_manager.find(achievement_id)
		if data != null and not titles.has(data.title):
			titles.append(data.title)
	return titles


func _on_overlay_pressed() -> void:
	if overlay_mode == "restart":
		_restart_current_mode()


func _on_overlay_endless_pressed() -> void:
	if game_mode == GameMode.CHALLENGE:
		start_game(false, current_challenge, true)
	else:
		start_game(true)


func _on_splash_pressed() -> void:
	start_game()


func _on_endless_pressed() -> void:
	start_game(true)


func _open_challenge_selection() -> void:
	challenge_selection.open(challenge_manager, achievement_manager.unlocked)
	_submenu_swipe_controller.open(
		challenge_selection, get_viewport_rect().size.x
	)


func _on_challenge_selection_closed() -> void:
	await _submenu_swipe_controller.close(
		challenge_selection, get_viewport_rect().size.x
	)
	challenge_button.grab_focus()


func _start_challenge(id: StringName, endless: bool) -> void:
	var data := challenge_manager.find(id)
	if data == null:
		return
	challenge_selection.visible = false
	start_game(false, data, endless)


func _open_checkpoint_menu() -> void:
	CheckpointMenuControllerScript.open(self)
	_submenu_swipe_controller.open(checkpoint_menu, get_viewport_rect().size.x)


func _close_checkpoint_menu() -> void:
	if not checkpoint_menu.visible:
		return
	await _submenu_swipe_controller.close(
		checkpoint_menu, get_viewport_rect().size.x
	)
	CheckpointMenuControllerScript.close(self)


func _refresh_checkpoint_button() -> void:
	CheckpointMenuControllerScript.refresh_button(self)


func _refresh_checkpoint_list() -> void:
	CheckpointMenuControllerScript.refresh_list(self)


func _on_checkpoint_selected(checkpoint_id: int) -> void:
	checkpoint_menu.visible = false
	start_from_checkpoint(checkpoint_id)


func _start_selected_checkpoint() -> void:
	if selected_checkpoint_id > 0:
		start_from_checkpoint(selected_checkpoint_id)


func _select_next_checkpoint(direction: int) -> void:
	CheckpointMenuControllerScript.select_next(self, direction)


func _update_checkpoint_button_text() -> void:
	CheckpointMenuControllerScript.update_button_text(self)


func _on_checkpoint_button_input(event: InputEvent) -> void:
	CheckpointMenuControllerScript.handle_button_input(self, event)


func _show_selected_checkpoint() -> void:
	CheckpointMenuControllerScript.show_selected(self)


func _show_checkpoint_unlocked(checkpoint_id: int) -> void:
	await CheckpointMenuControllerScript.show_unlocked(self, checkpoint_id)


func _on_special_rules_announcing(_rules: Array[SpecialRuleData]) -> void:
	_pause_achievement_notifications(&"special_rules")
	_pause_run_time()
	music_manager.set_low_pass_enabled(true)
	soft_audio.play_special_rule()


func _on_special_rules_announcement_finished() -> void:
	_resume_run_time()
	music_manager.set_low_pass_enabled(false, true)
	_resume_achievement_notifications(&"special_rules")


func _increase_difficulty(first_upgrade_override := -1) -> String:
	var first_upgrade := (
		first_upgrade_override == 1
		if first_upgrade_override >= 0
		else _progression_round() == 2
	)
	return difficulty_progression.increase(rng, first_upgrade)


func _new_difficulty_droughts() -> Dictionary:
	return DifficultyProgressionScript.new_droughts()


func _advance_difficulty(next_progression_round: int, first_upgrade_override := -1) -> String:
	return difficulty_progression.advance(rng, next_progression_round, first_upgrade_override)


func _has_due_difficulty_guarantee() -> bool:
	return difficulty_progression.has_due_guarantee()


func get_extra_difficulty_chance(progression_round: int) -> float:
	return DifficultyProgressionScript.extra_change_chance(progression_round)


func get_no_difficulty_change_chance(progression_round: int) -> float:
	return DifficultyProgressionScript.no_change_chance(progression_round)


func _is_special_tier_relief_round(progression_round: int) -> bool:
	return DifficultyProgressionScript.is_tier_relief_round(progression_round)


func _apply_special_tier_relief() -> void:
	difficulty_progression.apply_tier_relief(rng)


func _apply_debug_progression(start_round: int) -> void:
	difficulty_progression.apply_until(rng, start_round)


func _apply_challenge_starting_difficulty(data: ChallengeData) -> void:
	if data.starting_pile_count >= 0:
		pile_count = clampi(data.starting_pile_count, 1, Difficulty.MAX_PILES)
	if data.starting_hand_size >= 0:
		hand_size = clampi(data.starting_hand_size, 1, Difficulty.MAX_HAND_SIZE)
	if data.starting_card_value >= 0:
		start_value = clampi(data.starting_card_value, 2, Difficulty.MAX_CARD_VALUE)
	if data.starting_turn_time >= 0.0:
		turn_time = maxf(data.starting_turn_time, Difficulty.MIN_TURN_TIME)


func _playable_values() -> Array[int]:
	var values: Array[int] = []
	for pile in piles:
		if not pile.completed and not pile.is_complete_value():
			var expected := pile.expected_value()
			if not values.has(expected):
				values.append(expected)
	return values


func _playable_values_with_duplicates() -> Array[int]:
	var values: Array[int] = []
	for pile in piles:
		if not pile.completed and not pile.is_complete_value():
			values.append(pile.expected_value())
	return values


func _all_piles_complete() -> bool:
	for pile in piles:
		if not pile.completed:
			return false
	return not piles.is_empty()


func _start_turn_countdown(duration_override := -1.0) -> void:
	var effective_turn_time := (
		duration_override if duration_override > 0.0 else turn_time
	)
	if challenge_modifiers.shared_round_clock:
		if _shared_clock_initialized:
			if not _shared_clock_mistake_feedback_active:
				timer_manager.resume_countdown()
			return
		effective_turn_time = Difficulty.estimate_shared_round_time(
			pile_count,
			start_value,
			hand_size,
			challenge_modifiers.shared_clock_seconds_per_hand
			if challenge_modifiers.shared_clock_seconds_per_hand >= 0.0
			else turn_time
		)
		var warmup_level := bonus_manager.level(&"slow_start")
		if warmup_level > 0:
			effective_turn_time += float(warmup_level) * turn_time
		_shared_clock_initialized = true
	# Le premier tick correspond au passage à la seconde suivante, pas à
	# l'initialisation du chronomètre.
	_last_clock_second = ceili(effective_turn_time)
	_urgent_tick_index = 0
	while (
		_urgent_tick_index < URGENT_TICK_THRESHOLDS.size()
		and URGENT_TICK_THRESHOLDS[_urgent_tick_index] >= effective_turn_time
	):
		_urgent_tick_index += 1
	if _clock_flash_tween != null and _clock_flash_tween.is_valid():
		_clock_flash_tween.kill()
	timer_ring.flash_strength = 0.0
	var grace_duration := 0.0
	if round_modifiers.grace_period_enabled:
		var adapted_reveal_time := (
			Difficulty.GRACE_PERIOD_REVEAL_TIME
			/ maxf(round_modifiers.special_rule_intensity_multiplier, 0.01)
		)
		grace_duration = maxf(
			effective_turn_time - maxf(adapted_reveal_time, 0.0),
			0.0
		)
		round_modifiers.grace_period_duration = grace_duration
	timer_manager.start_countdown(effective_turn_time, grace_duration)


func _reveal_all_piles(duration: float) -> void:
	var revealed: Array[MemoryPile] = []
	for pile in piles:
		if is_instance_valid(pile) and not pile.completed and not pile.face_up:
			pile.set_bonus_revealed(true)
			revealed.append(pile)
	if revealed.is_empty():
		return
	await get_tree().create_timer(duration).timeout
	for pile in revealed:
		if is_instance_valid(pile):
			pile.set_bonus_revealed(false)


func _run_quick_peek() -> void:
	await _run_bonus_pile_flash(bonus_manager.quick_peek_duration())
	_quick_peek_pending = false
	if _all_piles_complete():
		return
	if _preserve_timer_through_quick_peek:
		_preserve_timer_through_quick_peek = false
		timer_manager.resume_countdown()
	else:
		_start_turn_countdown(bonus_manager.next_hand_time(turn_time))
	input_locked = false
	hand_manager.unlock_hand()


func _run_bonus_pile_flash(duration: float) -> void:
	var flashed_piles: Array[MemoryPile] = []
	for pile in piles:
		if is_instance_valid(pile) and not pile.completed and not pile.face_up:
			flashed_piles.append(pile)
			pile.show_quick_peek_flash()
	await get_tree().create_timer(duration).timeout
	for pile in flashed_piles:
		if is_instance_valid(pile):
			pile.hide_quick_peek_flash()
	await get_tree().create_timer(0.07).timeout


func _on_time_updated(time_left: float) -> void:
	var displayed_second := ceili(time_left)
	var formatted_time := RoundModifiers.format_value(
		displayed_second,
		round_modifiers.roman_numerals_enabled
	)
	timer_label.text = (
		str(ceili(time_left))
		if challenge_modifiers.shared_round_clock
		else formatted_time
	)
	timer_ring.set_ratio(timer_manager.ratio())
	if (
		not _timer_display_hidden
		and time_left > 2.0
		and displayed_second != _last_clock_second
	):
		_last_clock_second = displayed_second
		soft_audio.play_clock_tick()
	elif time_left <= 2.0 and (not _timer_display_hidden or time_left <= 1.0):
		while (
			_urgent_tick_index < URGENT_TICK_THRESHOLDS.size()
			and time_left <= URGENT_TICK_THRESHOLDS[_urgent_tick_index]
		):
			var threshold := URGENT_TICK_THRESHOLDS[_urgent_tick_index]
			var urgency := 1.0 - threshold / 2.0
			soft_audio.play_clock_tick(urgency)
			_flash_clock_tick(urgency)
			_urgent_tick_index += 1


func _on_timer_visibility_requested(visible: bool) -> void:
	var was_hidden := _timer_display_hidden
	_timer_display_hidden = not visible
	if _timer_visibility_tween != null and _timer_visibility_tween.is_valid():
		_timer_visibility_tween.kill()
	if not visible:
		if was_hidden:
			return
		timer_ring.visible = true
		_timer_visibility_tween = create_tween().set_parallel()
		_timer_visibility_tween.set_trans(Tween.TRANS_QUAD)
		_timer_visibility_tween.set_ease(Tween.EASE_IN)
		_timer_visibility_tween.tween_property(timer_ring, "modulate:a", 0.0, 0.15)
		_timer_visibility_tween.tween_property(
			timer_ring,
			"scale",
			Vector2(0.9, 0.9),
			0.15
		)
		_timer_visibility_tween.chain().tween_callback(func() -> void:
			if _timer_display_hidden:
				timer_ring.visible = false
		)
		return
	timer_ring.visible = true
	if not was_hidden:
		timer_ring.scale = Vector2.ONE
		timer_ring.modulate.a = 1.0
		return
	timer_ring.scale = Vector2(0.9, 0.9)
	timer_ring.modulate.a = 0.0
	_timer_visibility_tween = create_tween().set_parallel()
	_timer_visibility_tween.set_trans(Tween.TRANS_QUAD)
	_timer_visibility_tween.set_ease(Tween.EASE_OUT)
	_timer_visibility_tween.tween_property(timer_ring, "modulate:a", 1.0, 0.18)
	_timer_visibility_tween.tween_property(timer_ring, "scale", Vector2.ONE, 0.18)


func _flash_clock_tick(urgency: float) -> void:
	if _clock_flash_tween != null and _clock_flash_tween.is_valid():
		_clock_flash_tween.kill()
	var red_strength := lerpf(0.55, 0.9, clampf(urgency, 0.0, 1.0))
	timer_ring.flash_strength = red_strength
	_clock_flash_tween = create_tween()
	_clock_flash_tween.tween_property(
		timer_ring,
		"flash_strength",
		0.0,
		0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _update_hud() -> void:
	var displayed_round := round_number
	if game_mode == GameMode.CHECKPOINT and not checkpoint_uses_endless_progression:
		displayed_round = maxi(Difficulty.TOTAL_ROUNDS - round_number + 1, 0)
	round_label.text = RoundModifiers.format_value(
		displayed_round,
		round_modifiers.roman_numerals_enabled
	)
	mistakes_dots.set_remaining(mistakes_left)


func _total_time_milliseconds() -> int:
	var paused := run_paused_msec
	if run_pause_started_msec >= 0:
		paused += Time.get_ticks_msec() - run_pause_started_msec
	return maxi(Time.get_ticks_msec() - game_started_msec - paused, 0)


func _pause_run_time() -> void:
	if run_pause_started_msec < 0:
		run_pause_started_msec = Time.get_ticks_msec()


func _resume_run_time() -> void:
	if run_pause_started_msec < 0:
		return
	run_paused_msec += Time.get_ticks_msec() - run_pause_started_msec
	run_pause_started_msec = -1


func _format_duration(total_msec: int) -> String:
	var milliseconds := total_msec % 1000
	var total_seconds := total_msec / 1000
	var seconds := total_seconds % 60
	var total_minutes := total_seconds / 60
	var minutes := total_minutes % 60
	var hours := total_minutes / 60
	var parts := PackedStringArray()
	if hours > 0:
		parts.append("%d h" % hours)
	if total_minutes > 0:
		parts.append("%d min" % minutes)
	parts.append("%d s" % seconds)
	parts.append("%03d ms" % milliseconds)
	return " ".join(parts)


func _update_high_score(rounds_left: int, elapsed_time_ms: int) -> String:
	var is_better_progress := best_rounds_left < 0 or rounds_left < best_rounds_left
	var is_faster_tie := (
		rounds_left == best_rounds_left
		and (best_score_time_ms < 0 or elapsed_time_ms < best_score_time_ms)
	)
	if not is_better_progress and not is_faster_tie:
		return ""
	best_rounds_left = rounds_left
	best_score_time_ms = elapsed_time_ms
	_save_high_score()
	_refresh_high_score()
	return "ROUND" if is_better_progress else "TIME"


func _save_high_score() -> void:
	var config := ConfigFile.new()
	config.load("user://pile_down.cfg")
	config.set_value("save", "schema_version", SAVE_SCHEMA_VERSION)
	config.set_value("progress", "best_rounds_left", best_rounds_left)
	config.set_value("progress", "best_score_time_ms", best_score_time_ms)
	config.set_value("highscores", "classic", {
		"rounds_left": best_rounds_left, "time_ms": best_score_time_ms
	})
	config.set_value("highscores", "classic_no_mistake", {
		"rounds_left": classic_no_mistake_rounds_left,
		"time_ms": classic_no_mistake_time_ms,
	})
	if best_rounds_left == 0:
		config.set_value("progress", "best_time_ms", best_score_time_ms)
	config.save("user://pile_down.cfg")


func _update_endless_high_score(reached_round: int, elapsed_time_ms: int) -> String:
	var is_better_progress := (
		endless_best_round < 0 or reached_round > endless_best_round
	)
	var is_faster_tie := (
		reached_round == endless_best_round
		and (
			endless_best_time_ms < 0
			or elapsed_time_ms < endless_best_time_ms
		)
	)
	if not is_better_progress and not is_faster_tie:
		return ""
	endless_best_round = reached_round
	endless_best_time_ms = elapsed_time_ms
	_save_endless_progress()
	return "ROUND" if is_better_progress else "TIME"


func _unlock_endless_mode() -> void:
	if endless_unlocked:
		return
	endless_unlocked = true
	endless_button.visible = true
	_save_endless_progress()


func _save_endless_progress() -> void:
	var config := ConfigFile.new()
	config.load("user://pile_down.cfg")
	config.set_value("save", "schema_version", SAVE_SCHEMA_VERSION)
	config.set_value("progress", "endless_unlocked", endless_unlocked)
	config.set_value("progress", "endless_best_round", endless_best_round)
	config.set_value("progress", "endless_best_time_ms", endless_best_time_ms)
	config.set_value("highscores", "endless", endless_best_round)
	config.set_value("highscores", "endless_no_mistake", endless_no_mistake_round)
	config.save("user://pile_down.cfg")


func _load_high_score() -> void:
	var config := ConfigFile.new()
	if config.load("user://pile_down.cfg") == OK:
		if config.has_section_key("progress", "best_rounds_left"):
			best_rounds_left = int(config.get_value("progress", "best_rounds_left", -1))
			best_score_time_ms = int(config.get_value("progress", "best_score_time_ms", -1))
		else:
			var legacy_best_time := int(config.get_value("progress", "best_time_ms", 0))
			if legacy_best_time > 0:
				best_rounds_left = 0
				best_score_time_ms = legacy_best_time
		endless_unlocked = bool(
			config.get_value("progress", "endless_unlocked", false)
		)
		endless_best_round = int(
			config.get_value("progress", "endless_best_round", -1)
		)
		endless_best_time_ms = int(
			config.get_value("progress", "endless_best_time_ms", -1)
		)
		var classic_clean: Dictionary = config.get_value(
			"highscores", "classic_no_mistake", {}
		)
		classic_no_mistake_rounds_left = int(classic_clean.get("rounds_left", -1))
		classic_no_mistake_time_ms = int(classic_clean.get("time_ms", -1))
		endless_no_mistake_round = int(
			config.get_value("highscores", "endless_no_mistake", -1)
		)
		discovered_bonuses.assign(
			config.get_value("progression", "discovered_bonuses", [])
		)
		max_discovered_tile_value = clampi(
			int(config.get_value(
				"progression", "max_discovered_tile_value",
				Difficulty.START_CARD_VALUE
			)),
			Difficulty.START_CARD_VALUE,
			Difficulty.MAX_CARD_VALUE
		)
		seen_bonuses.assign(
			config.get_value("progression", "seen_bonuses", discovered_bonuses)
		)
		encountered_special_rules.assign(
			config.get_value("progression", "encountered_special_rules", [])
		)
		beaten_special_rules.assign(
			config.get_value("progression", "beaten_special_rules", [])
		)
		_load_checkpoint_progress(config)
		_migrate_save(config)
	endless_unlocked = endless_unlocked or Debug.unlock_endless_mode()
	endless_button.visible = endless_unlocked
	_refresh_high_score()


func _refresh_high_score() -> void:
	if best_rounds_left < 0 or best_score_time_ms < 0:
		splash_high_score.text = "[center]HIGHSCORE\n--[/center]"
		splash_high_score_time.visible = false
		return
	if best_rounds_left == 0:
		splash_high_score.text = (
			"[center]HIGHSCORE\nWIN[/center]"
		)
		splash_high_score_time.text = "in %s" % _format_duration(best_score_time_ms)
		splash_high_score_time.visible = true
		return
	splash_high_score.text = (
		"[center]HIGHSCORE\n%d rounds left[/center]" % best_rounds_left
	)
	splash_high_score_time.text = "in %s" % _format_duration(best_score_time_ms)
	splash_high_score_time.visible = true


func _show_endless_high_score() -> void:
	if endless_best_round < 0 or endless_best_time_ms < 0:
		splash_high_score.text = "[center]ENDLESS HIGHSCORE\n--[/center]"
		splash_high_score_time.visible = false
		return
	splash_high_score.text = (
		"[center]ENDLESS HIGHSCORE\nround %d[/center]" % endless_best_round
	)
	splash_high_score_time.text = (
		"in %s" % _format_duration(endless_best_time_ms)
	)
	splash_high_score_time.visible = true


func _progression_round() -> int:
	if game_mode == GameMode.CHALLENGE and not challenge_endless:
		return current_challenge.start_round + run_completed_rounds
	if game_mode in [GameMode.ENDLESS, GameMode.CHECKPOINT, GameMode.CHALLENGE]:
		return round_number
	return Difficulty.TOTAL_ROUNDS - round_number + 1


func get_checkpoint_bonus_choice_count(start_round: int) -> int:
	return int(floor(float(start_round - 1) / Difficulty.BONUS_INTERVAL))


func _offer_checkpoint_backlog_bonus(completed_round_number: int) -> void:
	if game_mode != GameMode.CHECKPOINT or checkpoint_bonus_backlog <= 0:
		return
	if await bonus_manager.offer_bonus_choice(completed_round_number):
		checkpoint_bonus_backlog -= 1


func _update_checkpoint_high_score(reached_round: int) -> String:
	if current_checkpoint_id <= 0:
		return ""
	if checkpoint_uses_endless_progression:
		if reached_round <= checkpoint_endless_best_round:
			return ""
		checkpoint_endless_best_round = reached_round
	else:
		var rounds_left := _checkpoint_rounds_left(reached_round)
		if checkpoint_best_rounds_left >= 0 and rounds_left >= checkpoint_best_rounds_left:
			return ""
		checkpoint_best_rounds_left = rounds_left
	_save_checkpoint_progress()
	return "ROUND"


func _update_no_mistake_high_score(reached_round: int, elapsed_time_ms: int) -> void:
	if run_mistake_count != 0:
		return
	match game_mode:
		GameMode.CHECKPOINT:
			if checkpoint_uses_endless_progression:
				if reached_round > checkpoint_endless_no_mistake_round:
					checkpoint_endless_no_mistake_round = reached_round
					_save_checkpoint_progress()
			else:
				var rounds_left := _checkpoint_rounds_left(reached_round)
				if (
					checkpoint_no_mistake_rounds_left < 0
					or rounds_left < checkpoint_no_mistake_rounds_left
				):
					checkpoint_no_mistake_rounds_left = rounds_left
				_save_checkpoint_progress()
		GameMode.ENDLESS:
			if reached_round > endless_no_mistake_round:
				endless_no_mistake_round = reached_round
				_save_endless_progress()
		_:
			var better := (
				classic_no_mistake_rounds_left < 0
				or reached_round < classic_no_mistake_rounds_left
				or (
					reached_round == classic_no_mistake_rounds_left
					and (
						classic_no_mistake_time_ms < 0
						or elapsed_time_ms < classic_no_mistake_time_ms
					)
				)
			)
			if better:
				classic_no_mistake_rounds_left = reached_round
				classic_no_mistake_time_ms = elapsed_time_ms
				_save_high_score()


func _checkpoint_rounds_left(internal_round: int) -> int:
	return maxi(Difficulty.TOTAL_ROUNDS - internal_round + 1, 0)


func _checkpoint_result_text(internal_round: int) -> String:
	if checkpoint_uses_endless_progression:
		return "ROUND %d REACHED" % internal_round
	return "%d ROUNDS LEFT" % _checkpoint_rounds_left(internal_round)


func _capture_checkpoint_candidate() -> void:
	if not Difficulty.ENABLE_CHECKPOINTS:
		return
	var internal_round := _progression_round()
	if internal_round <= 0 or internal_round % Difficulty.CHECKPOINT_INTERVAL != 0:
		_pending_checkpoint_snapshot = null
		return
	var checkpoint_id := int(internal_round / Difficulty.CHECKPOINT_INTERVAL)
	if unlocked_checkpoints.has(checkpoint_id):
		_pending_checkpoint_snapshot = null
		return
	var snapshot := CheckpointSnapshot.new()
	snapshot.checkpoint_id = checkpoint_id
	snapshot.start_round = internal_round
	snapshot.pile_count = pile_count
	snapshot.hand_size = hand_size
	snapshot.start_value = start_value
	snapshot.turn_time = turn_time
	snapshot.difficulty_droughts = difficulty_droughts.duplicate(true)
	snapshot.unlocked_endless = endless_unlocked
	_pending_checkpoint_snapshot = snapshot


func _unlock_completed_checkpoint(completed_round: int) -> bool:
	if (
		not Difficulty.ENABLE_CHECKPOINTS
		or completed_round % Difficulty.CHECKPOINT_INTERVAL != 0
	):
		return false
	var checkpoint_id := int(completed_round / Difficulty.CHECKPOINT_INTERVAL)
	if unlocked_checkpoints.has(checkpoint_id):
		# Crossing an already unlocked milestone starts a fresh flawless section.
		checkpoint_segment_damage_count = 0
		_pending_checkpoint_snapshot = null
		return false
	if checkpoint_id > 1 and not unlocked_checkpoints.has(checkpoint_id - 1):
		# Checkpoints form a strict chain. A later milestone cannot fill a gap,
		# even after a flawless section.
		return false
	if checkpoint_segment_damage_count > 0 or _pending_checkpoint_snapshot == null:
		return false
	unlocked_checkpoints.append(checkpoint_id)
	unlocked_checkpoints.sort()
	checkpoint_snapshots[checkpoint_id] = _pending_checkpoint_snapshot.to_dictionary()
	newly_unlocked_checkpoints.append(checkpoint_id)
	_save_checkpoint_progress()
	_pending_checkpoint_snapshot = null
	checkpoint_segment_damage_count = 0
	_refresh_checkpoint_button()
	return true


func start_from_checkpoint(
	checkpoint_id: int,
	restored_bonuses: Dictionary = {},
	skip_bonus_choices := false
) -> bool:
	var snapshot_value: Variant = _checkpoint_value(checkpoint_snapshots, checkpoint_id, null)
	if not snapshot_value is Dictionary:
		return false
	_gameplay_generation += 1
	var snapshot := CheckpointSnapshot.from_dictionary(snapshot_value)
	soft_audio.play_start()
	music_manager.set_low_pass_enabled(false, true)
	_hand_cycle_generation += 1
	_pending_interactive_generation = -1
	game_mode = GameMode.CHECKPOINT
	current_challenge = null
	challenge_endless = false
	challenge_modifiers = ChallengeModifiers.new()
	_configure_challenge_hand_tray()
	bonus_manager.disabled_bonus_ids.clear()
	special_rule_manager.disabled_rule_ids.clear()
	special_rule_manager.forced_rule_ids.clear()
	special_rule_manager.force_rules_every_round = false
	special_rule_manager.forced_rule_count = 0
	special_rule_manager.disable_rules_on_challenge_first_round = false
	current_checkpoint_id = checkpoint_id
	checkpoint_bonus_backlog = (
		0 if skip_bonus_choices else get_checkpoint_bonus_choice_count(snapshot.start_round)
	)
	checkpoint_uses_endless_progression = (
		snapshot.start_round > Difficulty.TOTAL_ROUNDS
	)
	round_number = snapshot.start_round
	pile_count = snapshot.pile_count
	hand_size = snapshot.hand_size
	start_value = snapshot.start_value
	turn_time = snapshot.turn_time
	difficulty_droughts = _normalise_droughts(snapshot.difficulty_droughts)
	endless_unlocked = endless_unlocked or snapshot.unlocked_endless
	run_mistake_count = 0
	run_lives_lost = 0
	run_completed_rounds = 0
	run_start_round = snapshot.start_round
	started_from_checkpoint = true
	checkpoint_segment_damage_count = 0
	newly_discovered_bonuses.clear()
	newly_encountered_rules.clear()
	newly_unlocked_achievements.clear()
	newly_unlocked_fonts.clear()
	newly_unlocked_checkpoints.clear()
	tier_reliefs_applied = 0
	music_manager.reset_game_sections(1)
	music_manager.transition_to_game_music()
	game_started_msec = Time.get_ticks_msec()
	run_paused_msec = 0
	run_pause_started_msec = game_started_msec
	round_reached_time_ms = 0
	run_time_label.visible = _global_timer_enabled
	overlay.visible = false
	overlay_mode = ""
	_restore_gameplay_transition_elements()
	splash.visible = false
	back_button.visible = true
	bonus_manager.begin_run()
	if skip_bonus_choices:
		bonus_manager.grant_starting_bonuses(restored_bonuses)
	start_round()
	return true


func _normalise_droughts(value: Dictionary) -> Dictionary:
	var result := _new_difficulty_droughts()
	for stat: StringName in result.keys():
		result[stat] = clampi(
			int(value.get(stat, value.get(String(stat), 0))),
			0,
			Difficulty.MAX_STAT_DROUGHT
		)
	return result


func _save_checkpoint_progress() -> void:
	var config := ConfigFile.new()
	config.load(AUDIO_CONFIG_PATH)
	config.set_value("save", "schema_version", SAVE_SCHEMA_VERSION)
	config.set_value("checkpoints", "unlocked", unlocked_checkpoints)
	config.set_value(
		"checkpoints", "interval", Difficulty.CHECKPOINT_INTERVAL
	)
	config.set_value("checkpoints", "snapshots", checkpoint_snapshots)
	config.set_value("checkpoints", "highscores", checkpoint_highscores)
	config.set_value(
		"checkpoints", "no_mistake_highscores", checkpoint_no_mistake_highscores
	)
	config.set_value("checkpoints", "best", checkpoint_best_round)
	config.set_value(
		"checkpoints", "best_no_mistake", checkpoint_no_mistake_best_round
	)
	config.set_value(
		"checkpoints", "best_rounds_left", checkpoint_best_rounds_left
	)
	config.set_value(
		"checkpoints", "endless_best_round", checkpoint_endless_best_round
	)
	config.set_value(
		"checkpoints", "no_mistake_rounds_left",
		checkpoint_no_mistake_rounds_left
	)
	config.set_value(
		"checkpoints", "endless_no_mistake_round",
		checkpoint_endless_no_mistake_round
	)
	config.save(AUDIO_CONFIG_PATH)


func _load_checkpoint_progress(config: ConfigFile) -> void:
	unlocked_checkpoints.assign(config.get_value("checkpoints", "unlocked", []))
	checkpoint_snapshots = Dictionary(
		config.get_value("checkpoints", "snapshots", {})
	).duplicate(true)
	checkpoint_highscores = Dictionary(
		config.get_value("checkpoints", "highscores", {})
	).duplicate(true)
	checkpoint_no_mistake_highscores = Dictionary(
		config.get_value("checkpoints", "no_mistake_highscores", {})
	).duplicate(true)
	var checkpoint_ids_changed := _normalise_checkpoint_ids()
	checkpoint_best_round = int(config.get_value("checkpoints", "best", -1))
	checkpoint_no_mistake_best_round = int(
		config.get_value("checkpoints", "best_no_mistake", -1)
	)
	checkpoint_best_rounds_left = int(
		config.get_value("checkpoints", "best_rounds_left", -1)
	)
	checkpoint_endless_best_round = int(
		config.get_value("checkpoints", "endless_best_round", -1)
	)
	checkpoint_no_mistake_rounds_left = int(
		config.get_value("checkpoints", "no_mistake_rounds_left", -1)
	)
	checkpoint_endless_no_mistake_round = int(
		config.get_value("checkpoints", "endless_no_mistake_round", -1)
	)
	# Migrate the former per-checkpoint leaderboards into one shared score.
	if checkpoint_best_round < 0:
		for value in checkpoint_highscores.values():
			checkpoint_best_round = maxi(checkpoint_best_round, int(value))
	if checkpoint_no_mistake_best_round < 0:
		for value in checkpoint_no_mistake_highscores.values():
			checkpoint_no_mistake_best_round = maxi(
				checkpoint_no_mistake_best_round, int(value)
			)
	if checkpoint_best_rounds_left < 0 and checkpoint_best_round >= 0:
		if checkpoint_best_round > Difficulty.TOTAL_ROUNDS:
			checkpoint_endless_best_round = maxi(
				checkpoint_endless_best_round, checkpoint_best_round
			)
		else:
			checkpoint_best_rounds_left = _checkpoint_rounds_left(
				checkpoint_best_round
			)
	if (
		checkpoint_no_mistake_rounds_left < 0
		and checkpoint_no_mistake_best_round >= 0
	):
		if checkpoint_no_mistake_best_round > Difficulty.TOTAL_ROUNDS:
			checkpoint_endless_no_mistake_round = maxi(
				checkpoint_endless_no_mistake_round,
				checkpoint_no_mistake_best_round
			)
		else:
			checkpoint_no_mistake_rounds_left = _checkpoint_rounds_left(
				checkpoint_no_mistake_best_round
			)
	if checkpoint_ids_changed:
		_save_checkpoint_progress()


func _normalise_checkpoint_ids() -> bool:
	var migrated_snapshots: Dictionary = {}
	var migrated_unlocked: Array[int] = []
	var changed := false
	for old_key in checkpoint_snapshots.keys():
		var snapshot_value: Variant = checkpoint_snapshots[old_key]
		if not snapshot_value is Dictionary:
			changed = true
			continue
		var snapshot := CheckpointSnapshot.from_dictionary(snapshot_value)
		if (
			snapshot.start_round <= 0
			or snapshot.start_round % Difficulty.CHECKPOINT_INTERVAL != 0
		):
			# Preserve unusual legacy data under its old key; it remains available
			# for migration inspection but is not presented as a valid checkpoint.
			migrated_snapshots[old_key] = snapshot_value
			changed = true
			continue
		var expected_id := int(
			snapshot.start_round / Difficulty.CHECKPOINT_INTERVAL
		)
		if int(old_key) != expected_id or snapshot.checkpoint_id != expected_id:
			changed = true
		snapshot.checkpoint_id = expected_id
		# Never replace the first snapshot already assigned to the same round.
		if not migrated_snapshots.has(expected_id):
			migrated_snapshots[expected_id] = snapshot.to_dictionary()
			migrated_unlocked.append(expected_id)
	migrated_unlocked.sort()
	# A player who reached a later checkpoint necessarily passed every earlier
	# milestone. Old schemas may not contain snapshots for those milestones.
	# Rebuild them with safe permanent defaults so the earliest FROM option is
	# never skipped merely because the checkpoint feature was added later.
	if not migrated_unlocked.is_empty():
		var highest_id: int = migrated_unlocked.back()
		for checkpoint_id in range(1, highest_id + 1):
			if migrated_snapshots.has(checkpoint_id):
				continue
			var fallback := CheckpointSnapshot.new()
			fallback.checkpoint_id = checkpoint_id
			fallback.start_round = checkpoint_id * Difficulty.CHECKPOINT_INTERVAL
			fallback.pile_count = Difficulty.START_PILES
			fallback.hand_size = Difficulty.START_HAND_SIZE
			fallback.start_value = Difficulty.START_CARD_VALUE
			fallback.turn_time = Difficulty.START_TURN_TIME
			fallback.difficulty_droughts = _new_difficulty_droughts()
			fallback.unlocked_endless = endless_unlocked
			migrated_snapshots[checkpoint_id] = fallback.to_dictionary()
			migrated_unlocked.append(checkpoint_id)
			changed = true
		migrated_unlocked.sort()
	if migrated_unlocked != unlocked_checkpoints:
		changed = true
	checkpoint_snapshots = migrated_snapshots
	unlocked_checkpoints = migrated_unlocked
	return changed


func _checkpoint_value(values: Dictionary, checkpoint_id: int, fallback: Variant) -> Variant:
	if values.has(checkpoint_id):
		return values[checkpoint_id]
	var string_id := str(checkpoint_id)
	return values.get(string_id, fallback)


func _apply_debug_checkpoints() -> void:
	var requested_checkpoint := Debug.start_from_checkpoint()
	if not Debug.unlock_all_checkpoints() and requested_checkpoint <= 0:
		return
	var last_checkpoint := (
		int(Difficulty.TOTAL_ROUNDS / Difficulty.CHECKPOINT_INTERVAL)
		if Debug.unlock_all_checkpoints()
		else requested_checkpoint
	)
	_generate_debug_checkpoint_snapshots(last_checkpoint)


func _generate_debug_checkpoint_snapshots(last_checkpoint: int) -> void:
	var saved_difficulty := {
		"pile_count": pile_count,
		"hand_size": hand_size,
		"start_value": start_value,
		"turn_time": turn_time,
		"difficulty_droughts": difficulty_droughts.duplicate(true),
		"tier_reliefs_applied": tier_reliefs_applied,
		"rng_state": rng.state,
	}
	pile_count = Difficulty.START_PILES
	hand_size = Difficulty.START_HAND_SIZE
	start_value = Difficulty.START_CARD_VALUE
	turn_time = Difficulty.START_TURN_TIME
	difficulty_droughts = _new_difficulty_droughts()
	tier_reliefs_applied = 0
	# Debug checkpoints must be reproducible and must not consume the gameplay
	# RNG sequence used by the run that follows.
	rng.seed = 0x50494C45
	var final_round := last_checkpoint * Difficulty.CHECKPOINT_INTERVAL
	for progression_round in range(2, final_round + 1):
		_advance_difficulty(progression_round, 1 if progression_round == 2 else 0)
		if progression_round % Difficulty.CHECKPOINT_INTERVAL != 0:
			continue
		var checkpoint_id := int(progression_round / Difficulty.CHECKPOINT_INTERVAL)
		if unlocked_checkpoints.has(checkpoint_id):
			continue
		var snapshot := CheckpointSnapshot.new()
		snapshot.checkpoint_id = checkpoint_id
		snapshot.start_round = progression_round
		snapshot.pile_count = pile_count
		snapshot.hand_size = hand_size
		snapshot.start_value = start_value
		snapshot.turn_time = turn_time
		snapshot.difficulty_droughts = difficulty_droughts.duplicate(true)
		snapshot.unlocked_endless = endless_unlocked
		unlocked_checkpoints.append(checkpoint_id)
		checkpoint_snapshots[checkpoint_id] = snapshot.to_dictionary()
	pile_count = int(saved_difficulty.pile_count)
	hand_size = int(saved_difficulty.hand_size)
	start_value = int(saved_difficulty.start_value)
	turn_time = float(saved_difficulty.turn_time)
	difficulty_droughts = Dictionary(saved_difficulty.difficulty_droughts)
	tier_reliefs_applied = int(saved_difficulty.tier_reliefs_applied)
	rng.state = int(saved_difficulty.rng_state)
	unlocked_checkpoints.sort()


func _migrate_save(config: ConfigFile) -> void:
	var schema_version := int(config.get_value("save", "schema_version", 0))
	if schema_version >= SAVE_SCHEMA_VERSION:
		return
	config.set_value("save", "schema_version", SAVE_SCHEMA_VERSION)
	config.set_value(
		"progression", "discovered_bonuses",
		config.get_value("progression", "discovered_bonuses", [])
	)
	config.set_value(
		"progression", "max_discovered_tile_value",
		config.get_value(
			"progression", "max_discovered_tile_value",
			Difficulty.START_CARD_VALUE
		)
	)
	config.set_value(
		"progression", "seen_bonuses",
		config.get_value(
			"progression", "seen_bonuses",
			config.get_value("progression", "discovered_bonuses", [])
		)
	)
	config.set_value(
		"progression", "encountered_special_rules",
		config.get_value("progression", "encountered_special_rules", [])
	)
	config.set_value(
		"progression", "unlocked_achievements",
		config.get_value("progression", "unlocked_achievements", [])
	)
	config.set_value(
		"progression", "unlocked_fonts",
		config.get_value("progression", "unlocked_fonts", [&"press_start_2p"])
	)
	config.set_value(
		"progression", "beaten_special_rules",
		config.get_value("progression", "beaten_special_rules", [])
	)
	config.set_value(
		"progression", "achievement_unlock_dates",
		config.get_value("progression", "achievement_unlock_dates", {})
	)
	config.set_value(
		"progression", "bonuses_maxed_once",
		config.get_value("progression", "bonuses_maxed_once", {})
	)
	config.set_value(
		"progression", "bonus_highest_levels",
		config.get_value("progression", "bonus_highest_levels", {})
	)
	config.save(AUDIO_CONFIG_PATH)


func _on_bonus_selected(bonus_id: StringName) -> void:
	if not seen_bonuses.has(bonus_id):
		seen_bonuses.append(bonus_id)
	if bonus_id == &"pile_mover":
		_refresh_pile_mover_cursors()
	if not discovered_bonuses.has(bonus_id):
		discovered_bonuses.append(bonus_id)
		newly_discovered_bonuses.append(bonus_id)
		_mark_progression_item_unread(ProgressionMenu.Page.BONUSES, bonus_id)
		_save_discoveries()
	achievement_manager.bonus_acquired.emit(
		bonus_id,
		bonus_manager.level(bonus_id),
		bonus_manager.active_levels(),
		discovered_bonuses
	)


func _on_bonuses_seen(bonus_ids: Array[StringName]) -> void:
	var changed := false
	for bonus_id in bonus_ids:
		if seen_bonuses.has(bonus_id):
			continue
		seen_bonuses.append(bonus_id)
		changed = true
	if changed:
		_save_discoveries()


func _refresh_pile_mover_cursors() -> void:
	var pile_mover_active := bonus_manager.has_bonus(&"pile_mover")
	for pile in piles:
		if is_instance_valid(pile):
			pile.set_movable(pile_mover_active)


func _on_special_rules_selected(rules: Array[SpecialRuleData]) -> void:
	for rule in rules:
		if encountered_special_rules.has(rule.id):
			continue
		encountered_special_rules.append(rule.id)
		newly_encountered_rules.append(rule.id)
		_mark_progression_item_unread(ProgressionMenu.Page.SPECIAL_RULES, rule.id)
	_save_discoveries()


func _save_discoveries() -> void:
	var config := ConfigFile.new()
	config.load(AUDIO_CONFIG_PATH)
	config.set_value("progression", "discovered_bonuses", discovered_bonuses)
	config.set_value(
		"progression", "max_discovered_tile_value", max_discovered_tile_value
	)
	config.set_value("progression", "seen_bonuses", seen_bonuses)
	config.set_value("progression", "encountered_special_rules", encountered_special_rules)
	config.set_value("progression", "beaten_special_rules", beaten_special_rules)
	config.save(AUDIO_CONFIG_PATH)


func _emit_difficulty_stats() -> void:
	if start_value > max_discovered_tile_value:
		max_discovered_tile_value = mini(start_value, Difficulty.MAX_CARD_VALUE)
		_save_discoveries()
	achievement_manager.difficulty_stat_changed.emit(&"pile_count", pile_count)
	achievement_manager.difficulty_stat_changed.emit(&"hand_size", hand_size)
	achievement_manager.difficulty_stat_changed.emit(&"start_value", start_value)
	achievement_manager.difficulty_stat_changed.emit(&"turn_time", turn_time)


func _build_run_summary(normal_game_completed: bool) -> RunSummary:
	var summary := RunSummary.new()
	match game_mode:
		GameMode.ENDLESS:
			summary.mode = RunSummary.Mode.ENDLESS
		GameMode.CHECKPOINT:
			summary.mode = RunSummary.Mode.CHECKPOINT
		GameMode.CHALLENGE:
			summary.mode = RunSummary.Mode.CHALLENGE
		_:
			summary.mode = RunSummary.Mode.NORMAL
	summary.started_from_checkpoint = started_from_checkpoint
	summary.start_round = run_start_round
	summary.completed_rounds = run_completed_rounds
	summary.highest_round = _progression_round()
	summary.run_time_seconds = _total_time_milliseconds() / 1000.0
	summary.mistakes_made = run_mistake_count
	summary.lives_lost = run_lives_lost
	summary.active_bonus_levels = bonus_manager.active_levels()
	summary.normal_game_completed = normal_game_completed and (
		game_mode == GameMode.STANDARD
		or (game_mode == GameMode.CHECKPOINT and not checkpoint_uses_endless_progression)
	)
	summary.uses_endless_progression = (
		game_mode == GameMode.ENDLESS
		or (game_mode == GameMode.CHECKPOINT and checkpoint_uses_endless_progression)
	)
	return summary


func _on_achievement_unlocked(data: AchievementData) -> void:
	newly_unlocked_achievements.append(data.id)
	_mark_progression_item_unread(ProgressionMenu.Page.ACHIEVEMENTS, data.id)
	for font_id in font_manager.unlock_for_achievement(data.id):
		newly_unlocked_fonts.append(font_id)
	palette_manager.unlock_for_achievement(data.id)
	_queue_achievement_notification(data)


func _queue_achievement_notification(data: AchievementData) -> void:
	AchievementNotificationControllerScript.queue(self, data)


func _play_achievement_notifications() -> void:
	await AchievementNotificationControllerScript.play(self)


func _pause_achievement_notifications(source: StringName) -> void:
	AchievementNotificationControllerScript.pause(self, source)


func _resume_achievement_notifications(source: StringName) -> void:
	AchievementNotificationControllerScript.resume(self, source)


func _on_bonus_selection_visibility_changed() -> void:
	if bonus_selection.visible:
		_pause_achievement_notifications(&"bonus_selection")
	else:
		_resume_achievement_notifications(&"bonus_selection")


func _position_achievement_popup() -> void:
	AchievementNotificationControllerScript.position(self)
