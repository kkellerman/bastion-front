extends Node
signal line_started(text: String, duration: float)
var remaining: float = 0.0
var categories: Dictionary[StringName, float] = {}

func _process(delta: float) -> void:
	remaining = maxf(0, remaining - delta)
	for category: StringName in categories: categories[category] = maxf(0, categories[category] - delta)

func request(voice: Node3D, category: StringName, radio: bool = false) -> bool:
	var data: InfantryVoiceSet = voice.voice_set
	if data == null or not data.subtitles.has(category) or remaining > 0 or categories.get(category, 0.0) > 0: return false
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not radio and (camera == null or camera.global_position.distance_to(voice.global_position) > 25): return false
	var stream: AudioStream = data.recordings.get(category)
	var duration: float = maxf(2.4, stream.get_length()) if stream != null else data.durations.get(category, 3.0)
	remaining = duration + 0.4
	categories[category] = 10.0
	var key: StringName = data.subtitle_keys.get(category, category)
	var translated: String = tr(key)
	line_started.emit(data.subtitles[category] if translated == str(key) else translated, duration)
	if stream != null and AudioServer.get_driver_name() != "Dummy":
		var audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		add_child(audio)
		audio.global_position = voice.global_position
		audio.stream = stream
		audio.max_distance = 30
		audio.bus = &"DialogueInterior" if get_node("/root/CombatAudio").interior_bounds.has_point(voice.global_position) else &"Dialogue"
		audio.finished.connect(audio.queue_free)
		audio.tree_exiting.connect(func() -> void:
			audio.stop()
			audio.stream = null)
		audio.play()
	return true
