extends Node3D
## Presentation zones are independent of combat noise/hearing events.
@export var listener: Node3D
@export var distant_combat_enabled: bool = false
@export var distant_position: Vector3 = Vector3(180, 15, -300)
@export var interior_bounds: AABB = AABB(Vector3(-9, -1, -80), Vector3(18, 5, 21))
var wind: AudioStreamPlayer
var bunker: AudioStreamPlayer
var _distant_time: float = 7.0
var _inside: bool = false
var _quitting: bool = false
var active: bool = true
var canopy: AudioStreamPlayer
var gust: AudioStreamPlayer
var radio: AudioStreamPlayer3D
var signals: AudioStreamPlayer3D
var _radio_time: float = 3.0
var _age: float = 0.0
var comm_room_warning: AudioStreamPlayer3D
var _comm_room_warning_played: bool = false
## Same spot as the radio_bed source: this is the communications desk.
const COMM_ROOM_POSITION: Vector3 = Vector3(6, 1.3, -64)
const COMM_ROOM_TRIGGER_RADIUS: float = 6.0

func _exit_tree() -> void:
	stop_audio()

func stop_audio() -> void:
	active = false
	for child: Node in get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D:
			child.stop()
			child.stream = null

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_node("/root/CombatAudio").interior_bounds = interior_bounds
	if listener != null:
		var owner_node: Node = listener
		while owner_node.get_parent() != null and not owner_node is CharacterBody3D:
			owner_node = owner_node.get_parent()
		var health: HealthComponent = owner_node.get_node_or_null("HealthComponent")
		if health != null: health.died.connect(stop_audio)
	if AudioServer.get_driver_name() == "Dummy":
		set_process(false)
		return
	wind = _loop("wind", -28.0)
	canopy = _loop("canopy", -28.0)
	canopy.play(4.1)
	gust = _loop("gust", -28.0)
	gust.play(7.3)
	bunker = _loop("bunker", -60.0)
	radio = _radio_source("radio_bed", -28)
	signals = _radio_source("radio_signal", -27)
	radio.play()
	comm_room_warning = AudioStreamPlayer3D.new()
	add_child(comm_room_warning)
	comm_room_warning.add_to_group(&"communications_audio")
	comm_room_warning.global_position = COMM_ROOM_POSITION
	comm_room_warning.bus = &"Communications"
	# A real recording dropped in for review; unlike the *.res cues this loads
	# a raw .wav directly, since it has no synthesized-prototype fallback.
	comm_room_warning.stream = load("res://assets/audio/ambience/186890__beat24__warning_message_german.wav")
	comm_room_warning.volume_db = -6.0
	comm_room_warning.unit_size = 4
	comm_room_warning.max_distance = 20
	var birds: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	add_child(birds)
	birds.position = Vector3(15, 8, 0)
	birds.stream = load("res://assets/audio/designed/birds.res")
	birds.bus = &"Ambience"
	birds.volume_db = -21
	birds.max_distance = 40
	birds.play()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

func quit_game() -> void:
	if _quitting: return
	_quitting = true
	set_process(false)
	stop_audio()
	get_node("/root/CombatAudio").stop_all()
	# Let the audio mixer retire stopped streams before the engine shuts down.
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()

func _process(delta: float) -> void:
	if not active or not is_instance_valid(listener): return
	var mission: Node = get_tree().current_scene
	if mission != null and "complete" in mission and mission.complete:
		stop_audio()
		return
	_age += delta
	_inside = interior_bounds.has_point(listener.global_position)
	if not _comm_room_warning_played and listener.global_position.distance_to(COMM_ROOM_POSITION) <= COMM_ROOM_TRIGGER_RADIUS:
		_comm_room_warning_played = true
		comm_room_warning.play()
	wind.volume_db = move_toward(wind.volume_db, -35.0 if _inside else -20.0, delta * 15)
	canopy.volume_db = move_toward(canopy.volume_db, (-43.0 if _inside else -29.0) + sin(_age * 0.17) * 2, delta * 8)
	gust.volume_db = move_toward(gust.volume_db, (-43.0 if _inside else -29.0) - sin(_age * 0.17) * 2, delta * 8)
	bunker.volume_db = move_toward(bunker.volume_db, -24.0 if _inside else -60.0, delta * 15)
	var radio_target: float = -28.0 if _inside else -44.0
	radio.volume_db = move_toward(radio.volume_db, radio_target, delta * 8)
	signals.volume_db = radio.volume_db + 1
	_radio_time -= delta
	if _radio_time <= 0:
		_radio_time = randf_range(4.5, 11.0)
		signals.pitch_scale = randf_range(0.94, 1.05)
		signals.play()
	for tail: AudioStreamPlayer3D in get_tree().get_nodes_in_group(&"distant_combat_audio"):
		tail.volume_db = move_toward(tail.volume_db, -12.0 if _inside else -4.0, delta * 12)
		if not distant_combat_enabled:
			tail.stop()
			tail.queue_free()
	# Optional off-map artillery, never a listener-following imitation of a local rifle.
	if not distant_combat_enabled: return
	_distant_time -= delta
	if _distant_time <= 0:
		_distant_time = randf_range(12, 24)
		var audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		audio.bus = &"DistantCombat"
		add_child(audio)
		audio.add_to_group(&"distant_combat_audio")
		audio.global_position = distant_position + Vector3(randf_range(-70, 70), 0, randf_range(-50, 50))
		audio.stream = load("res://assets/audio/designed/distant_artillery.res")
		audio.volume_db = -12.0 if _inside else -4.0
		audio.unit_size = 320
		audio.max_distance = 650
		audio.pitch_scale = randf_range(0.78, 1.05)
		audio.tree_exiting.connect(func() -> void:
			audio.stop()
			audio.stream = null)
		audio.finished.connect(audio.queue_free)
		audio.play()

func _loop(cue: String, volume: float) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = &"Ambience"
	add_child(player)
	player.stream = load("res://assets/audio/designed/" + cue + ".res")
	player.volume_db = volume
	player.play()
	return player

func _radio_source(cue: String, volume: float) -> AudioStreamPlayer3D:
	var audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	add_child(audio)
	audio.add_to_group(&"communications_audio")
	audio.global_position = Vector3(6, 1.3, -64)
	audio.bus = &"Communications"
	audio.stream = load("res://assets/audio/designed/" + cue + ".res")
	audio.volume_db = volume
	audio.unit_size = 3
	audio.max_distance = 17
	audio.attenuation_filter_cutoff_hz = 2200
	return audio
