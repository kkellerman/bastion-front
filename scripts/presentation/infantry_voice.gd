extends Node3D
## Text and recordings stay separate. Empty recording slots never synthesize speech.
signal subtitle_requested(text: String)
@export var voice_set: InfantryVoiceSet
var _cooldown: float = 0.0
var _had_contact: bool = false

func _process(delta: float) -> void:
	_cooldown = maxf(0, _cooldown - delta)

func say(category: StringName) -> void:
	if voice_set == null or _cooldown > 0 or not voice_set.subtitles.has(category): return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or camera.global_position.distance_to(global_position) > 22: return
	_cooldown = 5.0
	subtitle_requested.emit(voice_set.subtitles[category])
	if voice_set.recordings.has(category):
		var audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		add_child(audio)
		audio.stream = voice_set.recordings[category]
		audio.max_distance = 25
		audio.bus = &"Bunker" if global_position.z < -59 else &"Master"
		audio.finished.connect(audio.queue_free)
		audio.play()

func state_changed(state: String) -> void:
	match state:
		"ALERT":
			if get_parent().sees_target:
				_had_contact = true
				say(&"spotting")
		"HURT": say(&"taking_fire")
		"CHASE": say(&"moving")
		"IDLE":
			if _had_contact:
				say(&"lost_sight")
				_had_contact = false
