extends Node

signal noise(position: Vector3, radius: float, source: CollisionObject3D)
signal bullet_passed(start: Vector3, end: Vector3, source: CollisionObject3D)
signal cue_started(cue: StringName, source: CollisionObject3D)
var palette: AudioPalette = preload("res://resources/audio/prototype_palette.tres")
var _fallbacks: Dictionary[StringName, AudioStream] = {}
var _voices: int = 0
var interior_bounds: AABB = AABB(Vector3(-9, -1, -80), Vector3(18, 5, 21))

func _ready() -> void:
	if AudioServer.get_bus_index("Bunker") < 0:
		AudioServer.add_bus()
		var index: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, "Bunker")
		var reverb: AudioEffectReverb = AudioEffectReverb.new()
		reverb.room_size = 0.65
		reverb.damping = 0.6
		reverb.wet = 0.28
		AudioServer.add_bus_effect(index, reverb)


func _exit_tree() -> void:
	for child: Node in get_children():
		var voice: AudioStreamPlayer3D = child as AudioStreamPlayer3D
		voice.stop()
		voice.stream = null
	_fallbacks.clear()


func play(cue: StringName, position: Vector3, source: CollisionObject3D = null, override_stream: AudioStream = null) -> void:
	if str(cue).begins_with("footstep") and not can_emit(source): return
	# Validate before both hearing and playback. Explosions already in flight remain valid.
	if cue in [&"gunshot", &"mounted", &"reload", &"dry"] and not can_emit(source):
		return
	if cue == &"gunshot" and source is InfantryBrain and not source.combat.enabled: return
	cue_started.emit(cue, source)
	if cue in [&"gunshot", &"mounted", &"explosion"]:
		noise.emit(position, 45.0 if cue != &"gunshot" else 28.0, source)
	# Dummy has no audible output. Keep simulation noise, without allocating PCM
	# playbacks that its shutdown mixer may leave pending during CLI tests/bakes.
	if AudioServer.get_driver_name() == "Dummy":
		return
	if _voices >= 24:
		return
	var stream: AudioStream = override_stream
	if stream == null and cue == &"footstep": stream = load("res://assets/audio/designed/footstep_dirt.res")
	var designed: String = "res://assets/audio/designed/" + str(cue) + ".res"
	if stream == null and ResourceLoader.exists(designed):
		stream = load(designed) as AudioStream
	if stream == null and cue in [&"gunshot", &"mounted", &"reload", &"dry", &"impact", &"explosion", &"footstep"]:
		stream = palette.get(cue) as AudioStream
	if stream == null:
		if not _fallbacks.has(cue):
			_fallbacks[cue] = _synthesize(cue)
		stream = _fallbacks[cue]
	var voice: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	# World sounds belong to the current scene, so restart cancels old gunfire/tails.
	var scene: Node = get_tree().current_scene
	if scene == null: scene = self
	scene.add_child(voice)
	voice.add_to_group(&"combat_audio_voices")
	voice.set_meta(&"cue", cue)
	voice.set_meta(&"source_id", source.get_instance_id() if is_instance_valid(source) else 0)
	voice.global_position = position
	voice.stream = stream
	voice.bus = &"Bunker" if interior_bounds.has_point(position) else &"Effects"
	voice.volume_db = -10.0
	voice.max_distance = 65.0
	if str(cue).begins_with("footstep"):
		voice.volume_db = -26.0
		voice.max_distance = 12.0
		voice.attenuation_filter_cutoff_hz = 1600.0
	if cue == &"explosion":
		voice.max_distance = 140
		voice.unit_size = 9
	if cue in [&"hit_flesh", &"hit_gear"]:
		voice.volume_db = -15
		voice.max_distance = 24
		voice.unit_size = 4
	if cue == &"mounted":
		# A heavy tripod gun should stay loud and present at combat range, not fade
		# toward a handheld-weapon volume by a few metres out. The default inverse-
		# distance curve dropped it ~16x in amplitude between point-blank and 15 m;
		# logarithmic falloff keeps far more level and top-end out to max_distance.
		voice.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
		voice.unit_size = 22.0
		voice.max_distance = 90.0
	voice.pitch_scale = randf_range(0.94, 1.06)
	_voices += 1
	voice.tree_exiting.connect(func() -> void:
		_voices -= 1
		voice.stop()
		voice.stream = null)
	voice.finished.connect(voice.queue_free)
	voice.play()

func can_emit(source: CollisionObject3D) -> bool:
	if not is_instance_valid(source) or not source.is_inside_tree() or not source.can_process(): return false
	var health: HealthComponent = source.get_node_or_null("HealthComponent") as HealthComponent
	if health != null and health.current_health <= 0: return false
	# Mounted players deliberately suspend their movement physics; infantry never fires suspended.
	if source is InfantryBrain and not source.is_physics_processing(): return false
	return true

func stop_all() -> void:
	for voice: AudioStreamPlayer3D in get_tree().get_nodes_in_group(&"combat_audio_voices"):
		voice.stop()
		voice.stream = null
		voice.queue_free()


func _synthesize(cue: StringName) -> AudioStreamWAV:
	var duration: float = 0.5 if cue == &"explosion" else 0.12
	var samples: int = int(duration * 22050.0)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples * 2)
	var frequency: float = 70.0 if cue == &"explosion" else 180.0
	if cue in [&"reload", &"dry"]:
		frequency = 900.0
	for i: int in range(samples):
		var t: float = float(i) / 22050.0
		var envelope: float = exp(-t * (8.0 if cue == &"explosion" else 40.0))
		var value: float = (sin(TAU * frequency * t) * 0.35 + randf_range(-0.6, 0.6)) * envelope
		bytes.encode_s16(i * 2, int(value * 22000.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.data = bytes
	return wav
