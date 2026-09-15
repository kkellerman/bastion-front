extends CanvasLayer
## F7 frame meter. The live line repaints every frame so dips are visible as they
## happen; the smoothed line is what a Low/Medium comparison should be read from,
## since a mean hides the stutter you actually feel and a 1% low does not.
const WINDOW: int = 60
const SMOOTHING: float = 0.15
const VSYNC_NAMES: PackedStringArray = ["off", "on", "adaptive", "mailbox"]
## A spike is a frame well past the refresh budget. 1.8x tolerates ordinary
## vsync jitter while still catching a stutter the eye registers.
const SPIKE_FACTOR: float = 1.8
const SPIKE_LOG: int = 6
## Session log survives the process; the on-screen list only keeps the last few.
const LOG_PATH: String = "user://frame_log.txt"

var readout: Label
var _samples: PackedFloat32Array = _make_window()
var _cursor: int = 0
var _filled: int = 0
var _live_ms: float = 0.0
var _peak_ms: float = 0.0
var _peak_hold: float = 0.0
var _spikes: Array[String] = []
var _recent_cue: String = ""
var _cue_age: float = 99.0
var _seen: Dictionary[String, bool] = {}
var _elapsed: float = 0.0
var _budget_ms: float = 16.7
var _warmup: float = 0.0
var _log: FileAccess
var _spike_total: int = 0
var _header_written: bool = false
var _last_sample: float = 0.0
var _where: String = "?"
var _speed: float = 0.0
var _last_pos: Vector3 = Vector3.ZERO
var _has_pos: bool = false
var _scene: String = ""
var _tier_seen: String = ""
var _vsync_seen: int = -1

static func _make_window() -> PackedFloat32Array:
	var buffer: PackedFloat32Array = PackedFloat32Array()
	buffer.resize(WINDOW)
	return buffer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	readout = Label.new()
	add_child(readout)
	readout.position = Vector2(24, 24)
	readout.add_theme_font_size_override("font_size", 15)
	readout.add_theme_constant_override("outline_size", 7)
	readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var refresh: float = DisplayServer.screen_get_refresh_rate()
	if refresh > 1.0: _budget_ms = 1000.0 / refresh
	var audio: Node = get_node_or_null("/root/CombatAudio")
	if audio != null: audio.cue_started.connect(_cue)
	# READ_WRITE + seek_end appends; WRITE would discard earlier runs.
	_log = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if _log == null: _log = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if _log != null: _log.seek_end()
	hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE: _close_log()

func _close_log() -> void:
	if _log == null: return
	_log.store_line("")
	_log.store_line("session end  %.1fs  ·  %d spikes total" % [_elapsed, _spike_total])
	_log.close()
	_log = null

func mark(note: String) -> void:
	## Written by the F8 stepper so each probe's samples are attributable.
	if _log == null: return
	_log.store_line("")
	_log.store_line("--- %6.1fs  %s ---" % [_elapsed, note])
	_log.flush()

func _cue(cue: StringName, _source: CollisionObject3D) -> void:
	## Attribution only: the cue that fired nearest the spike, not proof of cause.
	_recent_cue = str(cue)
	_cue_age = 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F7:
		visible = not visible
		reset()
		if visible: mark("meter shown")
		get_viewport().set_input_as_handled()

func reset() -> void:
	## Called on probe changes too: old samples describe old settings.
	_cursor = 0
	_filled = 0
	_live_ms = 0.0
	_peak_ms = 0.0
	_peak_hold = 0.0
	# Settings changes rebuild pipelines; ignore the stalls that causes.
	_warmup = 0.75

func _process(delta: float) -> void:
	# Sampling runs whether or not the overlay is shown: the log should be complete
	# even when F7 was never pressed. Only the label work is gated on visibility.
	if not _header_written: _write_header()
	var frame_ms: float = delta * 1000.0
	_samples[_cursor] = frame_ms
	_cursor = (_cursor + 1) % WINDOW
	_filled = mini(_filled + 1, WINDOW)
	# Light smoothing only: enough to keep the digits readable, not enough to hide a spike.
	_live_ms = frame_ms if _live_ms == 0.0 else lerpf(_live_ms, frame_ms, SMOOTHING)
	_peak_hold -= delta
	if frame_ms > _peak_ms or _peak_hold <= 0.0:
		_peak_ms = frame_ms
		_peak_hold = 2.0
	_elapsed += delta
	_cue_age += delta
	_track(delta)
	_warmup -= delta
	if _warmup <= 0.0 and frame_ms > _budget_ms * SPIKE_FACTOR: _record(frame_ms)
	if _log != null and _elapsed - _last_sample >= 5.0:
		_last_sample = _elapsed
		_log.store_line("steady %6.1fs  %s  %s" % [_elapsed, _summary(), _where])
		_log.flush()
	if not visible: return
	readout.text = "F7  %s\n%s\n%s" % [_live(), _summary(), _probe()]

func _write_header() -> void:
	## Deferred to the first frame: settings apply after _ready(), so reading
	## vsync any earlier reports Godot's startup default instead of the setting.
	_header_written = true
	if _log == null: return
	_log.store_line("")
	_log.store_line("=== RUN  %s ===" % Time.get_datetime_string_from_system())
	_log.store_line("adapter: %s  ·  budget %.1f ms  ·  spike threshold %.1f ms" % [RenderingServer.get_video_adapter_name(), _budget_ms, _budget_ms * SPIKE_FACTOR])
	_log.store_line("vsync %s  ·  screen %.0f Hz  ·  max_fps %s" % [VSYNC_NAMES[clampi(DisplayServer.window_get_vsync_mode(), 0, 3)], DisplayServer.screen_get_refresh_rate(), "uncapped" if Engine.max_fps == 0 else str(Engine.max_fps)])
	_log.store_line("quality: %s  ·  LOD fades %s" % [_tier(), "on" if GraphicsProfile.fades_enabled else "off"])
	_log.store_line("")
	_log.flush()

func _tier() -> String:
	var settings: Node = get_node_or_null("/root/PlayerSettings")
	if settings == null: return "unknown"
	var choice: int = int(settings.values.graphics_preset)
	var applied: String = str(GraphicsProfile.PRESETS[settings.applied_preset].name)
	return "%s (dropdown: %s)" % [applied, "Auto" if choice == 0 else applied]

func _track(delta: float) -> void:
	## Position and speed make an uncued spike locatable: standing still points at
	## streaming or compilation, moving points at what just came into view.
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		_where = "no camera"
		return
	var pos: Vector3 = camera.global_position
	if _has_pos and delta > 0.0: _speed = _last_pos.distance_to(pos) / delta
	_last_pos = pos
	_has_pos = true
	_where = "(%.0f,%.0f,%.0f) %s" % [pos.x, pos.y, pos.z, "moving %.1fm/s" % _speed if _speed > 0.4 else "still"]
	var now_vsync: int = DisplayServer.window_get_vsync_mode()
	if _header_written and now_vsync != _vsync_seen:
		_vsync_seen = now_vsync
		if _log != null:
			_log.store_line("--- %6.1fs  vsync: %s ---" % [_elapsed, VSYNC_NAMES[clampi(now_vsync, 0, 3)]])
			_log.flush()
	var now_tier: String = _tier()
	if now_tier != _tier_seen:
		_tier_seen = now_tier
		if _log != null:
			_log.store_line("--- %6.1fs  quality: %s ---" % [_elapsed, now_tier])
			_log.flush()
	var current: Node = get_tree().current_scene
	var scene_name: String = "" if current == null else str(current.name)
	if scene_name != _scene:
		_scene = scene_name
		if _log != null:
			_log.store_line("--- %6.1fs  scene: %s ---" % [_elapsed, _scene])
			_log.flush()

func _record(frame_ms: float) -> void:
	# A cue within ~120ms is plausibly the trigger; anything older is unrelated.
	var blame: String = _recent_cue if _cue_age < 0.12 else "no cue"
	var first: bool = not _seen.has(blame)
	_seen[blame] = true
	# FIRST vs repeat is the whole diagnosis: shader stalls fire once per effect,
	# per-frame cost repeats every time.
	_spike_total += 1
	if _log != null:
		_log.store_line("SPIKE %6.1fs  %6.1f ms  %3.0f fps  %-10s %-6s  %s" % [_elapsed, frame_ms, 1000.0 / maxf(frame_ms, 0.001), blame, "FIRST" if first else "repeat", _where])
		_log.flush()
	_spikes.push_front("  %6.1fs  %5.1f ms (%2.0f fps)  %-14s %s" % [_elapsed, frame_ms, 1000.0 / maxf(frame_ms, 0.001), blame, "FIRST" if first else "repeat"])
	if _spikes.size() > SPIKE_LOG: _spikes.resize(SPIKE_LOG)

func _spike_report() -> String:
	if _spikes.is_empty(): return "spikes: none past %.1f ms" % (_budget_ms * SPIKE_FACTOR)
	var repeats: int = 0
	for line: String in _spikes:
		if line.ends_with("repeat"): repeats += 1
	var verdict: String = "mostly FIRST -> shader/resource stalls" if repeats * 2 < _spikes.size() else "mostly repeat -> per-frame cost"
	return "spikes past %.1f ms (%s):
%s" % [_budget_ms * SPIKE_FACTOR, verdict, "
".join(_spikes)]

func _live() -> String:
	var live_fps: float = 1000.0 / maxf(_live_ms, 0.001)
	# Worst frame in the last 2s: a stutter you'd otherwise blink past.
	return "%5.1f fps  %5.2f ms      worst %4.1f fps  (%.1f ms)" % [live_fps, _live_ms, 1000.0 / maxf(_peak_ms, 0.001), _peak_ms]

func _summary() -> String:
	if _filled < 8: return "1s avg: sampling..."
	var window: Array[float] = []
	for index: int in _filled: window.append(_samples[index])
	window.sort()
	var total: float = 0.0
	for value: float in window: total += value
	var mean: float = total / float(_filled)
	# 99th percentile frame time == the "1% low" framerate players quote.
	var worst: float = window[mini(int(float(_filled) * 0.99), _filled - 1)]
	return "1s avg %.0f fps (%.1f ms)   1%% low %.0f fps (%.1f ms)" % [1000.0 / maxf(mean, 0.001), mean, 1000.0 / maxf(worst, 0.001), worst]

func _probe() -> String:
	var mode: int = DisplayServer.window_get_vsync_mode()
	var capped: String = "vsync %s" % VSYNC_NAMES[clampi(mode, 0, 3)]
	if mode != DisplayServer.VSYNC_DISABLED: capped += " (caps fps - disable to see real headroom)"
	if Engine.max_fps > 0: capped += "  ·  max_fps %d" % Engine.max_fps
	var settings: Node = get_node_or_null("/root/PlayerSettings")
	return capped if settings == null else capped + "\n" + settings.probe_text()
