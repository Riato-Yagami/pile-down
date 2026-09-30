extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/data/localization/fr.json"
	))
	var rules: Array[SpecialRuleData] = []
	for filename in DirAccess.get_files_at("res://resources/data/special_rules"):
		if not filename.ends_with(".tres"):
			continue
		var rule := load("res://resources/data/special_rules/" + filename) as SpecialRuleData
		rules.append(rule)
		for source: String in [rule.title, rule.subtitle, rule.description]:
			assert(catalog.has(source), "Missing French rule text: " + source)
	var announcement := preload("res://resources/scenes/special_rules/SpecialRuleAnnouncement.tscn").instantiate() as SpecialRuleAnnouncement
	root.add_child(announcement)
	announcement.fade_duration = 0.0
	announcement.display_duration = 0.0
	for locale: String in ["fr", "en"]:
		root.get_node("LanguageSettings").apply_language(locale, false)
		await announcement.show_rules([rules[0]])
		assert(announcement.subtitle_label.text == TranslationServer.translate(rules[0].subtitle))
		await announcement.show_rules([rules[0], rules[1]])
		assert(announcement.rules_label.text == "%s\n+\n%s" % [
			TranslationServer.translate(rules[0].title), TranslationServer.translate(rules[1].title),
		])
		# Combined captions must also be present in the catalog.
		for first in rules:
			for second in rules:
				var caption := announcement._combination_title([first, second])
				assert(caption.is_empty() or catalog.has(caption), "Missing French caption: " + caption)
	announcement.queue_free()
	await process_frame
	print("French rule text tests passed.")
	quit()
