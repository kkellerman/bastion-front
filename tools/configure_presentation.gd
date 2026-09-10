extends SceneTree
func _initialize() -> void:
	for id: String in ["m1911", "p38", "thompson", "mp40", "stg44", "bazooka", "panzerfaust", "mg42", "m1919"]:
		var path: String = "res://resources/weapons/" + id + ".tres"
		var data: WeaponData = load(path) as WeaponData
		data.muzzle_audio = load("res://assets/audio/designed/" + id + ".res")
		data.reload_audio = load("res://assets/audio/designed/reload.res")
		data.dry_audio = load("res://assets/audio/designed/dry.res")
		ResourceSaver.save(data, path)
	var faction: FactionData = load("res://resources/factions/german.tres") as FactionData
	faction.uniform_scene = load("res://assets/characters/german/infantry_field_uniform.tscn")
	faction.voice_set = load("res://resources/characters/german_voice.tres")
	ResourceSaver.save(faction, "res://resources/factions/german.tres")
	quit()
