extends Node
const Voice = preload("res://scripts/presentation/infantry_voice.gd")
const P = preload("res://scripts/presentation/dressing_parts.gd")
var subtitle: Label
var _remaining: float = 0.0

func _ready() -> void:
	_install.call_deferred()

func _install() -> void:
	var mission: Node = get_parent()
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	subtitle = Label.new()
	canvas.add_child(subtitle)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	subtitle.position = Vector2(-320, -170)
	subtitle.size = Vector2(640, 40)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_constant_override("outline_size", 5)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for enemy: InfantryBrain in mission.get_node("Enemies").get_children():
		enemy.get_node("Status").visible = false
		var faction: FactionData = enemy.get_meta(&"faction") as FactionData
		var preview: Node3D = enemy.combat.weapon.data.viewmodel_scene.instantiate() as Node3D
		var held: Node3D = preview.get_node("WeaponMesh").duplicate() as Node3D
		preview.free()
		enemy.get_node("Eyes/Gun").mesh = null
		enemy.get_node("Eyes/Gun").add_child(held)
		if faction.uniform_scene != null:
			var old: Node3D = enemy.get_node("Visuals") as Node3D
			old.visible = false
			var model: Node3D = faction.uniform_scene.instantiate() as Node3D
			old.add_child(model)
			for child: Node3D in old.get_children():
				child.visible = child == model
			old.visible = true
		if faction.voice_set != null:
			var voice: Node3D = Voice.new()
			voice.voice_set = faction.voice_set
			enemy.add_child(voice)
			enemy.state_changed.connect(voice.state_changed)
			enemy.combat.weapon.reload_changed.connect(func(active: bool) -> void:
				if active: voice.say(&"reloading"))
			voice.subtitle_requested.connect(_subtitle)
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

func _subtitle(words: String) -> void:
	subtitle.text = words
	_remaining = 3.0

func _process(delta: float) -> void:
	_remaining = maxf(0, _remaining - delta)
	if subtitle != null and _remaining <= 0: subtitle.text = ""
