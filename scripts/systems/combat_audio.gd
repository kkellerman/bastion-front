extends Node

signal noise(position: Vector3, radius: float, source: CollisionObject3D)
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
	if cue in [&"gunshot", &"mounted", &"explosion"]:
		noise.emit(position, 45.0 if cue != &"gunshot" else 28.0, source)
	# Dummy has no audible output. Keep simulation noise, without allocating PCM
	# playbacks that its shutdown mixer may leave pending during CLI tests/bakes.
	if AudioServer.get_driver_name() == "Dummy":
		return
	if _voices >= 24:
		return
	var stream: AudioStream = override_stream
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
	voice.global_position = position
	voice.stream = stream
	voice.bus = &"Bunker" if interior_bounds.has_point(position) else &"Master"
	voice.volume_db = -18.0 if str(cue).begins_with("footstep") else -10.0
	voice.max_distance = 65.0
	voice.pitch_scale = randf_range(0.94, 1.06)
	_voices += 1
	voice.tree_exiting.connect(func() -> void:
		_voices -= 1
		voice.stop()
		voice.stream = null)
	voice.finished.connect(voice.queue_free)
	voice.play()

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
