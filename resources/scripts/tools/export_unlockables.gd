extends SceneTree
## Export des catalogues actifs, sans lire ni modifier la sauvegarde du joueur.

const DEFAULT_OUTPUT := "res://DEBLOCAGES.md"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var output := DEFAULT_OUTPUT
	var force := false
	var has_path := false
	for argument in OS.get_cmdline_user_args():
		if argument == "--force":
			force = true
		elif argument.begins_with("--") or has_path:
			_fail("Usage : --script resources/scripts/tools/export_unlockables.gd -- [sortie.md] [--force]")
			return
		else:
			output = argument
			has_path = true
	if not output.is_absolute_path():
		output = "res://".path_join(output)
	if output.get_extension().to_lower() != "md":
		_fail("Le fichier de sortie doit avoir l'extension .md.")
		return
	if FileAccess.file_exists(output) and not force:
		_fail("Le fichier existe déjà : %s. Choisir un autre chemin ou ajouter --force pour le remplacer." % output)
		return
	var fonts := FontRegistry.create_all()
	var palettes := ColorPaletteRegistry.create_all()
	var challenges := ChallengeRegistry.create_all()
	var achievements := AchievementRegistry.create_all()
	var entries: Array[Dictionary] = []
	for data in fonts:
		entries.append(_entry("Police", data, data.display_name, data.default_unlocked,
			data.required_achievement.id if data.required_achievement != null else &""))
	for data in palettes:
		entries.append(_entry("Palette", data, data.display_name, data.default_unlocked,
			data.required_achievement.id if data.required_achievement != null else &""))
	for data in challenges:
		entries.append(_entry("Challenge", data, data.title,
			data.required_achievement_id().is_empty(), data.required_achievement_id()))
	var active_achievements: Dictionary = {}
	for data in achievements:
		active_achievements[data.id] = data
	var default_count := 0
	for entry in entries:
		if entry.default_unlocked:
			default_count += 1
	var lines := PackedStringArray([
		"# Déblocages et achievements actifs", "",
		"Document généré depuis les listes `enabled_data` des catalogues actifs, trié par difficulté croissante au sein de chaque catégorie.",
		"Difficulté interne : 1–2 initiation, 3–4 accessible, 5–6 confirmé, 7–8 expert, 9 maîtrise, 10 collection complète. Les récompenses par défaut précèdent les autres ; les égalités sont départagées par ID.",
		"Les éléments désactivés sont exclus. Les sauvegardes et les déblocages de debug sont ignorés.", "",
		"## Comptes", "",
		"| Type | Nombre actif |", "| --- | ---: |",
		"| Polices | %d |" % fonts.size(),
		"| Palettes | %d |" % palettes.size(),
		"| Challenges | %d |" % challenges.size(),
		"| **Déblocables, toutes catégories confondues** | **%d** |" % entries.size(),
		"| Dont disponibles par défaut | %d |" % default_count,
		"| Dont verrouillés par défaut | %d |" % (entries.size() - default_count),
		"| **Achievements** | **%d** |" % achievements.size(),
		"| Total déblocables + achievements | %d |" % (entries.size() + achievements.size()), "",
		"## Comment choisir", "",
		"- Modifier les cases « Débloqué par défaut » et les lignes « Achievement requis » ci-dessous pour préparer les choix.",
		"- Utiliser les IDs de la liste des achievements actifs. `Aucun` signifie aucune condition configurée.",
		"- Pour une police ou une palette, la case correspond à `default_unlocked`. Sans cette case ni achievement, l'élément reste verrouillé.",
		"- Pour un challenge, l'absence d'achievement requis le rend disponible par défaut : ces deux choix sont liés.",
		"- Les comptes et récompenses ci-dessous décrivent l'export initial ; modifier ce Markdown ne modifie pas automatiquement le jeu ni les totaux.",
		"- Le champ historique `reward_font` d'un achievement n'est pas utilisé pour déterminer les déblocages ; les liens viennent des ressources à débloquer.", "",
	])
	for category in ["Police", "Palette", "Challenge"]:
		lines.append("## %s" % {"Police": "Polices", "Palette": "Palettes", "Challenge": "Challenges"}[category])
		lines.append("")
		for entry in entries:
			if entry.category != category:
				continue
			lines.append("### %s — `%s`" % [_escape(entry.title), entry.id])
			lines.append("")
			lines.append("- [%s] Débloqué par défaut" % ("x" if entry.default_unlocked else " "))
			var requirement := "Aucun" if entry.required.is_empty() else "`%s`" % entry.required
			if not entry.required.is_empty() and not active_achievements.has(entry.required):
				requirement += " — **achievement absent du catalogue actif**"
			lines.append("- Achievement requis : %s" % requirement)
			lines.append("- Difficulté de déblocage : %d / 10 (0 = disponible par défaut)." % entry.difficulty)
			lines.append("- Ressource : `%s`" % entry.path)
			lines.append("- Notes / décision :")
			lines.append("")
	lines.append("## Achievements actifs")
	lines.append("")
	for data in achievements:
		lines.append("### %s — `%s`" % [_escape(data.title), data.id])
		lines.append("")
		lines.append("- Condition : %s" % _escape(data.description))
		lines.append("- Catégorie : %s" % _escape(str(data.category)))
		lines.append("- Difficulté interne : %d / 10" % data.difficulty)
		lines.append("- Masqué avant obtention : %s" % ("Oui" if data.hidden else "Non"))
		lines.append("- Seuil configuré : %d ; limite de temps : %s s (0 = sans contrainte)." % [
			data.required_count, str(data.time_limit_seconds)])
		var rewards := PackedStringArray()
		for entry in entries:
			if entry.required == data.id:
				rewards.append("%s `%s`%s" % [entry.category, entry.id,
					" (déjà disponible par défaut)" if entry.default_unlocked else ""])
		lines.append("- Déblocables liés actuellement : %s" % (
			"Aucun" if rewards.is_empty() else ", ".join(rewards)))
		lines.append("- Ressource : `%s`" % data.resource_path)
		lines.append("- Logique de l'association : %s" % _escape(data.reward_rationale))
		lines.append("")
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		_fail("Impossible d'écrire %s : %s" % [output, error_string(FileAccess.get_open_error())])
		return
	file.store_string("\n".join(lines))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		_fail("Échec de l'export : %s" % error_string(write_error))
		return
	print("Export : %s" % ProjectSettings.globalize_path(output))
	print("%d déblocables (%d polices, %d palettes, %d challenges), %d achievements." % [
		entries.size(), fonts.size(), palettes.size(), challenges.size(), achievements.size()])
	quit()


func _entry(category: String, data: Data, title: String, unlocked: bool, required: StringName) -> Dictionary:
	return {"category": category, "id": data.id, "title": title,
		"default_unlocked": unlocked, "required": required, "path": data.resource_path,
		"difficulty": ProgressionOrdering.unlock_difficulty(data)}


func _escape(value: String) -> String:
	return value.replace("&", "&amp;").replace("<", "&lt;").replace(
		">", "&gt;").replace("\\", "\\\\").replace("*", "\\*").replace(
		"_", "\\_").replace("[", "\\[").replace(
		"]", "\\]").replace("`", "\\`").replace("\r", "").replace("\n", "<br>")


func _fail(message: String) -> void:
	printerr(message)
	quit(1)
