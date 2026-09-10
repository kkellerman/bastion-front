extends Node

signal noise(position: Vector3, radius: float, source: CollisionObject3D)
var palette: AudioPalette = preload("res://resources/audio/prototype_palette.tres")
var _fallbacks: Dictionary[StringName, AudioStream] = {}
var _voices: int = 0


func _exit_tree() -> void:
	for child: Node in get_children():
		var voice: AudioStreamPlayer3D = child as AudioStreamPlayer3D
		voice.stop()
		voice.stream = null
	_fallbacks.clear()


func play(cue: StringName, position: Vector3, source: CollisionObject3D = null, override_stream: AudioStream = null) -> void:
	if cue in [&"gunshot", &"mounted", &"explosion"]:
		noise.emit(position, 45.0 if cue != &"gunshot" else 28.0, source)
	if _voices >= 24:
		return
	var stream: AudioStream = override_stream if override_stream != null else palette.get(cue) as AudioStream
	if stream == null:
		if not _fallbacks.has(cue):
			_fallbacks[cue] = _synthesize(cue)
		stream = _fallbacks[cue]
	var voice: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	add_child(voice)
	voice.global_position = position
	voice.stream = stream
	voice.volume_db = -18.0 if cue == &"footstep" else -10.0
	voice.max_distance = 65.0
	voice.pitch_scale = randf_range(0.94, 1.06)
	_voices += 1
	voice.finished.connect(func() -> void:
		_voices -= 1
		voice.queue_free())
	voice.play()


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
