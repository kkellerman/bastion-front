extends Node3D
## Presentation zones are independent of combat noise/hearing events.
@export var listener: Node3D
@export var interior_bounds: AABB = AABB(Vector3(-9, -1, -80), Vector3(18, 5, 21))
var wind: AudioStreamPlayer
var bunker: AudioStreamPlayer
var _distant_time: float = 7.0
var _inside: bool = false
var _quitting: bool = false

func _exit_tree() -> void:
	stop_audio()

func stop_audio() -> void:
	for child: Node in get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D:
			child.stop()
			child.stream = null

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_node("/root/CombatAudio").interior_bounds = interior_bounds
	if AudioServer.get_driver_name() == "Dummy":
		set_process(false)
		return
	wind = _loop("wind", -20.0)
	bunker = _loop("bunker", -60.0)
	var birds: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	add_child(birds)
	birds.position = Vector3(15, 8, 0)
	birds.stream = load("res://assets/audio/designed/birds.res")
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
	if not is_instance_valid(listener): return
	_inside = interior_bounds.has_point(listener.global_position)
	wind.volume_db = move_toward(wind.volume_db, -35.0 if _inside else -20.0, delta * 15)
	bunker.volume_db = move_toward(bunker.volume_db, -24.0 if _inside else -60.0, delta * 15)
	_distant_time -= delta
	if _distant_time <= 0:
		_distant_time = randf_range(10, 19)
		var audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		add_child(audio)
		audio.global_position = listener.global_position + Vector3(30, 8, -45)
		audio.stream = load("res://assets/audio/designed/" + ("distant_artillery" if randf() < 0.6 else "distant_fire") + ".res")
		audio.volume_db = -23 if _inside else -13
		audio.unit_size = 20
		audio.max_distance = 120
		audio.finished.connect(audio.queue_free)
		audio.play()

func _loop(cue: String, volume: float) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(player)
	player.stream = load("res://assets/audio/designed/" + cue + ".res")
	player.volume_db = volume
	player.play()
	return player
