class_name SecretCodeManager
extends RefCounted

const CATALOG = preload("res://resources/data/secrets.tres")


static func redeem(game: GameManager, input: String) -> bool:
	for entry in CATALOG.enabled_data:
		var data := entry as SecretCodeData
		if data == null or data.code.to_lower() != input.strip_edges().to_lower():
			continue
		var message := TranslationServer.translate("CODE REQUIREMENTS NOT MET")
		if data.is_eligible(game.achievement_manager, int(Time.get_unix_time_from_system())):
			if data.reward_font == null or data.reward_font.font == null:
				message = TranslationServer.translate("REWARD NOT AVAILABLE")
			elif game.font_manager.unlock(data.reward_font.id):
				message = TranslationServer.translate("UNLOCKED: %s") % data.reward_font.display_name
				ProgressionUnreadStore.mark_item(game, ProgressionMenu.Page.FONTS, data.reward_font.id)
			else:
				message = TranslationServer.translate("ALREADY UNLOCKED: %s") % data.reward_font.display_name
		var notification := AchievementData.new()
		notification.title = message
		notification.notification_icon = preload("res://resources/materials/icons/fonts.tres")
		AchievementNotificationController.queue(game, notification)
		return true
	return false
