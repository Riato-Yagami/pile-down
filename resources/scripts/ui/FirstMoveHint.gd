extends Control

const ARROW := preload("res://resources/sprites/first-move-arrow.svg")
## A visual gesture only: never consumes input or alters the seeded game.
var game: GameManager
var completed := false
var phase := 0.0
var start := Vector2.ZERO
var finish := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 50
	game.card_placed.connect(func(_card, _pile): completed = true)


func _process(delta: float) -> void:
	visible = false
	if completed or game.input_locked or game.splash.visible or game.quit_popup.visible:
		return
	if not game.gameplay_layer.visible or game.selected_card != null:
		return
	for card: PlayingCard in game.hand_manager.active_cards():
		for pile: MemoryPile in game.piles:
			if not pile.completed and (card.is_joker or pile.can_accept(card.card_value)):
				var inverse := get_global_transform().affine_inverse()
				start = inverse * card.get_global_rect().get_center()
				finish = inverse * pile.get_global_rect().get_center()
				phase = fmod(phase + delta / 1.6, 1.0)
				visible = true
				queue_redraw()
				return


func _draw() -> void:
	var tip := start.lerp(finish, smoothstep(0.0, 0.8, phase)).round()
	var direction := (finish - start).normalized()
	draw_set_transform(tip, direction.angle() + PI * 0.5)
	draw_texture(ARROW, Vector2(-6, 0), Color(GameColors.WHITE, sin(phase * PI)))
