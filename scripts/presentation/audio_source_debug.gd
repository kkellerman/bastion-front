extends CanvasLayer
## Opt-in investigation overlay. No changes to perception, health or navigation.
var mission: Node3D
var panel: Label
var markers: Dictionary[StringName, Label] = {}
var recent: Array[String] = []
var _remaining: float = 0.0

func _ready() -> void:
	layer = 80
	mission = get_parent().get_parent() as Node3D
	panel = Label.new()
	add_child(panel)
	panel.position = Vector2(24,170)
	panel.add_theme_font_size_override("font_size",14)
	panel.add_theme_constant_override("outline_size",7)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for enemy: Node3D in mission.get_node("Enemies").get_children():
		var marker: Label = Label.new()
		add_child(marker)
		marker.add_theme_constant_override("outline_size",6)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		markers[enemy.name] = marker
	get_node("/root/CombatAudio").cue_started.connect(_cue)
	hide()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F9:
		visible = not visible
		_remaining = 0
		get_viewport().set_input_as_handled()

func _cue(cue: StringName, source: CollisionObject3D) -> void:
	if cue not in [&"gunshot",&"mounted",&"explosion",&"impact_metal"]: return
	var identity: String = str(source.name) if is_instance_valid(source) else "world impact / near miss"
	recent.push_front("%ds  %s: %s" % [Time.get_ticks_msec()/1000,identity,cue])
	if recent.size() > 5: recent.resize(5)

func _process(delta: float) -> void:
	if not visible: return
	_remaining -= delta
	if _remaining > 0: return
	_remaining = 0.1
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null: return
	var lines: PackedStringArray = PackedStringArray(["F9 AUDIO / SOLDIER AUDIT (labels show through cover)"])
	var variant: MissionVariant = mission.get_node_or_null("MissionVariant")
	if variant != null:
		lines.append("Operation %d | %s" % [variant.operation_seed, "restricted flank" if variant.restricted_flank else "open flank"])
		lines.append(variant.signature)
	lines.append("Driver: %s | output: %s" % [AudioServer.get_driver_name(), AudioServer.output_device])
	for bus: String in ["Master","Effects","Dialogue"]:
		var index: int = AudioServer.get_bus_index(bus)
		lines.append("%s: %d%% | muted %s | peak %.1f dB" % [bus,int(AudioServer.get_bus_volume_linear(index)*100), AudioServer.is_bus_mute(index), AudioServer.get_bus_peak_volume_left_db(index,0)])
	lines.append("Speech recordings missing; subtitles/test tones only.")
	lines.append("Off-map artillery: " + ("ENABLED" if get_node("/root/PlayerSettings").values.distant_combat else "off"))
	for enemy: InfantryBrain in mission.get_node("Enemies").get_children():
		var alive: bool = enemy.health.current_health > 0
		var point: Vector3 = enemy.global_position + Vector3.UP*1.7
		var hit: Dictionary = enemy.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(camera.global_position,point,1))
		var condition: String = "behind cover" if not hit.is_empty() else "clear sightline"
		if camera.is_position_behind(point): condition = "behind camera"
		var state: String = InfantryBrain.State.keys()[enemy.state]
		lines.append("%s %s %.0fm [%s] at %.1f, %.1f, %.1f" % [enemy.name,state,camera.global_position.distance_to(point),condition,enemy.position.x,enemy.position.y,enemy.position.z])
		var marker: Label = markers[enemy.name]
		marker.visible = alive and not camera.is_position_behind(point)
		if marker.visible:
			marker.position = camera.unproject_position(point)
			marker.text = "%s [%s]" % [enemy.name,state]
			marker.modulate = Color(1,0.5,0.3) if enemy.state == InfantryBrain.State.ATTACK else Color(0.9,0.9,0.5)
	lines.append("Recent game effects (not artillery):")
	for entry: String in recent: lines.append(entry)
	panel.text = "\n".join(lines)
