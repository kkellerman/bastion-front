extends SceneTree
var failures: int = 0
var hostile_cues: int = 0
var hostile_noise: int = 0
var playbacks: int = 0
var last_playback: AudioStreamPlayer3D

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var settings: Node = root.get_node("PlayerSettings")
	var saved: Dictionary = settings.values.duplicate(true)
	settings.values.graphics_preset = 0
	settings.values.distant_combat = false
	root.get_node("PrototypeSession").checkpoint.clear()
	var mission: Node3D = load("res://scenes/missions/forest_command_post.tscn").instantiate()
	root.add_child(mission)
	current_scene = mission
	await _frames(10)
	var viewport_rect: Rect2 = root.get_visible_rect()
	var subtitle: Label = mission.get_node("Presentation").subtitle
	_check(viewport_rect.encloses(subtitle.get_global_rect()),"Subtitle rectangle is visible inside the viewport")
	settings.toggle()
	await process_frame
	_check(viewport_rect.encloses(settings.panel.get_global_rect()),"F10 settings panel fits inside the viewport")
	settings.toggle()
	_check_navigation(mission.get_node("NavigationRegion3D").navigation_mesh)
	var audio: Node = root.get_node("CombatAudio")
	audio.cue_started.connect(func(cue: StringName, source: CollisionObject3D) -> void:
		if source is InfantryBrain and cue in [&"gunshot", &"mounted"]: hostile_cues += 1)
	audio.noise.connect(func(_point: Vector3, _range: float, source: CollisionObject3D) -> void:
		if source is InfantryBrain: hostile_noise += 1)
	var enemies: Array[Node] = mission.get_node("Enemies").get_children()
	var first: InfantryBrain = enemies[0] as InfantryBrain
	audio.play(&"gunshot",first.global_position,first)
	_check(hostile_cues == 1 and hostile_noise == 1,"Live shooter emits sound and hearing evidence")
	for i: int in range(enemies.size()):
		var enemy: InfantryBrain = enemies[i] as InfantryBrain
		if i == 0: enemy.process_mode = Node.PROCESS_MODE_DISABLED
		elif i == 1: enemy.set_physics_process(false)
		else: enemy.health.take_damage(1000)
		var rounds: int = enemy.combat.weapon.magazine
		enemy.combat.attack(mission.player.global_position + Vector3.UP)
		audio.play(&"gunshot",enemy.global_position,enemy)
		audio.play(&"mounted",enemy.global_position,enemy)
		_check(enemy.combat.weapon.magazine == rounds,"Dead/disabled actor rejects direct attack " + str(i))
	# Simulate a stale scheduled callback after shutdown, through the public combat API.
	create_timer(2.0).timeout.connect(func() -> void:
		first.combat.attack(mission.player.global_position)
		audio.play(&"gunshot",first.global_position,first))
	var mount: MountedWeapon = mission.get_node("DefensiveMG")
	var mounted_rounds: int = mount.weapon.magazine
	mount.fire(mount.pivot, first)
	_check(mount.weapon.magazine == mounted_rounds,"Mounted fire rejects a disabled shooter")
	await create_timer(21.0).timeout
	_check(hostile_cues == 1 and hostile_noise == 1,"No hostile sound/noise after all actors stop; waited beyond 19s ambience interval")
	_check(get_nodes_in_group(&"combat_audio_voices").is_empty(),"Local one-shot tails and stale attack sounds are fully retired")
	_check(get_nodes_in_group(&"distant_combat_audio").is_empty(),"Distant combat is off by default")
	if AudioServer.get_driver_name() != "Dummy":
		_check(mission.get_node("Soundscape").wind.playing,"Wind remains audible after enemies stop")
		settings.values.distant_combat = true
		settings.apply()
		mission.get_node("Soundscape")._distant_time = 0
		await _frames(2)
		var distant: Array[Node] = get_nodes_in_group(&"distant_combat_audio")
		_check(distant.size() == 1 and distant[0].bus == &"DistantCombat" and distant[0].global_position.distance_to(mission.player.global_position) > 200,"Optional ambience uses a separate off-map low-pass channel")
		settings.values.distant_combat = false
		settings.apply()
		_check(AudioServer.is_bus_mute(AudioServer.get_bus_index("DistantCombat")),"Ambience can be disabled independently")
	await _voices(mission,settings)
	_check(GraphicsProfile.recommend({"renderer":"forward_plus","type":RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU}) == 1,"Integrated capability selects Medium-Low")
	_check(GraphicsProfile.recommend({"renderer":"forward_plus","type":RenderingDevice.DEVICE_TYPE_DISCRETE_GPU}) == 2,"Discrete capability selects Medium")
	_check(GraphicsProfile.recommend({"renderer":"gl_compatibility","type":RenderingDevice.DEVICE_TYPE_DISCRETE_GPU}) == 0,"Fallback renderer selects Low")
	var low: Dictionary = GraphicsProfile.PRESETS[0]
	var medium_low: Dictionary = GraphicsProfile.PRESETS[1]
	var medium: Dictionary = GraphicsProfile.PRESETS[2]
	_check(low.scale < medium_low.scale and medium_low.scale < medium.scale,"Medium-Low render scale sits between Low and Medium")
	_check(low.density < medium_low.density and medium_low.density < medium.density,"Medium-Low vegetation load sits between Low and Medium")
	_check(not medium_low.ssao and medium.ssao and medium_low.shadow_size < medium.shadow_size,"Medium-Low omits costly Medium lighting features")
	_check(settings.quality.item_count == GraphicsProfile.PRESETS.size() + 1 and settings.quality.get_item_text(2) == "Graphics: Medium-Low","Settings menu exposes Medium-Low in quality order")
	for choice: int in [1,2,3,4,0]:
		settings.values.graphics_preset = choice
		settings.apply()
		var p: Dictionary = GraphicsProfile.PRESETS[settings.applied_preset]
		_check(is_equal_approx(root.scaling_3d_scale,p.scale),"Resolution scale applied " + p.name)
		_check(mission.get_node("Environment/Sun").directional_shadow_max_distance == p.shadow_distance,"Shadow range applied " + p.name)
		var vegetation: MultiMeshInstance3D = get_first_node_in_group(&"quality_vegetation")
		_check(vegetation.multimesh.visible_instance_count == int(vegetation.multimesh.instance_count*float(p.density)),"Vegetation density applied " + p.name)
		var env: Environment = mission.get_node("Environment/Environment").environment
		_check(env.volumetric_fog_enabled == p.fog and env.ssao_enabled == p.ssao and env.ssil_enabled == p.ssil and env.ssr_enabled == p.reflections,"Environment features applied " + p.name)
		_check(int(root.msaa_3d) == p.msaa and (root.screen_space_aa == Viewport.SCREEN_SPACE_AA_FXAA) == p.fxaa and is_equal_approx(root.texture_mipmap_bias,p.mip_bias),"Antialiasing and texture sampling applied " + p.name)
	settings.values.graphics_preset = 3
	settings.save()
	var config: ConfigFile = ConfigFile.new()
	config.load("user://settings.cfg")
	_check(config.get_value("settings","graphics_preset") == 3,"Manual Medium override persists on disk")
	settings.auto_detect()
	_check(settings.values.graphics_preset == 0,"Auto-detect resets manual choice explicitly")
	settings.values = saved
	settings.save()
	mission.queue_free()
	await _frames(20)
	_check(get_nodes_in_group(&"dialogue_audio").is_empty() and get_nodes_in_group(&"combat_audio_voices").is_empty(),"Scene teardown retires audio ownership")
	print("Polish smoke: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)

func _voices(mission: Node3D, settings: Node) -> void:
	var director: Node = mission.get_node("Presentation/DialogueDirector")
	director.playback_started.connect(func(_language: StringName,_category: StringName,player: AudioStreamPlayer3D) -> void:
		playbacks += 1
		last_playback = player)
	settings.values.voice_diagnostics = true
	settings.values.dialogue = 1.0
	settings.apply()
	var capture: AudioEffectCapture = AudioEffectCapture.new()
	var bus: int = AudioServer.get_bus_index("Dialogue")
	AudioServer.add_bus_effect(bus,capture)
	for faction: String in ["allied","german"]:
		var data: FactionData = load("res://resources/factions/" + faction + ".tres")
		var voice: Node3D = load("res://scripts/presentation/infantry_voice.gd").new()
		voice.voice_set = data.voice_set
		voice.director = director
		mission.player.add_child(voice)
		_check(voice.voice_set.language == data.spoken_language,"Faction routes correct language " + faction)
		for event: StringName in [&"spotting",&"taking_fire",&"reloading",&"moving",&"lost_sight",&"grenade_warning",&"casualty",&"death"]:
			director.remaining = 0
			director.categories.clear()
			voice._cooldown = 0
			voice._categories.clear()
			_check(voice.say(event),"Event accepted " + faction + "/" + event)
			if AudioServer.get_driver_name() != "Dummy":
				_check(last_playback.playing and last_playback.get_meta(&"language") == data.spoken_language and last_playback.bus == &"Dialogue","Spatial diagnostic playback uses faction and Dialogue bus")
				await create_timer(0.12).timeout
				var frames: PackedVector2Array = capture.get_buffer(capture.get_frames_available())
				var peak: float = 0.0
				for sample: Vector2 in frames: peak = maxf(peak,sample.length())
				_check(peak > 0.00001,"Native audio mixer receives nonzero diagnostic samples")
			_check(not voice.say(event),"Cooldown/death prevents repeated event")
			for player: Node in get_nodes_in_group(&"dialogue_audio"):
				player.stop()
				player.queue_free()
			await _frames(2)
		_check(not voice.say(&"reloading"),"Dead actor cannot speak queued combat lines")
		voice.queue_free()
	# Supply a real AudioStream resource in the production slot with diagnostics OFF.
	# Its content is still explicitly a test tone; this verifies the asset path, not speech.
	settings.values.voice_diagnostics = false
	var supplied: Node3D = load("res://scripts/presentation/infantry_voice.gd").new()
	supplied.voice_set = load("res://resources/characters/german_voice.tres").duplicate(true)
	supplied.voice_set.recordings[&"reloading"] = supplied.voice_set.diagnostic_clip()
	supplied.director = director
	mission.player.add_child(supplied)
	mission.player.position = Vector3(0,0,-65)
	director.remaining = 0
	director.categories.clear()
	_check(supplied.say(&"reloading"),"Supplied recording plays without diagnostic fallback")
	if AudioServer.get_driver_name() != "Dummy":
		_check(last_playback.bus == &"DialogueInterior" and not last_playback.get_meta(&"diagnostic"),"Supplied interior clip routes through reverb into Dialogue")
	_check(not supplied.say(&"spotting"),"Global/actor cooldown blocks overlapping supplied recording")
	# Death must interrupt reload immediately even while both cooldowns are active.
	_check(supplied.say(&"death"),"Death event bypasses combat cooldown and retires interrupted line")
	supplied.queue_free()
	AudioServer.remove_bus_effect(bus,AudioServer.get_bus_effect_count(bus)-1)

func _frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func _check_navigation(mesh: NavigationMesh) -> void:
	var vertices: PackedVector3Array = mesh.vertices
	var counts: Dictionary[String, int] = {}
	for index: int in range(mesh.get_polygon_count()):
		var polygon: PackedInt32Array = mesh.get_polygon(index)
		for corner: int in range(polygon.size()):
			var a: String = str(vertices[polygon[corner]].snapped(Vector3.ONE*0.0001))
			var b: String = str(vertices[polygon[(corner+1)%polygon.size()]].snapped(Vector3.ONE*0.0001))
			var key: String = a+b if a < b else b+a
			counts[key] = counts.get(key,0)+1
	var manifold: bool = true
	for count: int in counts.values():
		if count > 2: manifold = false
	_check(manifold,"Baked terrain navigation has no non-manifold shared edges")

func _check(condition: bool,message: String) -> void:
	if condition: print("PASS: ",message)
	else:
		failures += 1
		push_error("FAIL: " + message)
