class_name AchievementNotificationController
extends RefCounted


static func queue(game: GameManager, data: AchievementData) -> void:
	if not game._achievement_notifications_enabled:
		return
	game._achievement_notification_queue.append(data)
	if not game._achievement_notification_active:
		game.call_deferred("_play_achievement_notifications")


static func play(game: GameManager) -> void:
	if game._achievement_notification_active:
		return
	game._achievement_notification_active = true
	while (
		game._achievement_notifications_enabled
		and not game._achievement_notification_queue.is_empty()
	):
		while (
			not game._important_announcement_sources.is_empty()
			or game._achievement_resume_delay_pending
		):
			if not game._important_announcement_sources.is_empty():
				await game.get_tree().process_frame
			else:
				game._achievement_resume_delay_pending = false
				if game.achievement_popup_after_announcements_delay > 0.0:
					await game.get_tree().create_timer(
						game.achievement_popup_after_announcements_delay
					).timeout
			if not game._achievement_notifications_enabled:
				break
		if not game._achievement_notifications_enabled:
			break
		var data: AchievementData = (
			game._achievement_notification_queue.pop_front()
		)
		game.achievement_popup_title.text = data.title
		position(game)
		game.achievement_popup.visible = true
		game.achievement_popup.modulate.a = 0.0
		var target_y := game.achievement_popup.position.y
		game.achievement_popup.position.y = target_y - 16.0
		game.soft_audio.play_achievement()
		game._achievement_popup_tween = game.create_tween()
		game._achievement_popup_tween.set_trans(Tween.TRANS_QUAD)
		game._achievement_popup_tween.set_ease(Tween.EASE_OUT)
		game._achievement_popup_tween.set_parallel()
		game._achievement_popup_tween.tween_property(
			game.achievement_popup, "modulate:a", 1.0, 0.18
		)
		game._achievement_popup_tween.tween_property(
			game.achievement_popup, "position:y", target_y, 0.18
		)
		game._achievement_popup_tween.chain().tween_interval(1.5)
		game._achievement_popup_tween.chain().tween_property(
			game.achievement_popup, "modulate:a", 0.0, 0.2
		)
		await game._achievement_popup_tween.finished
	game.achievement_popup.visible = false
	game._achievement_notification_active = false


static func pause(game: GameManager, source: StringName) -> void:
	game._important_announcement_sources[source] = true


static func resume(game: GameManager, source: StringName) -> void:
	var was_paused := not game._important_announcement_sources.is_empty()
	game._important_announcement_sources.erase(source)
	if was_paused and game._important_announcement_sources.is_empty():
		game._achievement_resume_delay_pending = true
	if (
		not game._achievement_notification_active
		and not game._achievement_notification_queue.is_empty()
	):
		game.call_deferred("_play_achievement_notifications")


static func position(game: GameManager) -> void:
	var timer_bottom := 0.0
	for timer_control: Control in [game.timer_ring, game.run_time_label]:
		if timer_control.visible:
			timer_bottom = maxf(
				timer_bottom, timer_control.get_global_rect().end.y
			)
	var viewport_size := game.get_viewport_rect().size
	game.achievement_popup.position.x = floorf(
		(viewport_size.x - game.achievement_popup.size.x) * 0.5
	)
	game.achievement_popup.position.y = minf(
		maxf(50.0, timer_bottom + 24.0),
		viewport_size.y - game.achievement_popup.size.y - 4.0
	)
