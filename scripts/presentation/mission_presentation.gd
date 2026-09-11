extends Node
const Voice = preload("res://scripts/presentation/infantry_voice.gd")
const P = preload("res://scripts/presentation/dressing_parts.gd")
var subtitle: Label
var _remaining: float = 0.0
var dialogue: Node
var _player_health: float = 100.0

func _ready() -> void:
	_install.call_deferred()

func _install() -> void:
	var mission: Node = get_parent()
	dialogue = load("res://scripts/presentation/dialogue_director.gd").new()
	dialogue.name = "DialogueDirector"
	add_child(dialogue)
	dialogue.line_started.connect(_timed_subtitle)
	dialogue.line_cleared.connect(func() -> void:
		if subtitle != null: subtitle.text = "")
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	subtitle = Label.new()
	canvas.add_child(subtitle)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	subtitle.offset_left = -320
	subtitle.offset_right = 320
	subtitle.offset_top = -170
	subtitle.offset_bottom = -85
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_constant_override("outline_size", 5)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for enemy: InfantryBrain in mission.get_node("Enemies").get_children():
		enemy.get_node("Status").visible = false
		var faction: FactionData = enemy.get_meta(&"faction") as FactionData
		var preview: Node3D = enemy.combat.weapon.data.viewmodel_scene.instantiate() as Node3D
		var held: Node3D = preview.get_node("WeaponMesh").duplicate() as Node3D
		var muzzle_transform: Transform3D = preview.get_node("Muzzle").transform
		preview.free()
		enemy.get_node("Eyes/Gun").mesh = null
		enemy.get_node("Eyes/Gun").add_child(held)
		if faction.uniform_scene != null:
			var old: Node3D = enemy.get_node("Visuals") as Node3D
			old.visible = false
			var visual: PackedScene = faction.uniform_scene if faction.visual_variants.is_empty() else faction.visual_variants[enemy.get_index() % faction.visual_variants.size()]
			var model: Node3D = visual.instantiate() as Node3D
			old.add_child(model)
			for child: Node3D in old.get_children():
				child.visible = child == model
			old.visible = true
			var animator: Node = load("res://scripts/presentation/character_animation.gd").new()
			animator.actor = enemy
			animator.model = model
			enemy.add_child(animator)
			held.reparent(model.get_node("Skeleton3D/WeaponSocket"), false)
			held.position = Vector3(0, 0.07, -0.06)
			enemy.combat.muzzle.reparent(held, false)
			enemy.combat.muzzle.transform = muzzle_transform
		if faction.voice_set != null:
			var voice: Node3D = Voice.new()
			voice.voice_set = faction.voice_set
			voice.name = "CombatVoice"
			voice.director = dialogue
			enemy.add_child(voice)
			enemy.state_changed.connect(voice.state_changed)
			enemy.combat.weapon.reload_changed.connect(func(active: bool) -> void:
				if active: voice.say(&"reloading"))
			enemy.health.died.connect(_casualty.bind(enemy))
	for mount: String in ["RangeM1919", "RangeMG42", "DefensiveMG"]:
		mission.get_node(mount + "/Label").visible = false
		mission.get_node(mount).set_meta(&"surface", &"metal")
	mission.get_node("Player/Head/Camera3D/WeaponRig/WeaponHUD/Controls").visible = false
	for point: Node3D in mission.get_node("Interactions").get_children():
		point.get_node("Mesh").visible = false
		point.get_node("Label").visible = false
		P.crate(point, Vector3.ZERO, Vector3(0.8, 1.0, 0.8), load("res://assets/materials/presentation/bark.tres"), P.material(Color(0.1, 0.12, 0.11), 0.6))
		if point.name == &"Documents":
			P.box(point, Vector3(0, 1.015, 0), Vector3(0.5, 0.025, 0.38), P.material(Color(0.67, 0.61, 0.43)))
		else:
			P.sign_text(point, Vector3(0, 0.7, 0.411), "ALLIED" if point.name == &"AlliedStation" else "GERMAN", 0.002)
	for supply: Node3D in mission.get_node("Supplies").get_children():
		for child: Node in supply.get_children():
			if child is MeshInstance3D: child.material_override = load("res://assets/materials/presentation/bark.tres")
	var radio: Node3D = Voice.new()
	radio.voice_set = mission.rig.inventory.faction.voice_set
	radio.name = "PlayerVoice"
	radio.director = dialogue
	mission.player.add_child(radio)
	for weapon: WeaponBase in mission.rig.inventory.weapons:
		weapon.reload_changed.connect(func(active: bool) -> void:
			if active: radio.say(&"reloading"))
	_player_health = mission.player.get_node("HealthComponent").current_health
	mission.player.get_node("HealthComponent").health_changed.connect(func(current: float, _maximum: float) -> void:
		if current > 0 and current < _player_health: radio.say(&"taking_fire")
		_player_health = current)
	mission.player.get_node("HealthComponent").died.connect(func() -> void: radio.say(&"death"))
	if get_node("/root/PrototypeSession").checkpoint.is_empty(): dialogue.request(radio, &"briefing", true)
	get_node("/root/PlayerSettings").apply()
	var audio_debug: CanvasLayer = load("res://scripts/presentation/audio_source_debug.gd").new()
	audio_debug.name = "AudioSourceDebug"
	add_child(audio_debug)

func _casualty(fallen: InfantryBrain) -> void:
	for enemy: InfantryBrain in get_parent().get_node("Enemies").get_children():
		if enemy != fallen and enemy.health.current_health > 0 and enemy.global_position.distance_to(fallen.global_position) < 14:
			var voice: Node = enemy.get_node_or_null("CombatVoice")
			if voice != null: voice.queue_line(&"casualty")

func _timed_subtitle(words: String, duration: float) -> void:
	_subtitle(words)
	_remaining = duration

func _subtitle(words: String) -> void:
	subtitle.text = words
	_remaining = 3.0

func _process(delta: float) -> void:
	_remaining = maxf(0, _remaining - delta)
	if subtitle != null: subtitle.visible = get_node("/root/PlayerSettings").values.subtitles
	if subtitle != null and _remaining <= 0: subtitle.text = ""
