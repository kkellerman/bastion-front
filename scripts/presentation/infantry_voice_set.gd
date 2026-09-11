class_name InfantryVoiceSet
extends Resource
@export var language: StringName = &"de"
@export var subtitles: Dictionary[StringName, String] = {}
@export var recordings: Dictionary[StringName, AudioStream] = {}
@export var subtitle_keys: Dictionary[StringName, StringName] = {}
@export var durations: Dictionary[StringName, float] = {}
@export_dir var recording_directory: String = ""
@export var diagnostic_frequency: float = 440.0

func recording(category: StringName) -> AudioStream:
	if recordings.has(category): return recordings[category]
	var path: String = recording_directory.path_join(str(category) + ".wav")
	return load(path) as AudioStream if ResourceLoader.exists(path) else null

func diagnostic_clip() -> AudioStreamWAV:
	# Explicitly a two-note equipment-test tone, never a speech substitute.
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(22050 * 2)
	for i: int in range(22050):
		var t: float = float(i) / 22050.0
		var envelope: float = sin(PI * fmod(t, 0.5) * 2.0)
		var value: float = sin(TAU * diagnostic_frequency * (1.0 if t < 0.5 else 1.5) * t) * envelope * 0.3
		bytes.encode_s16(i * 2, int(value * 32767.0))
	var clip: AudioStreamWAV = AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = 22050
	clip.data = bytes
	return clip
