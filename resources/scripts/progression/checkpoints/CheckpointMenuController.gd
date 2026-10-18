class_name CheckpointMenuController
extends RefCounted


static func open(game: GameManager) -> void:
	refresh_list(game)
	game.checkpoint_menu.visible = true
	var first := (
		game.checkpoint_list.get_child(0) as Control
		if game.checkpoint_list.get_child_count() > 0 else null
	)
	if first != null:
		first.grab_focus()


static func close(game: GameManager) -> void:
	game.checkpoint_menu.visible = false
	game.checkpoint_button.grab_focus()


static func refresh_button(game: GameManager, select_highest := false) -> void:
	var available := (
		DifficultySettings.ENABLE_CHECKPOINTS
		and not game.unlocked_checkpoints.is_empty()
	)
	game.checkpoint_button.get_parent().visible = available
	game.checkpoint_button.visible = available
	game.checkpoint_up_button.get_parent().visible = available
	if available and select_highest:
		game.selected_checkpoint_id = game.unlocked_checkpoints.back()
	elif not available or (
		game.selected_checkpoint_id != 0
		and not game.unlocked_checkpoints.has(game.selected_checkpoint_id)
	):
		game.selected_checkpoint_id = 0
	update_button_text(game)


static func refresh_list(game: GameManager) -> void:
	for child in game.checkpoint_list.get_children():
		child.queue_free()
	var normal_button := Button.new()
	normal_button.set_script(game.HIGHLIGHT_BUTTON_SCRIPT)
	normal_button.custom_minimum_size = Vector2(210, 43)
	normal_button.text = TranslationServer.translate("FROM %d") % 0
	normal_button.pressed.connect(game._on_checkpoint_selected.bind(0))
	game.checkpoint_list.add_child(normal_button)
	for checkpoint_id in game.unlocked_checkpoints:
		var value: Variant = game._checkpoint_value(
			game.checkpoint_snapshots, checkpoint_id, {}
		)
		if not value is Dictionary:
			continue
		var snapshot := CheckpointSnapshot.from_dictionary(value)
		var best := int(game._checkpoint_value(
			game.checkpoint_highscores, checkpoint_id, -1
		))
		var button := Button.new()
		button.set_script(game.HIGHLIGHT_BUTTON_SCRIPT)
		button.custom_minimum_size = Vector2(210, 43)
		button.text = TranslationServer.translate("CHECKPOINT %d\nROUND %d   BEST: %s") % [
			checkpoint_id, snapshot.start_round, str(best) if best >= 0 else "--"
		]
		button.pressed.connect(game._on_checkpoint_selected.bind(checkpoint_id))
		game.checkpoint_list.add_child(button)


static func select_next(game: GameManager, direction: int) -> void:
	if game.unlocked_checkpoints.is_empty():
		return
	# Zero is the normal start, not a saved checkpoint or a separate leaderboard.
	var choices: Array[int] = [0]
	choices.append_array(game.unlocked_checkpoints)
	var index := choices.find(game.selected_checkpoint_id)
	if index < 0:
		index = 0
	index = clampi(index + direction, 0, choices.size() - 1)
	game.selected_checkpoint_id = choices[index]
	update_button_text(game)
	show_selected(game)


static func update_button_text(game: GameManager) -> void:
	game.checkpoint_down_button.disabled = game.selected_checkpoint_id == 0
	game.checkpoint_up_button.disabled = (
		game.unlocked_checkpoints.is_empty()
		or game.selected_checkpoint_id == game.unlocked_checkpoints.back()
	)
	if game.selected_checkpoint_id == 0:
		game.checkpoint_button.text = TranslationServer.translate("FROM %d") % 0
		return
	var value: Variant = game._checkpoint_value(
		game.checkpoint_snapshots, game.selected_checkpoint_id, null
	)
	if value is Dictionary:
		var snapshot := CheckpointSnapshot.from_dictionary(value)
		game.checkpoint_button.text = TranslationServer.translate("FROM %d") % snapshot.start_round
	else:
		game.checkpoint_button.text = "FROM"


static func handle_button_input(game: GameManager, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select_next(game, 1)
			game.accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select_next(game, -1)
			game.accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_UP:
			select_next(game, 1)
			game.accept_event()
		elif event.keycode == KEY_DOWN:
			select_next(game, -1)
			game.accept_event()


static func show_selected(game: GameManager) -> void:
	if game.selected_checkpoint_id == 0:
		game._refresh_high_score()
		return
	var value: Variant = game._checkpoint_value(
		game.checkpoint_snapshots, game.selected_checkpoint_id, null
	)
	if not value is Dictionary:
		return
	var snapshot := CheckpointSnapshot.from_dictionary(value)
	if snapshot.start_round <= DifficultySettings.TOTAL_ROUNDS:
		game.splash_high_score.text = (
			TranslationServer.translate("[center]CHECKPOINT HIGHSCORE\n--[/center]")
			if game.checkpoint_best_rounds_left < 0
			else TranslationServer.translate("[center]CHECKPOINT HIGHSCORE\n%d rounds left[/center]")
			% game.checkpoint_best_rounds_left
		)
		game.splash_high_score_time.visible = false
		return
	game.splash_high_score.text = (
		TranslationServer.translate("[center]CHECKPOINT HIGHSCORE\nROUND REACHED[/center]")
	)
	game.splash_high_score_time.text = TranslationServer.translate("BEST: %s") % (
		str(game.checkpoint_endless_best_round)
		if game.checkpoint_endless_best_round >= 0 else "--"
	)
	game.splash_high_score_time.visible = true


static func show_unlocked(game: GameManager, checkpoint_id: int) -> void:
	game._pause_achievement_notifications(&"checkpoint")
	game.transient_label.text = TranslationServer.translate("CHECKPOINT %d\nUNLOCKED") % checkpoint_id
	game.transient_label.visible = true
	game.transient_label.modulate.a = 0.0
	var tween := game.create_tween()
	tween.tween_property(game.transient_label, "modulate:a", 1.0, 0.18)
	tween.tween_interval(1.0)
	tween.tween_property(game.transient_label, "modulate:a", 0.0, 0.18)
	game.skippable_sequence.begin(tween)
	if game._debug_round_wins_queued > 0:
		game.skippable_sequence.call_deferred("skip_to_end")
	await tween.finished
	game.skippable_sequence.finish()
	game.transient_label.visible = false
	game._resume_achievement_notifications(&"checkpoint")
