extends SceneTree
## Kill every actual actor, then traverse with player input/collision (no teleport).
var failures: int = 0
var player: FirstPersonPlayer
var mission: Node3D
var shots: int = 0
var subtitles: int = 0
var noises: int = 0
var flashes: int = 0

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.get_node("PrototypeSession").checkpoint.clear()
	mission = load("res://scenes/missions/forest_command_post.tscn").instantiate()
	root.add_child(mission)
	current_scene = mission
	await _frames(15)
	player = mission.player
	var audio: Node = root.get_node("CombatAudio")
	audio.cue_started.connect(func(cue: StringName, source: CollisionObject3D) -> void:
		if source is InfantryBrain and cue in [&"gunshot", &"mounted"]: shots += 1)
	audio.noise.connect(func(_point: Vector3, _radius: float, source: CollisionObject3D) -> void:
		if source is InfantryBrain: noises += 1)
	mission.get_node("Presentation/DialogueDirector").actor_line_started.connect(func(actor: Node3D, _category: StringName) -> void:
		if actor is InfantryBrain: subtitles += 1)
	for enemy: InfantryBrain in mission.get_node("Enemies").get_children():
		enemy.get_node("CombatVoice").queue_line(&"casualty")
		enemy.health.take_damage(1000)
		_check(enemy.health.current_health == 0 and enemy.state == InfantryBrain.State.DEATH, str(enemy.name) + " is killed, not merely hidden/disabled")
	await _frames(5)
	var settings: Node = root.get_node("PlayerSettings")
	settings.values.distant_combat = true
	settings.apply()
	var visits: Dictionary[String, Vector3] = {
		"entrance": Vector3(0, 0, -56),
		"radio_room": Vector3(4, 0, -65),
		"operations": Vector3(-5, 0, -72.5),
		"rear_corridor": Vector3(0, 0, -77),
		"radio_return": Vector3(4, 0, -65),
		"exterior_return": Vector3(0, 0, -56)}
	for place: String in visits:
		_check(await _walk(visits[place]), "Physically walked to " + place)
		# Look around at each stop while checking events, rather than only crossing triggers.
		for frame: int in range(120):
			player.rotation.y += TAU / 120
			await _frames(1)
		_check(shots == 0 and subtitles == 0 and noises == 0 and flashes == 0, "No hostile events at " + place)
		if place in ["radio_room", "operations"]:
			var aim: Vector3 = Vector3(6, 1.3, -64) if place == "radio_room" else Vector3(-6, 1.6, -79)
			var offset: Vector3 = aim - player.get_node("Head/Camera3D").global_position
			player.rotation.y = atan2(-offset.x, -offset.z)
			player.get_node("Head").rotation.x = atan2(offset.y, Vector2(offset.x, offset.z).length())
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/screenshots/cleared_" + place + ".png")
	await create_timer(26).timeout
	_check(shots == 0 and subtitles == 0 and noises == 0 and flashes == 0, "No hostile events after walk plus another 26 seconds")
	var emitters: int = 0
	for voice: Node in get_nodes_in_group(&"combat_audio_voices"):
		if voice.get_meta(&"cue", &"") in [&"gunshot", &"mounted"]: emitters += 1
	_check(emitters == 0, "No active local gunfire emitters remain")
	_check(mission.get_node("Soundscape").radio.playing, "Nonverbal environmental radio remains independent of soldiers")
	print("Cleared command post: shots=%d subtitles=%d noise=%d flashes=%d; %d failure(s)" % [shots, subtitles, noises, flashes, failures])
	mission.queue_free()
	await _frames(5)
	quit(0 if failures == 0 else 1)

func _walk(destination: Vector3) -> bool:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var route: PackedVector3Array = NavigationServer3D.map_get_path(player.get_world_3d().navigation_map, player.global_position, destination, true)
	if route.is_empty(): return false
	player.get_node("Head").rotation = Vector3.ZERO
	Input.action_press("sprint")
	for waypoint: Vector3 in route:
		var frames: int = 0
		while Vector2(player.position.x - waypoint.x, player.position.z - waypoint.z).length() > 0.25:
			var offset: Vector3 = waypoint - player.position
			Input.action_press("move_forward", clampf(Vector2(offset.x, offset.z).length() / 1.5, 0.35, 1))
			player.rotation.y = atan2(-offset.x, -offset.z)
			await _frames(1)
			frames += 1
			if frames >= 360:
				Input.action_release("move_forward")
				Input.action_release("sprint")
				return false
	Input.action_release("move_forward")
	Input.action_release("sprint")
	return player.position.distance_to(destination) < 1

func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame
		if player != null and is_instance_valid(mission):
			for effect: MuzzleEffect in get_nodes_in_group(&"muzzle_effects"):
				if effect.actor is InfantryBrain and effect.flash.visible: flashes += 1

func _check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1
