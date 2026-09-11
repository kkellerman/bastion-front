extends SceneTree
var failures: int = 0

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var mission: Node3D = load("res://scenes/missions/forest_command_post.tscn").instantiate()
	root.add_child(mission)
	current_scene = mission
	await _frames(10)
	for enemy: InfantryBrain in mission.get_node("Enemies").get_children(): enemy.health.take_damage(1000)
	await _frames(3)
	var player: FirstPersonPlayer = mission.player
	var camera: Camera3D = player.get_node("Head/Camera3D")
	var rig: Node3D = mission.rig
	for name: String in ["RangeM1919", "RangeMG42", "DefensiveMG"]:
		var gun: MountedWeapon = mission.get_node(name)
		player.position = gun.position + Vector3(0, 0.05, 1.7)
		var rest: Vector3 = camera.position
		gun.interact(player)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_mouse(MOUSE_BUTTON_RIGHT, true)
		await _frames(30)
		_check(rig._aiming and camera.fov < 58, name + " right mouse zooms")
		_check(camera.global_position.distance_to(gun.pivot.to_global(gun.aim_eye_position)) < 0.04, name + " viewpoint aligns behind sights")
		player.rotation.y = gun.rotation.y + 0.2
		player.get_node("Head").rotation.x = 0.1
		await _frames(3)
		_check(absf(gun.pivot.rotation.y - 0.2) < 0.01 and absf(gun.pivot.rotation.x - 0.1) < 0.01, name + " aiming retains yaw/pitch traverse")
		var rounds: int = gun.weapon.magazine
		_mouse(MOUSE_BUTTON_LEFT, true)
		await _frames(3)
		_mouse(MOUSE_BUTTON_LEFT, false)
		_check(gun.weapon.magazine < rounds, name + " fires while aimed")
		_mouse(MOUSE_BUTTON_RIGHT, false)
		await _frames(30)
		_check(not rig._aiming and absf(camera.fov - rig._base_fov) < 0.1 and camera.position.distance_to(rest) < 0.001, name + " releasing aim restores view")
		_mouse(MOUSE_BUTTON_RIGHT, true)
		await _frames(20)
		gun.dismount()
		_check(camera.position.distance_to(rest) < 0.001 and camera.fov == rig._base_fov and not rig._aiming, name + " dismount clears aim and restores camera")
		_mouse(MOUSE_BUTTON_RIGHT, false)
	var shot: AudioStreamWAV = load("res://assets/audio/designed/m1911.res")
	for surface: String in ["dirt", "wood", "concrete", "metal"]:
		var step: AudioStreamWAV = load("res://assets/audio/designed/footstep_" + surface + ".res")
		_check(_rms(step) < _rms(shot) * 0.3, surface + " footsteps have much lower energy than gunshots")
		var attack_peak: int = 0
		for i: int in range(220): attack_peak = maxi(attack_peak, absi(step.data.decode_s16(i * 2)))
		_check(attack_peak < 600, surface + " footsteps have no sharp opening crack")
		root.get_node("CombatAudio").play(StringName("footstep_" + surface), player.position, player)
		if AudioServer.get_driver_name() != "Dummy":
			var voices: Array[Node] = get_nodes_in_group(&"combat_audio_voices")
			var voice: AudioStreamPlayer3D = voices[-1]
			_check(voice.volume_db == -30 and voice.max_distance == 12, surface + " quiet local playback settings")
	print("Footsteps/mounted aim smoke: %d failure(s)" % failures)
	mission.queue_free()
	await _frames(5)
	quit(0 if failures == 0 else 1)

func _rms(wav: AudioStreamWAV) -> float:
	var sum: float = 0
	var count: int = wav.data.size() / 2
	for i: int in range(count):
		var sample: float = wav.data.decode_s16(i * 2) / 32768.0
		sum += sample * sample
	return sqrt(sum / count)

func _mouse(button: MouseButton, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)

func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame

func _check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1
