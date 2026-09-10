extends SceneTree

func _initialize() -> void:
	var keys: Array[StringName] = [&"spotting", &"taking_fire", &"reloading", &"moving", &"lost_sight", &"grenade_warning", &"casualty", &"death", &"briefing"]
	var english: Array[String] = ["Contact ahead!", "Taking fire!", "Reloading!", "Moving up. Watch the treeline.", "Lost sight of him. Search the area.", "Grenade! Get down!", "Man down!", "I'm hit!", "Command to patrol: follow the forest track. Take the command post, recover the documents, then leave by the rear exit. The eastern supply track offers another approach."]
	var german: Array[String] = ["Feind gesichtet!", "Wir werden beschossen!", "Ich lade nach!", "Ich rücke vor. Waldrand beobachten!", "Sichtkontakt verloren. Sucht die Umgebung ab!", "Granate! In Deckung!", "Mann ausgefallen!", "Ich bin getroffen!", "Führung an Streife: Folgt dem Waldweg. Sichert den Gefechtsstand und die Unterlagen. Rückzug durch den hinteren Ausgang. Der Versorgungsweg im Osten bietet einen zweiten Zugang."]
	for id: String in ["allied", "german"]:
		var voice: InfantryVoiceSet = InfantryVoiceSet.new()
		voice.language = &"en" if id == "allied" else &"de"
		for i: int in range(keys.size()):
			voice.subtitles[keys[i]] = english[i] if id == "allied" else german[i]
			voice.subtitle_keys[keys[i]] = StringName(id.to_upper() + "_" + str(keys[i]).to_upper())
			voice.durations[keys[i]] = 11.0 if keys[i] == &"briefing" else 3.0
		ResourceSaver.save(voice, "res://resources/characters/" + id + "_voice.tres")
		var faction: FactionData = load("res://resources/factions/" + id + ".tres")
		faction.voice_set = load("res://resources/characters/" + id + "_voice.tres")
		ResourceSaver.save(faction, faction.resource_path)
	for id: String in ["m1911", "p38", "thompson", "mp40", "stg44", "bazooka", "panzerfaust"]:
		var data: WeaponData = load("res://resources/weapons/" + id + ".tres")
		data.support_hand_position = Vector3(-0.034, -0.085, 0.07) if data.weapon_class == &"pistol" else Vector3(-0.025, -0.05, -0.24)
		ResourceSaver.save(data, data.resource_path)
	print("Configured faction voices and seven viewmodel hand poses")
	quit()
