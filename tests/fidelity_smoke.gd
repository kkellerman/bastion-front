extends SceneTree
var failures: int = 0
var lines: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.get_node("PrototypeSession").checkpoint.clear()
	var mission: Node3D = load("res://scenes/missions/forest_command_post.tscn").instantiate()
	root.add_child(mission)
	current_scene = mission
	await _frames(10)
	for enemy: InfantryBrain in mission.get_node("Enemies").get_children(): enemy.set_physics_process(false)
	mission.player.set_physics_process(false)
	mission.get_node("DefensiveMG").set_physics_process(false)
	for id: String in ["allied", "german"]:
		var faction: FactionData = load("res://resources/factions/" + id + ".tres")
		var model: Node3D = faction.uniform_scene.instantiate()
		mission.add_child(model)
		var skeleton: Skeleton3D = model.get_node("Skeleton3D")
		_check(skeleton.get_bone_count() == 17, id + " shares 17-bone gameplay skeleton")
		_check(model.get_node("UniformAndBody").skin.get_bind_count() == 17, id + " mesh has skin bindings")
		var mesh: Mesh = model.get_node("UniformAndBody").mesh
		var arrays: Array = mesh.surface_get_arrays(0)
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var normalized: bool = true
		for vertex: int in range(arrays[Mesh.ARRAY_VERTEX].size()):
			var sum: float = 0
			for slot: int in range(4): sum += weights[vertex * 4 + slot]
			if absf(sum - 1.0) > 0.002: normalized = false
		_check(normalized, id + " retargeted skin weights are normalized")
		_check(model.has_node("Skeleton3D/WeaponSocket") and model.has_node("AnimationTree"), id + " attachment and AnimationTree hooks")
		var animations: AnimationPlayer = model.get_node("AnimationPlayer")
		for clip: String in ["idle", "walk", "run", "aim", "fire", "reload", "hurt", "death", "switch"]:
			_check(animations.has_animation(clip), id + " animation " + clip)
		animations.play("walk")
		animations.advance(0.2)
		_check(absf(skeleton.get_bone_pose_rotation(skeleton.find_bone("LeftThigh")).x) > 0.05, "Walk animates bound thigh")
		_check(faction.voice_set.language == faction.spoken_language, id + " selects correct spoken language")
		model.queue_free()
	var env: Environment = mission.get_node("Environment/Environment").environment
	_check(env.sky.sky_material is ShaderMaterial, "Authored cloud sky installed")
	_check(ResourceLoader.exists("res://assets/environments/germany/forest/tree_2_foliage_lod.res"), "Distant tree tier available")
	var flank_path: PackedVector3Array = NavigationServer3D.map_get_path(mission.player.get_world_3d().navigation_map, Vector3(12, 0, -20), Vector3(12, 0, -48), true)
	_check(flank_path.size() >= 2 and flank_path[-1].distance_to(Vector3(12, 0, -48)) < 1.0, "Optional supply flank connects along east side")
	var enemy: InfantryBrain = mission.get_node("Enemies/ForestPatrol")
	var voice: Node3D = enemy.get_node("CombatVoice")
	var director: Node = mission.get_node("Presentation/DialogueDirector")
	mission.player.position = enemy.position + Vector3(0, 0, 4)
	director.remaining = 0
	director.categories.clear()
	director.line_started.connect(func(_text: String, _duration: float) -> void: lines += 1)
	_check(voice.say(&"spotting"), "Nearby event triggers subtitle with silent recording")
	_check(not voice.say(&"spotting") and lines == 1, "Actor cooldown prevents duplicate line")
	voice._cooldown = 0
	_check(not voice.say(&"taking_fire"), "Global timing prevents overlapping lines")
	director.remaining = 0
	_check(not voice.say(&"spotting"), "Category cooldown remains after global cooldown")
	voice._categories.clear()
	director.categories.clear()
	_check(voice.say(&"taking_fire"), "Different event plays after cooldown")
	var remembered: Vector3 = Vector3(6, 0, -22)
	enemy.sees_target = false
	enemy._set_state(InfantryBrain.State.IDLE)
	enemy.receive_alert(remembered)
	_check(enemy.state == InfantryBrain.State.ALERT and enemy.last_known_position == remembered, "Shared alert stores reported point")
	var ally: InfantryBrain = mission.get_node("Enemies/RoadGuard")
	ally.position = enemy.position + Vector3(2, 0, 0)
	ally.sees_target = false
	ally._set_state(InfantryBrain.State.IDLE)
	enemy.sees_target = true
	enemy.tactics._broadcast = 0
	enemy.tactics.tick(0.1)
	_check(ally.last_known_position == remembered and ally.state == InfantryBrain.State.ALERT, "Visible contact broadcasts a position to nearby friendly infantry")
	enemy.sees_target = false
	mission.player.position = Vector3(22, 0, 20)
	enemy._set_state(InfantryBrain.State.CHASE)
	enemy._memory_remaining = 0
	enemy.tactics.tick(0.1)
	_check(enemy.tactics.order == &"search" and enemy.last_known_position == remembered, "Search uses remembered evidence, not hidden player")
	var rounds: int = enemy.combat.weapon.magazine
	for i: int in range(6): enemy.tactics.tick(1.0)
	_check(enemy.state == InfantryBrain.State.IDLE and enemy.combat.weapon.magazine == rounds, "Search expires without firing")
	_check(get_nodes_in_group(&"infantry_cover").size() == 6, "Encounter has authored cover points")
	# Construct known cover to test selection rather than relying on random combat positions.
	var wall: StaticBody3D = StaticBody3D.new()
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(4, 1.2, 0.3)
	collision.shape = shape
	wall.add_child(collision)
	mission.add_child(wall)
	wall.position = Vector3(0, 0.6, 4)
	var cover: Marker3D = Marker3D.new()
	mission.add_child(cover)
	cover.position = Vector3(0, 0, 5)
	cover.add_to_group(&"infantry_cover")
	enemy.position = Vector3(1, 0, 6)
	enemy.last_known_position = Vector3(0, 0, -5)
	await _frames(3)
	enemy.tactics._choose_cover()
	_check(enemy.tactics._cover == cover, "Cover selection requires a real occluding surface")
	wall.queue_free()
	cover.queue_free()
	var checkpoint: Node = mission.get_node("Checkpoints")
	mission.player.position = Vector3(0, 0.05, -56)
	mission.rig.weapon.magazine = 3
	enemy.health.take_damage(1000)
	checkpoint.capture(1)
	mission.player.position = Vector3(0, 0, 18)
	mission.rig.weapon.magazine = 7
	checkpoint._restore()
	_check(mission.player.position.z == -56 and mission.rig.weapon.magazine == 3, "Checkpoint restores position and individual magazine")
	mission.objective_done = true
	checkpoint.capture(2)
	mission.objective_done = false
	checkpoint._restore()
	_check(mission.objective_done and checkpoint.stage == 2, "Document checkpoint preserves objective")
	var saved: Dictionary = root.get_node("PrototypeSession").checkpoint.duplicate(true)
	mission.player.get_node("HealthComponent").take_damage(1000)
	var restart: InputEventKey = InputEventKey.new()
	restart.physical_keycode = KEY_ENTER
	restart.pressed = true
	Input.parse_input_event(restart)
	await _frames(15)
	mission = current_scene as Node3D
	_check(mission.objective_done and mission.player.position.distance_to(saved.position) < 0.3 and mission.rig.weapon.magazine == 3, "Death and Enter load the saved mission checkpoint")
	var settings: Node = root.get_node("PlayerSettings")
	settings.values.fov = 90.0
	settings.apply()
	_check(mission.rig._base_fov == 90.0, "FOV option reaches weapon aiming controller")
	settings.values.fov = 78.0
	settings.apply()
	settings.toggle()
	_check(paused and settings.panel.visible and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "F10 options pause gameplay and release the pointer")
	settings.toggle()
	_check(not paused and not settings.panel.visible, "Closing options resumes gameplay")
	_check(FileAccess.file_exists("user://settings.cfg"), "Options persist to the user configuration")
	for slot: int in range(mission.rig.inventory.weapons.size()):
		mission.rig.inventory.select(slot)
		await _frames(2)
		_check(mission.rig.viewmodel.has_node("Arms"), "Selected weapon installs faction hands")
	mission.rig.inventory.configure(load("res://resources/factions/german.tres"))
	for slot: int in range(mission.rig.inventory.weapons.size()):
		mission.rig.inventory.select(slot)
		await _frames(2)
		_check(mission.rig.viewmodel.has_node("Arms"), "German slot installs configured support-hand pose")
	root.get_node("PrototypeSession").checkpoint.clear()
	print("Fidelity smoke: %d failure(s)" % failures)
	mission.queue_free()
	await _frames(20)
	quit(0 if failures == 0 else 1)

func _frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func _check(condition: bool, message: String) -> void:
	if condition: print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
