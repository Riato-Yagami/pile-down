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

enum DamageType {
	WRONG_PLACEMENT,
	TIMER_TIMEOUT,
	SUDDEN_DEATH,
	HOT_POTATO_RETURN,
	LAVA_RETURN,
	EMPTY_DROP,
	CONVEYOR_MISSED_CARD,
	RELOAD,
}

const CardPlacementControllerScript := preload(
	"res://resources/scripts/gameplay/interaction/CardPlacementController.gd"
)
const GameMenuPresenterScript := preload("res://resources/scripts/ui/game/GameMenuPresenter.gd")
const GameHudControllerScript := preload("res://resources/scripts/ui/game/GameHudController.gd")

const GameSessionControllerScript := preload(
	"res://resources/scripts/core/session/GameSessionController.gd"
)
const RoundFlowControllerScript := preload(
	"res://resources/scripts/gameplay/round/RoundFlowController.gd"
)
const CheckpointRunControllerScript := preload(
	"res://resources/scripts/progression/checkpoints/CheckpointRunController.gd"
)

const GameDebugControllerScript := preload(
	"res://resources/scripts/core/debug/GameDebugController.gd"
)
const GameScreenLayoutScript := preload("res://resources/scripts/ui/game/GameScreenLayout.gd")
const GameTransitionsScript := preload("res://resources/scripts/ui/game/GameTransitions.gd")
const RunRecordStoreScript := preload("res://resources/scripts/progression/RunRecordStore.gd")
const CheckpointProgressStoreScript := preload(
	"res://resources/scripts/progression/checkpoints/CheckpointProgressStore.gd"
)
const ConveyorControllerScript := preload("res://resources/scripts/gameplay/ConveyorController.gd")
const PileInteractionControllerScript := preload(
	"res://resources/scripts/gameplay/interaction/PileInteractionController.gd"
)
const HandDragControllerScript := preload(
	"res://resources/scripts/gameplay/interaction/HandDragController.gd"
)

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
	"res://resources/sprites/ui/check/unchecked.png"
)
const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")
const DifficultyProgressionScript := preload(
	"res://resources/scripts/gameplay/DifficultyProgression.gd"
)
const DifficultyAnnouncementScript := preload(
	"res://resources/scripts/ui/DifficultyAnnouncement.gd"
)
const ProgressionSnapshotBuilderScript := preload(
	"res://resources/scripts/progression/ProgressionSnapshotBuilder.gd"
)
const RunRNGScript := preload("res://resources/scripts/core/RunRNG.gd")
const SubmenuSwipeControllerScript := preload(
	"res://resources/scripts/ui/SubmenuSwipeController.gd"
)
const SubmenuPageAnimatorScript := preload(
	"res://resources/scripts/ui/SubmenuPageAnimator.gd"
)
const GameOptionsControllerScript := preload(
	"res://resources/scripts/settings/GameOptionsController.gd"
)
const ThemeManagerScript := preload("res://resources/scripts/theme/ThemeManager.gd")
const BackgroundManagerScript := preload(
	"res://resources/scripts/backgrounds/BackgroundManager.gd"
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
const LOCKED_VIEWPORT_SIZE := Vector2i(256, 320)
const AUDIO_CONFIG_PATH := SaveConfig.PATH
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
@onready var gameplay_layer: Control = $Gameplay
@onready var timer_label: Label = %TimerLabel
@onready var timer_ring: CountdownRing = %TimerRing
@onready var round_panel: TextureRect = %RoundPanel
@onready var round_label: Label = %RoundLabel
@onready var run_time_label: Label = %RunTimeLabel
@onready var mistakes_dots: RoundDots = %MistakesDots
@onready var transient_label: Label = %TransientLabel
@onready var round_wave: Control = %RoundWave
@onready var achievement_popup: Control = %AchievementPopup
@onready var achievement_popup_title: Label = %AchievementPopupTitle
@onready var bonus_selection: BonusSelection = %BonusSelection
@onready var skippable_sequence: SkippableSequence = %SkippableSequence
@onready var quit_popup: Control = %QuitPopup
@onready var quit_continue_button: Button = %QuitContinueButton
@onready var quit_restart_button: Button = %QuitRestartButton
@onready var quit_run_button: Button = %QuitRunButton
@onready var pause_seed_margin: MarginContainer = $PresentationLayers/QuitPopupLayer/QuitPopup/Center/Panel/Content/PauseSeedMargin
@onready var pause_seed_display: SeedCopyDisplay = $PresentationLayers/QuitPopupLayer/QuitPopup/Center/Panel/Content/PauseSeedMargin/PauseSeedDisplay
@onready var quit_panel: NinePatchRect = $PresentationLayers/QuitPopupLayer/QuitPopup/Center/Panel
@onready var quit_content: VBoxContainer = $PresentationLayers/QuitPopupLayer/QuitPopup/Center/Panel/Content
@onready var overlay: Control = %Overlay
@onready var overlay_title: RichTextLabel = $Screens/Overlay/OverlayCenter/ResultStack/OverlayPanel/Content/OverlayTitle
@onready var overlay_details: RichTextLabel = $Screens/Overlay/OverlayCenter/ResultStack/OverlayPanel/Content/OverlayDetails
@onready var overlay_button: Button = $Screens/Overlay/OverlayCenter/ResultStack/OverlayPanel/Content/OverlayButtons/OverlayButton
@onready var end_seed_display: SeedCopyDisplay = $Screens/Overlay/OverlayCenter/ResultStack/OverlayPanel/Content/EndSeedDisplay
@onready var overlay_endless_button: Button = $Screens/Overlay/OverlayCenter/ResultStack/OverlayPanel/Content/OverlayButtons/OverlayEndlessButton
@onready var overlay_high_score: RichTextLabel = $Screens/Overlay/OverlayCenter/ResultStack/OverlayHighScore
@onready var overlay_unlocks: RichTextLabel = $Screens/Overlay/OverlayCenter/ResultStack/OverlayUnlocks
@onready var overlay_quit_button: Button = $Screens/Overlay/OverlayCenter/ResultStack/OverlayPanel/Content/OverlayButtons/OverlayQuitButton
@onready var overlay_scrim: ColorRect = $Screens/Overlay/Scrim
@onready var overlay_panel: NinePatchRect = $Screens/Overlay/OverlayCenter/ResultStack/OverlayPanel
@onready var replay_transition_mask: ColorRect = %ReplayTransitionMask
@onready var menu_transition_layer: CanvasLayer = %MenuTransitionLayer
@onready var screens: Control = $Screens
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
@onready var screen_size_up_button: TextureHighlightButton = %ScreenSizeUpButton
@onready var screen_size_down_button: TextureHighlightButton = %ScreenSizeDownButton
@onready var adaptive_resolution_button: Button = %AdaptiveResolutionButton
@onready var true_pixel_art_button: Button = %TruePixelArtButton
@onready var dust_effects_button: Button = %DustEffectsButton
@onready var background_enabled_button: Button = %BackgroundEnabledButton
@onready var relief_lighting: ReliefLighting = %ReliefLighting
@onready var uniform_relief_light: DirectionalLight2D = %UniformReliefLight
@onready var pointer_relief_light: PointLight2D = %PointerReliefLight
@onready var achievement_notifications_button: Button = %AchievementNotificationsButton
@onready var timer_display_button: Button = %TimerDisplayButton
@onready var link_button_template: Button = %LinkButtonTemplate
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
var max_discovered_pile_count: int = Difficulty.START_PILES
var max_discovered_hand_size: int = Difficulty.START_HAND_SIZE
var min_discovered_turn_time: float = Difficulty.START_TURN_TIME
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
var flawless_since_last_bonus := true
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
var theme_manager := ThemeManagerScript.new()
var background_manager := BackgroundManagerScript.new()
var _round_mistakes_at_start := 0
var game_started_msec := 0
var run_paused_msec := 0
var run_pause_started_msec := -1
var round_reached_time_ms := 0
var mistakes_left := 3
var maximum_mistakes := 3
var selected_card: PlayingCard:
	set(value):
		selected_card = value
		if is_instance_valid(bonus_manager):
			bonus_manager.set_descriptions_enabled(not is_instance_valid(value))
var piles: Array[MemoryPile] = []
var input_locked := true
var run_rng := RunRNGScript.new()
var rng := RandomNumberGenerator.new()
var hands_rng := RandomNumberGenerator.new()
var cosmetic_rng := RandomNumberGenerator.new()
var run_seed_value := 0
var run_seed_label := ""
var run_uses_requested_seed := false
var run_seed_bonus_ids: Array[StringName] = []
var run_seed_bonus_levels: Dictionary = {}
var run_seed_rule_ids: Array[StringName] = []
var run_seed_difficulty: Dictionary = {}
var classic_record_seed: Dictionary = {}
var classic_no_mistake_record_seed: Dictionary = {}
var endless_record_seed: Dictionary = {}
var endless_no_mistake_record_seed: Dictionary = {}
var checkpoint_record_seed: Dictionary = {}
var checkpoint_no_mistake_record_seed: Dictionary = {}
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
var _submenu_page_animator := SubmenuPageAnimatorScript.new()
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
var _debug_help_expanded := false
var _debug_probability_visible := false
var _hand_cycle_generation := 0
var _pending_interactive_generation := -1
var _regeneration_hand_check_pending := false
var _music_volume_before_mute := 100.0
var _sound_volume_before_mute := 100.0
var _options_page := OPTION_GAMEPLAY
var _adaptive_resolution := false
var _screen_size_mode := &"semi_adaptive"
var _true_pixel_art_enabled := false
var _dust_enabled := true
var _viewport_effects_resize_pending := false
var _background_enabled := true
var dust_pool: DustPool
var background_effects
var _dust_previous_positions: Dictionary = {}
var _achievement_notifications_enabled := true
var _global_timer_enabled := false
var _achievement_notification_queue: Array[AchievementData] = []
var _achievement_notification_active := false
var _achievement_popup_tween: Tween
var _important_announcement_sources: Dictionary = {}
var _achievement_resume_delay_pending := false
var _timer_display_hidden := false
var _timer_visibility_tween: Tween
var _gameplay_back_cursor_update_queued := false
var _last_reminder_pile: MemoryPile
var _last_played_pile: MemoryPile
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
@export_category("Screen Edges")
@export var screen_edge_margins := Vector4(12.0, 8.0, 12.0, 12.0):
	set(value):
		screen_edge_margins = _normalized_edge_margins(value)
		if is_node_ready():
			_apply_screen_edge_margins()
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
	add_child(preload("res://resources/scripts/ui/MenuTouchScroll.gd").new())
	screens.visible = true
	_initialize_run_rng(RunRNGScript.generate_run_seed())
	quit_content.move_child(pause_seed_margin, quit_content.get_child_count() - 1)
	_submenu_swipe_controller.duration = submenu_swipe_duration
	_submenu_page_animator.duration = 0.18
	_submenu_page_animator.travel_distance = 18.0
	add_child(achievement_manager)
	add_child(challenge_manager)
	add_child(font_manager)
	add_child(palette_manager)
	add_child(theme_manager)
	add_child(background_manager)
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
	theme_manager.configure_from_palettes(
		palette_manager.definitions,
		_debug_or_selected_palette()
	)
	_load_unread_progression_pages()
	# Unlock newly introduced cosmetic rewards for achievements already earned
	# by an existing save.
	for achievement_id in achievement_manager.unlocked:
		font_manager.unlock_for_achievement(achievement_id)
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
	challenge_selection.seeded_run_requested.connect(_start_seeded_run)
	challenge_selection.closed.connect(_on_challenge_selection_closed)
	options_button.pressed.connect(_open_options_menu)
	options_back_button.pressed.connect(_close_options_menu)
	gameplay_options_button.pressed.connect(_show_options_page.bind(OPTION_GAMEPLAY, true))
	sound_options_button.pressed.connect(_show_options_page.bind(OPTION_SOUND, true))
	graphics_options_button.pressed.connect(_show_options_page.bind(OPTION_GRAPHICS, true))
	save_options_button.pressed.connect(_show_options_page.bind(OPTION_SAVE, true))
	links_options_button.pressed.connect(_show_options_page.bind(OPTION_LINKS, true))
	screen_size_up_button.pressed.connect(_step_screen_size_mode.bind(1))
	screen_size_down_button.pressed.connect(_step_screen_size_mode.bind(-1))
	adaptive_resolution_button.pressed.connect(_step_screen_size_mode.bind(1))
	true_pixel_art_button.pressed.connect(_toggle_true_pixel_art)
	dust_effects_button.pressed.connect(_toggle_dust_effects)
	background_enabled_button.pressed.connect(_toggle_background)
	achievement_notifications_button.pressed.connect(
		_toggle_achievement_notifications
	)
	timer_display_button.pressed.connect(_toggle_timer_display)
	GameMenuPresenterScript.setup_links(self)
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
	theme_manager.theme_changed.connect(_on_theme_changed)
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
	pause_seed_display.seed_copied.connect(soft_audio.play_seed_copy)
	end_seed_display.seed_copied.connect(soft_audio.play_seed_copy)
	debug_help.mouse_entered.connect(_on_debug_help_mouse_entered)
	debug_help.mouse_exited.connect(_on_debug_help_mouse_exited)
	splash_debug_help.mouse_entered.connect(_on_debug_help_mouse_entered)
	splash_debug_help.mouse_exited.connect(_on_debug_help_mouse_exited)
	debug_help.mouse_filter = Control.MOUSE_FILTER_PASS
	splash_debug_help.mouse_filter = Control.MOUSE_FILTER_PASS
	_setup_button_click_sounds()
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
	_apply_screen_edge_margins()
	_setup_dust_pool()
	_setup_save_dialogs()
	_load_high_score()
	_apply_debug_unlock_everything()
	_apply_debug_checkpoints()
	_refresh_checkpoint_button()
	splash_debug_mode.visible = Debug.is_enabled()
	input_locked = true
	splash.visible = true
	gameplay_layer.visible = false
	call_deferred("_resize_dust_distribution")
	_refresh_debug_help()
	font_manager.select(font_manager.selected_font)
	_apply_tile_font()
	_apply_tile_palette()
	_apply_global_theme()
	preload("res://resources/scripts/effects/RenderWarmup.gd").run.call_deferred(
		self, gameplay_layer, replay_transition_mask
	)
	var debug_checkpoint := Debug.start_from_checkpoint()
	if debug_checkpoint > 0:
		call_deferred("start_from_checkpoint", debug_checkpoint)


func _setup_audio_controls() -> void:
	GameOptionsControllerScript.setup_audio(self)


func _style_option_list_buttons() -> void:
	GameOptionsControllerScript.style_buttons(self)


func _setup_gameplay_options() -> void:
	GameOptionsControllerScript.setup_gameplay(self)


func _setup_button_click_sounds() -> void:
	for ui_root in [screens, $PresentationLayers]:
		_connect_button_click_sound_branch(ui_root)
	for gameplay_button in [back_button, redraw_button]:
		_connect_button_click_sound(gameplay_button)


func _connect_button_click_sound_branch(node: Node) -> void:
	if node == null:
		return
	if not node.child_entered_tree.is_connected(_connect_button_click_sound_branch):
		node.child_entered_tree.connect(_connect_button_click_sound_branch)
	if node is BaseButton:
		_connect_button_click_sound(node as BaseButton)
	for child in node.get_children():
		_connect_button_click_sound_branch(child)


func _connect_button_click_sound(button: BaseButton) -> void:
	if button == null or button.has_meta(&"ui_click_sound_connected"):
		return
	if _is_seed_copy_button(button):
		return
	button.set_meta(&"ui_click_sound_connected", true)
	button.pressed.connect(soft_audio.play_ui_click)


func _is_seed_copy_button(button: BaseButton) -> bool:
	var ancestor := button.get_parent()
	while ancestor != null:
		if ancestor is SeedCopyDisplay:
			return true
		ancestor = ancestor.get_parent()
	return false


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


func _flush_viewport_effects_resize() -> void:
	GameOptionsControllerScript.flush_viewport_effects_resize(self)


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
	GameDebugControllerScript.toggle_debug_unlock_everything(self)


func _apply_debug_unlock_everything() -> void:
	GameDebugControllerScript.apply_debug_unlock_everything(self)


func _set_adaptive_resolution(adaptive: bool) -> void:
	GameOptionsControllerScript.set_adaptive_resolution(self, adaptive)


func _toggle_adaptive_resolution() -> void:
	_set_adaptive_resolution(not _adaptive_resolution)


func _step_screen_size_mode(direction: int) -> void:
	GameOptionsControllerScript.step_screen_size_mode(self, direction)


func _toggle_true_pixel_art() -> void:
	GameOptionsControllerScript.toggle_true_pixel_art(self)


func _apply_resolution_mode() -> void:
	GameOptionsControllerScript.apply_resolution(self)


func _normalized_edge_margins(margins: Vector4) -> Vector4:
	return GameScreenLayoutScript.normalized_edge_margins(self, margins)


func _apply_screen_edge_margins() -> void:
	GameScreenLayoutScript.apply_screen_edge_margins(self)


func _apply_screen_margin_control(control: Control, margins: Vector4) -> void:
	GameScreenLayoutScript.apply_screen_margin_control(self, control, margins)


func _apply_bonus_title_margins(margins: Vector4) -> void:
	GameScreenLayoutScript.apply_bonus_title_margins(self, margins)


func _position_top_left(control: Control, left: float, top: float) -> void:
	GameScreenLayoutScript.position_top_left(self, control, left, top)


func _position_top_right(control: Control, right: float, top: float) -> void:
	GameScreenLayoutScript.position_top_right(self, control, right, top)


func _position_right_keep_top(control: Control, right: float) -> void:
	GameScreenLayoutScript.position_right_keep_top(self, control, right)


func _position_bottom_left(control: Control, left: float, bottom: float) -> void:
	GameScreenLayoutScript.position_bottom_left(self, control, left, bottom)


func _position_bottom_right(control: Control, right: float, bottom: float) -> void:
	GameScreenLayoutScript.position_bottom_right(self, control, right, bottom)


func _edge_size(control: Control) -> Vector2:
	return GameScreenLayoutScript.edge_size(self, control)


func _edge_width(control: Control) -> float:
	return GameScreenLayoutScript.edge_width(self, control)


func _setup_save_dialogs() -> void:
	GameOptionsControllerScript.setup_save_dialogs(self)


func _open_export_save_dialog() -> void:
	save_status.text = ""
	export_save_dialog.popup_centered_ratio(0.85)


func _open_import_save_dialog() -> void:
	save_status.text = ""
	import_save_dialog.popup_centered_ratio(0.85)


func _open_delete_save_confirmation() -> void:
	delete_save_confirmation.reset_size()
	delete_save_confirmation.popup_centered()
	delete_save_confirmation.get_cancel_button().grab_focus()


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
	GameHudControllerScript.emit_motion_dust(self, delta)


func _update_tile_background_weight() -> void:
	GameHudControllerScript.update_tile_background_weight(self)


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
			background_effects.emit_motion(
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
		_button_contains_pointer(back_button, event.position)
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
		and _button_contains_pointer(
			back_button, viewport.get_mouse_position()
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
	return _button_contains_pointer(button, pointer_position)


func _button_contains_pointer(button: BaseButton, pointer_position: Vector2) -> bool:
	var local_position := button.get_global_transform_with_canvas().affine_inverse() * pointer_position
	return Rect2(Vector2.ZERO, button.size).has_point(local_position)


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
	await GameSessionControllerScript.return_to_menu(self)


func _reset_to_menu_state() -> void:
	await GameSessionControllerScript.reset_to_menu_state(self)


func _open_quit_popup() -> void:
	if splash.visible or overlay.visible or quit_popup.visible:
		return
	pause_seed_margin.visible = run_uses_requested_seed
	pause_seed_display.visible = run_uses_requested_seed
	quit_panel.custom_minimum_size = (
		Vector2(252, 252) if run_uses_requested_seed else Vector2(180, 220)
	)
	if run_uses_requested_seed:
		pause_seed_display.set_seed(run_seed_label)
		pause_seed_display.set_copy_enabled(DisplayServer.has_feature(
			DisplayServer.FEATURE_CLIPBOARD
		))
	_fit_quit_popup_to_viewport()
	quit_popup.visible = true
	quit_continue_button.release_focus()
	quit_restart_button.release_focus()
	quit_run_button.release_focus()


func _fit_quit_popup_to_viewport() -> void:
	GameScreenLayoutScript.fit_quit_popup_to_viewport(self)


func _close_quit_popup() -> void:
	quit_popup.visible = false
	back_button.grab_focus()


func _restart_from_quit_popup() -> void:
	_restart_current_mode()


func _restart_current_mode() -> void:
	await GameSessionControllerScript.restart_current_mode(self)


func _mask_replay_transition() -> void:
	await GameTransitionsScript.mask_replay_transition(self)


func _unmask_replay_transition() -> void:
	await GameTransitionsScript.unmask_replay_transition(self)


func _maximum_iris_radius(center_uv: Vector2, aspect_ratio: float) -> float:
	return GameTransitionsScript.maximum_iris_radius(self, center_uv, aspect_ratio)


func _play_return_to_menu_transition() -> void:
	await GameTransitionsScript.play_return_to_menu_transition(self)


func _canvas_origin() -> Vector2:
	return GameScreenLayoutScript.canvas_origin(self)


func _canvas_size() -> Vector2:
	return GameScreenLayoutScript.canvas_size(self)


func _fit_control_to_canvas_space(control: Control, center_source: Control = null) -> void:
	GameScreenLayoutScript.fit_control_to_canvas_space(self, control, center_source)


func _fit_overlay_to_canvas() -> void:
	GameScreenLayoutScript.fit_overlay_to_canvas(self)


func _fit_splash_background_to_canvas() -> void:
	GameScreenLayoutScript.fit_splash_background_to_canvas(self)


func _fit_splash_background_to_local_rect() -> void:
	GameScreenLayoutScript.fit_splash_background_to_local_rect(self)


func _prepare_splash_transition_layout() -> void:
	GameScreenLayoutScript.prepare_splash_transition_layout(self)


func _restore_splash_screen_layout() -> void:
	GameScreenLayoutScript.restore_splash_screen_layout(self)


func _open_progression_menu() -> void:
	GameMenuPresenterScript.open_progression_menu(self)


func _submenu_travel_distance() -> float:
	return GameMenuPresenterScript.submenu_travel_distance(self)


func _open_options_menu() -> void:
	GameMenuPresenterScript.open_options_menu(self)


func _show_options_page(page: int, animate := false) -> void:
	GameMenuPresenterScript.show_options_page(self, page, animate)


func _open_external_link(url: String) -> void:
	GameMenuPresenterScript.open_external_link(self, url)


func _close_options_menu() -> void:
	await GameMenuPresenterScript.close_options_menu(self)


func _on_progression_menu_closed() -> void:
	await GameMenuPresenterScript.on_progression_menu_closed(self)


func _on_progression_font_selected(font_id: StringName) -> void:
	GameMenuPresenterScript.on_progression_font_selected(self, font_id)


func _on_progression_palette_selected(palette_id: StringName) -> void:
	GameMenuPresenterScript.on_progression_palette_selected(self, palette_id)


func _apply_tile_font() -> void:
	GameMenuPresenterScript.apply_tile_font(self)


func _apply_tile_palette() -> void:
	GameMenuPresenterScript.apply_tile_palette(self)


func _debug_or_selected_palette() -> StringName:
	return GameMenuPresenterScript.debug_or_selected_palette(self)


func _on_theme_changed(theme: ThemePaletteData) -> void:
	GameMenuPresenterScript.on_theme_changed(self, theme)


func _apply_global_theme() -> void:
	GameMenuPresenterScript.apply_global_theme(self)


func _sync_shader_background_visibility() -> void:
	GameMenuPresenterScript.sync_shader_background_visibility(self)


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
	return GameDebugControllerScript.handle_debug_shortcut(self, event)


func _debug_win_round() -> void:
	await GameDebugControllerScript.debug_win_round(self)


func _debug_lose_life() -> void:
	await GameDebugControllerScript.debug_lose_life(self)


func _debug_die() -> void:
	await GameDebugControllerScript.debug_die(self)


func _debug_next_background() -> void:
	GameDebugControllerScript.debug_next_background(self)


func _debug_reset_game() -> void:
	await GameDebugControllerScript.debug_reset_game(self)


func _debug_reset_progression() -> void:
	GameDebugControllerScript.debug_reset_progression(self)


func _refresh_debug_help() -> void:
	GameDebugControllerScript.refresh_debug_help(self)


func _on_debug_help_mouse_entered() -> void:
	GameDebugControllerScript.on_debug_help_mouse_entered(self)


func _on_debug_help_mouse_exited() -> void:
	GameDebugControllerScript.on_debug_help_mouse_exited(self)


func _set_debug_help_expanded(expanded: bool) -> void:
	GameDebugControllerScript.set_debug_help_expanded(self, expanded)


func _fit_debug_help(label: Label, on_splash: bool) -> void:
	GameDebugControllerScript.fit_debug_help(self, label, on_splash)


func _difficulty_probability_debug_text() -> String:
	return GameDebugControllerScript.difficulty_probability_debug_text(self)


func _initialize_run_rng(seed_value: int, seed_label := "") -> void:
	run_rng.initialize(seed_value, seed_label)
	run_seed_value = run_rng.seed_value
	run_seed_label = run_rng.seed_label
	rng = run_rng.get_stream(&"difficulty")
	hands_rng = run_rng.get_stream(&"hands")
	cosmetic_rng = run_rng.get_stream(&"cosmetic")
	hand_manager.set_run_rng(hands_rng)
	bonus_manager.set_run_rng(run_rng.get_stream(&"bonuses"))
	special_rule_manager.set_run_rng(
		run_rng.get_stream(&"special_rules"),
		run_rng.get_stream(&"movement")
	)


func _current_seed_record() -> Dictionary:
	return {"seed": run_seed_value, "seed_label": run_seed_label}


func _shuffle_with_rng(values: Array, stream: RandomNumberGenerator) -> void:
	RunRNG.shuffle(values, stream)


func _normalise_seed_bonus_levels(seed_bonuses: Variant) -> Dictionary:
	var result := {}
	if seed_bonuses is Dictionary:
		for id_value in seed_bonuses:
			var id := StringName(id_value)
			var data := BonusRegistry.get_bonus(id)
			if data != null:
				result[id] = clampi(int(seed_bonuses[id_value]), 1, data.max_level)
	elif seed_bonuses is Array:
		# Compatibility with seed replays saved before selectable levels existed.
		for id_value in seed_bonuses:
			var id := StringName(id_value)
			if BonusRegistry.get_bonus(id) != null:
				result[id] = 1
	return result


func start_game(
	endless_mode := false,
	challenge_data: ChallengeData = null,
	challenge_is_endless := false,
	requested_seed := "",
	seed_bonuses: Variant = [],
	seed_rule_ids: Array[StringName] = [],
	seed_difficulty: Dictionary = {}
) -> void:
	GameSessionControllerScript.start_game(
		self, endless_mode, challenge_data, challenge_is_endless, requested_seed, seed_bonuses, seed_rule_ids, seed_difficulty
	)


func _finish_animated_game_start() -> void:
	await GameSessionControllerScript.finish_animated_game_start(self)


func _prepare_gameplay_start_reveal() -> void:
	GameTransitionsScript.prepare_gameplay_start_reveal(self)


func _play_start_game_transition() -> void:
	await GameTransitionsScript.play_start_game_transition(self)


func _start_transition_elements() -> Array[Control]:
	return GameTransitionsScript.start_transition_elements(self)


func _restore_gameplay_transition_elements() -> void:
	GameTransitionsScript.restore_gameplay_transition_elements(self)


func start_round() -> void:
	await RoundFlowControllerScript.start_round(self)


func _layout_piles() -> void:
	RoundFlowControllerScript.layout_piles(self)


func _begin_turn(
	hand_prepared := false,
	enter_from_right := false,
	preserve_timer := false
) -> void:
	await RoundFlowControllerScript.begin_turn(self, hand_prepared, enter_from_right, preserve_timer)


func _prepare_next_hand(clear_existing: bool, enter_from_right: bool) -> void:
	await RoundFlowControllerScript.prepare_next_hand(self, clear_existing, enter_from_right)


func _generate_next_hand(
	requested_generation: int,
	clear_existing: bool,
	enter_from_right: bool,
	start_timer := true
) -> void:
	RoundFlowControllerScript.generate_next_hand(
		self, requested_generation, clear_existing, enter_from_right, start_timer
	)


func _draw_wandering_hand() -> void:
	RoundFlowControllerScript.draw_wandering_hand(self)


func _start_conveyor() -> void:
	ConveyorControllerScript.start_conveyor(self)


func _process_conveyor(delta: float) -> void:
	ConveyorControllerScript.process_conveyor(self, delta)


func _refresh_conveyor_pointer_hover() -> void:
	ConveyorControllerScript.refresh_conveyor_pointer_hover(self)


func _spawn_conveyor_card() -> PlayingCard:
	return ConveyorControllerScript.spawn_conveyor_card(self)


func _return_card_to_conveyor(card: PlayingCard) -> void:
	ConveyorControllerScript.return_card_to_conveyor(self, card)


func _configure_challenge_hand_tray() -> void:
	ConveyorControllerScript.configure_challenge_hand_tray(self)


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
	for current_card in hand_manager.current_cards:
		if (
			is_instance_valid(current_card)
			and current_card._entrance_animation_running
		):
			return
	_pending_interactive_generation = -1
	selected_card = null
	input_locked = false
	hand_manager.unlock_hand()
	_resolve_pending_shared_clock_timeout()


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
	CustomCursor.set_holding_card(true)
	if challenge_modifiers.commit_selected_cards:
		card.begin_commit()
		if challenge_modifiers.hide_selected_card_value:
			for companion in drag_companions:
				if is_instance_valid(companion):
					companion.begin_commit()
	soft_audio.play_tone(330.0, 0.045, 0.035)


func _prepare_drag_companions(main_card: PlayingCard) -> void:
	HandDragControllerScript.prepare_drag_companions(self, main_card)


func _resolve_companion_drops(anchor_pile: MemoryPile) -> Array[MemoryPile]:
	return await HandDragControllerScript.resolve_companion_drops(self, anchor_pile)


func _find_nearby_companion_pile(
	companion: PlayingCard,
	anchor_pile: MemoryPile,
	already_used: Array[MemoryPile]
) -> MemoryPile:
	return HandDragControllerScript.find_nearby_companion_pile(
		self, companion, anchor_pile, already_used
	)


func _return_drag_companions() -> void:
	await HandDragControllerScript.return_drag_companions(self)


func _return_companion_to_hand(card: PlayingCard) -> void:
	await HandDragControllerScript.return_companion_to_hand(self, card)


func _on_card_drag_released(card: PlayingCard, release_position: Vector2) -> void:
	if input_locked or card != selected_card or not card.dragging:
		return
	_card_touch_index = -1
	CustomCursor.set_holding_card(false)
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
	PileInteractionControllerScript.on_pile_drag_requested(self, pile, pointer_position)


func _on_pile_drag_released(pile: MemoryPile, pointer_position: Vector2) -> void:
	PileInteractionControllerScript.on_pile_drag_released(self, pile, pointer_position)


func _finish_pile_move() -> void:
	PileInteractionControllerScript.finish_pile_move(self)


func _nearest_valid_pile_position(
	pile: MemoryPile,
	requested_position: Vector2,
	fallback_position: Vector2
) -> Vector2:
	return PileInteractionControllerScript.nearest_valid_pile_position(
		self, pile, requested_position, fallback_position
	)


func _pile_movement_bounds(pile: MemoryPile) -> Rect2:
	return PileInteractionControllerScript.pile_movement_bounds(self, pile)


func _is_valid_pile_position(pile: MemoryPile) -> bool:
	return PileInteractionControllerScript.is_valid_pile_position(self, pile)


func _handle_pile_touch_input(event: InputEvent) -> bool:
	return PileInteractionControllerScript.handle_pile_touch_input(self, event)


func _update_touch_pile_position(pointer_position: Vector2) -> void:
	PileInteractionControllerScript.update_touch_pile_position(self, pointer_position)


func _handle_card_touch_input(event: InputEvent) -> bool:
	return HandDragControllerScript.handle_card_touch_input(self, event)


func _try_start_touch_card_drag() -> void:
	HandDragControllerScript.try_start_touch_card_drag(self)


func _card_at_touch_position(touch_position: Vector2) -> PlayingCard:
	return HandDragControllerScript.card_at_touch_position(self, touch_position)


func _transformed_control_rect(control: Control) -> Rect2:
	return HandDragControllerScript.transformed_control_rect(self, control)


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
	await CardPlacementControllerScript.place_selected_card(self, pile)


func _stack_card(
	card: PlayingCard,
	pile: MemoryPile,
	context: PlacementContext
) -> void:
	await CardPlacementControllerScript.stack_card(self, card, pile, context)


func _resolve_deja_vu(
	played_value: int,
	original_pile: MemoryPile,
	maximum_copies: int,
	origin: Vector2,
	root_action_id: int
) -> Array[MemoryPile]:
	return await CardPlacementControllerScript.resolve_deja_vu(
		self, played_value, original_pile, maximum_copies, origin, root_action_id
	)


func _resolve_double_down(
	pile: MemoryPile,
	maximum_bonus_cards: int,
	origin: Vector2,
	root_action_id: int
) -> int:
	return await CardPlacementControllerScript.resolve_double_down(
		self, pile, maximum_bonus_cards, origin, root_action_id
	)


func _finalize_placement_action(affected_piles: Array[MemoryPile]) -> void:
	await CardPlacementControllerScript.finalize_placement_action(self, affected_piles)


func _complete_pile(pile: MemoryPile) -> void:
	await CardPlacementControllerScript.complete_pile(self, pile)


func _after_valid_card_played() -> void:
	await CardPlacementControllerScript.after_valid_card_played(self)


func _handle_mistake(
	pile: MemoryPile = null,
	caused_by_timeout := false,
	force_damage := false,
	instant_death := false,
	damage_type := DamageType.WRONG_PLACEMENT
) -> void:
	await CardPlacementControllerScript.handle_mistake(
		self, pile, caused_by_timeout, force_damage, instant_death, damage_type
	)


func _reveal_mistake_pile(pile: MemoryPile) -> void:
	await CardPlacementControllerScript.reveal_mistake_pile(self, pile)


func _reveal_piles_before_game_over() -> void:
	await CardPlacementControllerScript.reveal_piles_before_game_over(self)


func _discard_rejected_conveyor_card(card: PlayingCard) -> void:
	await ConveyorControllerScript.discard_rejected_conveyor_card(self, card)


func _return_card_to_hand(card: PlayingCard, duration := 0.26) -> void:
	await HandDragControllerScript.return_card_to_hand(self, card, duration)


func _clear_drag_placeholder() -> void:
	HandDragControllerScript.clear_drag_placeholder(self)


func _create_hand_slot_placeholder(card: PlayingCard) -> Control:
	return HandDragControllerScript.create_hand_slot_placeholder(self, card)


func _remove_hand_slot_placeholder(card: PlayingCard) -> void:
	HandDragControllerScript.remove_hand_slot_placeholder(self, card)


func _valid_hand_slot_placeholder(card: PlayingCard) -> Control:
	return HandDragControllerScript.valid_hand_slot_placeholder(self, card)


func _clear_all_hand_slot_placeholders() -> void:
	HandDragControllerScript.clear_all_hand_slot_placeholders(self)


func _remove_orphan_drag_placeholders() -> void:
	HandDragControllerScript.remove_orphan_drag_placeholders(self)


func _restore_hand_child_order() -> void:
	HandDragControllerScript.restore_hand_child_order(self)


func _record_stable_hand_layout() -> void:
	HandDragControllerScript.record_stable_hand_layout(self)


func _discard_current_hand(preserve_unused_jokers := true) -> void:
	await hand_manager.discard_hand(
		hand_container,
		drag_layer,
		preserve_unused_jokers
	)
	_clear_all_hand_slot_placeholders()


func _start_discard_current_hand(preserve_unused_jokers := true) -> void:
	hand_manager.discard_hand(hand_container, drag_layer, preserve_unused_jokers)
	_clear_all_hand_slot_placeholders()


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
	CustomCursor.set_holding_card(false)
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
	await RoundFlowControllerScript.finish_round(self)


func _show_round_wave() -> void:
	await RoundFlowControllerScript.show_round_wave(self)


func _finish_game(completed_all_rounds := false) -> void:
	await GameSessionControllerScript.finish_game(self, completed_all_rounds)


func _end_gameplay_for_result_screen() -> void:
	GameSessionControllerScript.end_gameplay_for_result_screen(self)


func _is_finite_mode_victory(completed_all_rounds: bool) -> bool:
	return GameSessionControllerScript.is_finite_mode_victory(self, completed_all_rounds)


func _show_game_over_overlay(animate_death: bool) -> void:
	GameTransitionsScript.show_game_over_overlay(self, animate_death)


func _append_new_checkpoint_summary() -> void:
	GameMenuPresenterScript.append_new_checkpoint_summary(self)


func _append_new_progression_summary() -> void:
	GameMenuPresenterScript.append_new_progression_summary(self)


func _progression_icon_line(icon_path: String, titles: PackedStringArray) -> String:
	return GameMenuPresenterScript.progression_icon_line(self, icon_path, titles)


func _new_checkpoint_summary_line() -> String:
	return GameMenuPresenterScript.new_checkpoint_summary_line(self)


func _new_bonus_titles() -> PackedStringArray:
	return GameMenuPresenterScript.new_bonus_titles(self)


func _new_rule_titles() -> PackedStringArray:
	return GameMenuPresenterScript.new_rule_titles(self)


func _new_achievement_titles() -> PackedStringArray:
	return GameMenuPresenterScript.new_achievement_titles(self)


func _on_overlay_pressed() -> void:
	if overlay_mode == "restart":
		_restart_current_mode()


func _on_overlay_endless_pressed() -> void:
	var replay_seed := run_seed_label if run_uses_requested_seed else ""
	if game_mode == GameMode.CHALLENGE:
		start_game(
			false, current_challenge, true, replay_seed,
			run_seed_bonus_levels, run_seed_rule_ids, run_seed_difficulty.duplicate()
		)
	else:
		start_game(
			true, null, false, replay_seed,
			run_seed_bonus_levels, run_seed_rule_ids, run_seed_difficulty.duplicate()
		)


func _on_splash_pressed() -> void:
	start_game()


func _on_endless_pressed() -> void:
	start_game(true)


func _open_challenge_selection() -> void:
	challenge_selection.open(
		challenge_manager,
		achievement_manager.unlocked,
		discovered_bonuses,
		beaten_special_rules,
		achievement_manager.bonus_highest_levels,
		_seed_difficulty_limits()
	)
	_submenu_swipe_controller.open(
		challenge_selection, _submenu_travel_distance()
	)


func _on_challenge_selection_closed() -> void:
	await _submenu_swipe_controller.close(
		challenge_selection, _submenu_travel_distance()
	)
	challenge_button.grab_focus()


func _start_challenge(id: StringName, endless: bool) -> void:
	var data := challenge_manager.find(id)
	if data == null:
		return
	challenge_selection.visible = false
	start_game(false, data, endless)


func _start_seeded_run(
	seed_text: String, challenge_id: StringName,
	bonus_levels: Dictionary, rule_ids: Array[StringName],
	endless: bool, seed_difficulty: Dictionary
) -> void:
	var data: ChallengeData = null
	if not challenge_id.is_empty():
		data = challenge_manager.find(challenge_id)
		if data == null or not challenge_manager.is_unlocked(
			data, achievement_manager.unlocked
		):
			return
		endless = endless and data.allow_endless and challenge_manager.completed.has(data.id)
	else:
		endless = endless
	var allowed_bonus_levels := {}
	for id_value in bonus_levels:
		var bonus_id := StringName(id_value)
		if not discovered_bonuses.has(bonus_id):
			continue
		var bonus_data := BonusRegistry.get_bonus(bonus_id)
		if bonus_data == null:
			continue
		var unlocked_level := clampi(
			int(achievement_manager.bonus_highest_levels.get(bonus_id, 1)),
			1, bonus_data.max_level
		)
		allowed_bonus_levels[bonus_id] = clampi(
			int(bonus_levels[id_value]), 1, unlocked_level
		)
	var allowed_rule_ids: Array[StringName] = []
	for rule_id in rule_ids:
		if beaten_special_rules.has(rule_id):
			allowed_rule_ids.append(rule_id)
	challenge_selection.visible = false
	start_game(
		endless and data == null,
		data,
		endless and data != null,
		seed_text,
		allowed_bonus_levels,
		allowed_rule_ids,
		_sanitized_seed_difficulty(seed_difficulty)
	)


func _sanitized_seed_difficulty(seed_difficulty: Dictionary) -> Dictionary:
	if seed_difficulty.is_empty():
		return {}
	return {
		"pile_count": clampi(
			int(seed_difficulty.get("pile_count", Difficulty.START_PILES)),
			Difficulty.START_PILES,
			4
		),
		"hand_size": clampi(
			int(seed_difficulty.get("hand_size", Difficulty.START_HAND_SIZE)),
			Difficulty.START_HAND_SIZE,
			Difficulty.MAX_HAND_SIZE
		),
		"start_value": clampi(
			int(seed_difficulty.get("start_value", Difficulty.START_CARD_VALUE)),
			1,
			Difficulty.MAX_CARD_VALUE
		),
		"turn_time": clampf(
			float(seed_difficulty.get("turn_time", Difficulty.START_TURN_TIME)),
			Difficulty.MIN_TURN_TIME,
			Difficulty.START_TURN_TIME
		),
	}


func _apply_seed_difficulty(seed_difficulty: Dictionary) -> void:
	if seed_difficulty.is_empty():
		return
	pile_count = int(seed_difficulty.get("pile_count", pile_count))
	hand_size = int(seed_difficulty.get("hand_size", hand_size))
	start_value = int(seed_difficulty.get("start_value", start_value))
	turn_time = float(seed_difficulty.get("turn_time", turn_time))


func _open_checkpoint_menu() -> void:
	CheckpointMenuControllerScript.open(self)
	_submenu_swipe_controller.open(checkpoint_menu, _submenu_travel_distance())


func _close_checkpoint_menu() -> void:
	if not checkpoint_menu.visible:
		return
	await _submenu_swipe_controller.close(
		checkpoint_menu, _submenu_travel_distance()
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
	GameHudControllerScript.on_time_updated(self, time_left)


func _on_timer_visibility_requested(visible: bool) -> void:
	GameHudControllerScript.on_timer_visibility_requested(self, visible)


func _flash_clock_tick(urgency: float) -> void:
	GameHudControllerScript.flash_clock_tick(self, urgency)


func _update_hud() -> void:
	GameHudControllerScript.update_hud(self)


func _total_time_milliseconds() -> int:
	return GameHudControllerScript.total_time_milliseconds(self)


func _pause_run_time() -> void:
	GameHudControllerScript.pause_run_time(self)


func _resume_run_time() -> void:
	GameHudControllerScript.resume_run_time(self)


func _format_duration(total_msec: int) -> String:
	return GameHudControllerScript.format_duration(self, total_msec)


func _update_high_score(rounds_left: int, elapsed_time_ms: int) -> String:
	return RunRecordStoreScript.update_high_score(self, rounds_left, elapsed_time_ms)


func _save_high_score() -> void:
	RunRecordStoreScript.save_high_score(self)


func _update_endless_high_score(reached_round: int, elapsed_time_ms: int) -> String:
	return RunRecordStoreScript.update_endless_high_score(self, reached_round, elapsed_time_ms)


func _unlock_endless_mode() -> void:
	RunRecordStoreScript.unlock_endless_mode(self)


func _save_endless_progress() -> void:
	RunRecordStoreScript.save_endless_progress(self)


func _load_high_score() -> void:
	RunRecordStoreScript.load_high_score(self)


func _refresh_high_score() -> void:
	RunRecordStoreScript.refresh_high_score(self)


func _show_endless_high_score() -> void:
	RunRecordStoreScript.show_endless_high_score(self)


func _progression_round() -> int:
	if game_mode == GameMode.CHALLENGE and not challenge_endless:
		return current_challenge.start_round + run_completed_rounds
	if game_mode in [GameMode.ENDLESS, GameMode.CHECKPOINT, GameMode.CHALLENGE]:
		return round_number
	return Difficulty.TOTAL_ROUNDS - round_number + 1


func get_checkpoint_bonus_choice_count(start_round: int) -> int:
	return CheckpointRunControllerScript.get_checkpoint_bonus_choice_count(self, start_round)


func _offer_checkpoint_backlog_bonus(completed_round_number: int) -> void:
	await CheckpointRunControllerScript.offer_checkpoint_backlog_bonus(self, completed_round_number)


func _update_checkpoint_high_score(reached_round: int) -> String:
	return RunRecordStoreScript.update_checkpoint_high_score(self, reached_round)


func _update_no_mistake_high_score(reached_round: int, elapsed_time_ms: int) -> void:
	RunRecordStoreScript.update_no_mistake_high_score(self, reached_round, elapsed_time_ms)


func _checkpoint_rounds_left(internal_round: int) -> int:
	return maxi(Difficulty.TOTAL_ROUNDS - internal_round + 1, 0)


func _checkpoint_result_text(internal_round: int) -> String:
	if checkpoint_uses_endless_progression:
		return "ROUND %d REACHED" % internal_round
	return "%d ROUNDS LEFT" % _checkpoint_rounds_left(internal_round)


func _capture_checkpoint_candidate() -> void:
	CheckpointRunControllerScript.capture_checkpoint_candidate(self)


func _unlock_completed_checkpoint(completed_round: int) -> bool:
	return CheckpointRunControllerScript.unlock_completed_checkpoint(self, completed_round)


func start_from_checkpoint(
	checkpoint_id: int,
	restored_bonuses: Dictionary = {},
	skip_bonus_choices := false,
	requested_seed := ""
) -> bool:
	return CheckpointRunControllerScript.start_from_checkpoint(
		self, checkpoint_id, restored_bonuses, skip_bonus_choices, requested_seed
	)


static func breaks_flawless(damage_type: DamageType) -> bool:
	return damage_type in [
		DamageType.WRONG_PLACEMENT,
		DamageType.TIMER_TIMEOUT,
		DamageType.SUDDEN_DEATH,
	]


func _normalise_droughts(value: Dictionary) -> Dictionary:
	return CheckpointProgressStoreScript.normalise_droughts(self, value)


func _save_checkpoint_progress() -> void:
	CheckpointProgressStoreScript.save_checkpoint_progress(self)


func _load_checkpoint_progress(config: ConfigFile) -> void:
	CheckpointProgressStoreScript.load_checkpoint_progress(self, config)


func _normalise_checkpoint_ids() -> bool:
	return CheckpointProgressStoreScript.normalise_checkpoint_ids(self)


func _checkpoint_value(values: Dictionary, checkpoint_id: int, fallback: Variant) -> Variant:
	return CheckpointProgressStoreScript.checkpoint_value(self, values, checkpoint_id, fallback)


func _apply_debug_checkpoints() -> void:
	CheckpointProgressStoreScript.apply_debug_checkpoints(self)


func _generate_debug_checkpoint_snapshots(last_checkpoint: int) -> void:
	CheckpointProgressStoreScript.generate_debug_checkpoint_snapshots(self, last_checkpoint)


func _migrate_save(config: ConfigFile) -> void:
	RunRecordStoreScript.migrate_save(self, config)


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
	RunRecordStoreScript.save_discoveries(self)


func _refresh_discovered_difficulty_limits_from_progression() -> void:
	for snapshot_value in checkpoint_snapshots.values():
		if not snapshot_value is Dictionary:
			continue
		var snapshot := CheckpointSnapshot.from_dictionary(snapshot_value)
		max_discovered_pile_count = maxi(
			max_discovered_pile_count,
			clampi(snapshot.pile_count, Difficulty.START_PILES, Difficulty.MAX_PILES)
		)
		max_discovered_hand_size = maxi(
			max_discovered_hand_size,
			clampi(snapshot.hand_size, Difficulty.START_HAND_SIZE, Difficulty.MAX_HAND_SIZE)
		)
		max_discovered_tile_value = maxi(
			max_discovered_tile_value,
			clampi(snapshot.start_value, Difficulty.START_CARD_VALUE, Difficulty.MAX_CARD_VALUE)
		)
		min_discovered_turn_time = minf(
			min_discovered_turn_time,
			clampf(snapshot.turn_time, Difficulty.MIN_TURN_TIME, Difficulty.START_TURN_TIME)
		)
	if achievement_manager.unlocked.has(&"max_piles"):
		max_discovered_pile_count = Difficulty.MAX_PILES
	if achievement_manager.unlocked.has(&"max_hand"):
		max_discovered_hand_size = Difficulty.MAX_HAND_SIZE
	if achievement_manager.unlocked.has(&"start_value_nine"):
		max_discovered_tile_value = Difficulty.MAX_CARD_VALUE
	if achievement_manager.unlocked.has(&"minimum_timer"):
		min_discovered_turn_time = Difficulty.MIN_TURN_TIME


func _seed_difficulty_limits() -> Dictionary:
	return {
		"max_pile_count": max_discovered_pile_count,
		"max_hand_size": max_discovered_hand_size,
		"max_start_value": max_discovered_tile_value,
		"min_turn_time": min_discovered_turn_time,
	}


func _emit_difficulty_stats() -> void:
	var difficulty_discovery_changed := false
	if pile_count > max_discovered_pile_count:
		max_discovered_pile_count = mini(pile_count, Difficulty.MAX_PILES)
		difficulty_discovery_changed = true
	if hand_size > max_discovered_hand_size:
		max_discovered_hand_size = mini(hand_size, Difficulty.MAX_HAND_SIZE)
		difficulty_discovery_changed = true
	if start_value > max_discovered_tile_value:
		max_discovered_tile_value = mini(start_value, Difficulty.MAX_CARD_VALUE)
		difficulty_discovery_changed = true
	if turn_time < min_discovered_turn_time:
		min_discovered_turn_time = maxf(turn_time, Difficulty.MIN_TURN_TIME)
		difficulty_discovery_changed = true
	if difficulty_discovery_changed:
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
