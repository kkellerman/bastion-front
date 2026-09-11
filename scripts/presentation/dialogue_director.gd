extends Node
signal line_started(text: String, duration: float)
signal playback_started(language: StringName, category: StringName, audio: AudioStreamPlayer3D)
signal line_cleared
signal actor_line_started(actor: Node3D, category: StringName)
var active_voice: WeakRef
var remaining: float = 0.0
var categories: Dictionary[StringName, float] = {}

func _process(delta: float) -> void:
	for source: Node in get_tree().get_nodes_in_group(&"combat_voices"):
		if not source.available(): source._pending = &""
	if active_voice != null:
		var voice: Node = active_voice.get_ref()
		if voice == null or not voice.available():
			line_cleared.emit()
			active_voice = null
	remaining = maxf(0, remaining - delta)
	for category: StringName in categories: categories[category] = maxf(0, categories[category] - delta)

func stop(voice: Node3D) -> void:
	# Actor died mid-line: end its own in-flight playback/subtitle without touching others.
	for audio: Node in voice.get_tree().get_nodes_in_group(&"dialogue_audio"):
		if audio.get_parent() == voice:
			audio.stop()
			audio.queue_free()
	if active_voice != null and active_voice.get_ref() == voice:
		active_voice = null
		line_cleared.emit()


func request(voice: Node3D, category: StringName, radio: bool = false) -> bool:
	var data: InfantryVoiceSet = voice.voice_set
	if not voice.available() or data == null or not data.subtitles.has(category): return false
	var urgent: bool = category == &"death"
	if not urgent and (remaining > 0 or categories.get(category, 0.0) > 0): return false
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not radio and (camera == null or camera.global_position.distance_to(voice.global_position) > 25): return false
	var stream: AudioStream = data.recording(category)
	var missing: bool = stream == null
	var diagnostic: bool = missing and get_node("/root/PlayerSettings").values.voice_diagnostics
	if diagnostic: stream = data.diagnostic_clip()
	if urgent:
		for old: Node in get_tree().get_nodes_in_group(&"dialogue_audio"):
			old.stop()
			old.queue_free()
	var duration: float = maxf(2.4, stream.get_length()) if stream != null else data.durations.get(category, 3.0)
	remaining = duration + 0.4
	categories[category] = 10.0
	var key: StringName = data.subtitle_keys.get(category, category)
	var translated: String = tr(key)
	var words: String = data.subtitles[category] if translated == str(key) else translated
	if missing: words = ("[NON-SPEECH VOICE TEST] " if diagnostic else "[Voice recording missing] ") + words
	active_voice = weakref(voice)
	actor_line_started.emit(voice.get_parent(), category)
	line_started.emit(words, duration)
	if stream != null and AudioServer.get_driver_name() != "Dummy":
		var audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		# Follow the speaking actor; scene restart retires every playback.
		voice.add_child(audio)
		audio.position = Vector3.UP * 1.5
		audio.add_to_group(&"dialogue_audio")
		audio.stream = stream
		audio.max_distance = 30
		audio.unit_size = 5.0
		audio.attenuation_filter_cutoff_hz = 10000.0
		audio.set_meta(&"language", data.language)
		audio.set_meta(&"category", category)
		audio.set_meta(&"diagnostic", diagnostic)
		audio.bus = &"DialogueInterior" if get_node("/root/CombatAudio").interior_bounds.has_point(voice.global_position) else &"Dialogue"
		audio.finished.connect(audio.queue_free)
		audio.tree_exiting.connect(func() -> void:
			audio.stop()
			audio.stream = null)
		audio.play()
		playback_started.emit(data.language, category, audio)
	return true
