extends CanvasLayer
## Small persistent options panel; gameplay is paused while editing.
var values: Dictionary = {"fov": 78.0, "sensitivity": 0.1, "master": 0.8, "effects": 1.0, "dialogue": 1.0, "ambience": 0.8, "communications": 0.7, "artillery": 0.7, "subtitles": true, "reduced_motion": false, "graphics_preset": 0, "vsync": true, "distant_combat": true, "voice_diagnostics": false}
var panel: PanelContainer
var _old_mouse: int
var capabilities: Dictionary
var recommended: int = 0
var applied_preset: int = 0
var graphics_summary: Label
var quality: OptionButton
## -1 leaves normal settings alone; 0+ pins Low and layers one probe patch on top.
var probe: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	capabilities = GraphicsProfile.audit()
	recommended = GraphicsProfile.recommend(capabilities)
	print("Graphics audit: ", capabilities, " Recommended: ", GraphicsProfile.PRESETS[recommended].name)
	var config: ConfigFile = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		for key: String in values: values[key] = config.get_value("settings", key, values[key])
	for bus: String in ["Effects", "Dialogue", "DialogueInterior", "DistantCombat", "Ambience", "Communications"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	AudioServer.set_bus_send(AudioServer.get_bus_index("DialogueInterior"), "Dialogue")
	AudioServer.set_bus_send(AudioServer.get_bus_index("Bunker"), "Effects")
	AudioServer.set_bus_send(AudioServer.get_bus_index("DistantCombat"), "Master")
	var room: AudioEffectReverb = AudioEffectReverb.new()
	room.wet = 0.2
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Communications"), room)
	var low_pass: AudioEffectLowPassFilter = AudioEffectLowPassFilter.new()
	low_pass.cutoff_hz = 700.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("DistantCombat"), low_pass)
	var reverb: AudioEffectReverb = AudioEffectReverb.new()
	reverb.wet = 0.23
	AudioServer.add_bus_effect(AudioServer.get_bus_index("DialogueInterior"), reverb)
	var meter: CanvasLayer = load("res://scripts/presentation/frame_meter.gd").new()
	meter.name = "FrameMeter"
	get_tree().root.call_deferred("add_child", meter)
	_build()
	apply()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F10:
		toggle()
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F6:
		# Live A/B: the same firefight with and without LOD cross-fading.
		GraphicsProfile.set_fades(get_tree().current_scene, not GraphicsProfile.fades_enabled)
		var meter_node: Node = get_tree().root.get_node_or_null("FrameMeter")
		if meter_node != null:
			meter_node.reset()
			meter_node.mark("LOD fades -> %s" % ("ON" if GraphicsProfile.fades_enabled else "OFF"))
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F8:
		# Shift steps back so a suspicious reading can be re-checked without a full lap.
		probe = wrapi(probe + (-1 if event.shift_pressed else 1), -1, GraphicsProfile.PROBES.size())
		apply()
		var meter: Node = get_tree().root.get_node_or_null("FrameMeter")
		if meter != null:
			meter.reset()
			meter.mark("probe -> %s" % probe_text())
		get_viewport().set_input_as_handled()

func toggle() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		_old_mouse = Input.mouse_mode
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		get_tree().paused = false
		Input.mouse_mode = _old_mouse as Input.MouseMode
		save()

func save() -> void:
	var config: ConfigFile = ConfigFile.new()
	for key: String in values: config.set_value("settings", key, values[key])
	config.save("user://settings.cfg")

func auto_detect() -> void:
	capabilities = GraphicsProfile.audit()
	recommended = GraphicsProfile.recommend(capabilities)
	values.graphics_preset = 0
	quality.select(0)
	apply()
	save()

func probe_text() -> String:
	if probe < 0: return "F8 probe: off  ·  now %s" % GraphicsProfile.PRESETS[applied_preset].name
	return "F8 probe %d/%d (shift+F8 back)  ·  Low %s" % [probe, GraphicsProfile.PROBES.size() - 1, GraphicsProfile.PROBES[probe].label]

func recommendation_text() -> String:
	if int(values.graphics_preset) != 0:
		return "Graphics: " + str(GraphicsProfile.PRESETS[clampi(int(values.graphics_preset)-1,0,2)].name)
	return "Auto: " + str(GraphicsProfile.PRESETS[recommended].name) + " settings recommended."

func apply() -> void:
	for key: String in ["master", "effects", "dialogue", "ambience", "communications"]:
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(key.capitalize()), float(values[key]))
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("DistantCombat"), float(values.artillery))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(values.vsync) else DisplayServer.VSYNC_DISABLED)
	# Uncapped frames a 60Hz panel cannot show are heat and fan noise, not smoothness.
	# 200 leaves ample headroom to measure while keeping the GPU off its limiter.
	Engine.max_fps = 0 if bool(values.vsync) else 200
	var scene: Node = get_tree().current_scene
	applied_preset = recommended if int(values.graphics_preset) == 0 else clampi(int(values.graphics_preset) - 1, 0, 2)
	if probe >= 0: applied_preset = 0
	GraphicsProfile.apply(scene, get_viewport(), applied_preset, capabilities, {} if probe < 0 else GraphicsProfile.PROBES[probe].patch)
	if graphics_summary != null:
		var p: Dictionary = GraphicsProfile.PRESETS[applied_preset].duplicate()
		for feature: String in ["fog","ssao","ssil","reflections"]:
			p[feature] = p[feature] and capabilities.get("renderer", "") == "forward_plus"
		graphics_summary.text = recommendation_text() + "\nResolution %d%% · shadows %dm · vegetation %d%%\nPlant range %dm · tree range %dm\nFog %s · SSAO %s · SSIL %s · MSAA %s · FXAA %s\nReflections %s · textures: %s" % [int(p.scale * 100), p.shadow_distance, int(p.density * 100), p.plants, p.trees, _on_off(p.fog), _on_off(p.ssao), _on_off(p.ssil), "2x" if p.msaa > 0 else "Off", _on_off(p.fxaa), _on_off(p.reflections), ["reduced detail","full detail","sharper sampling"][applied_preset]]
	AudioServer.set_bus_mute(AudioServer.get_bus_index("DistantCombat"), not values.distant_combat)
	if scene == null: return
	var player: Node = scene.get_node_or_null("Player")
	if player != null:
		player.get_node("MouseLook").sensitivity_degrees = float(values.sensitivity)
		player.get_node("Head/Camera3D/WeaponRig")._base_fov = float(values.fov)
	var soundscape: Node = scene.find_child("Soundscape", true, false)
	if soundscape != null: soundscape.distant_combat_enabled = bool(values.distant_combat)

func _on_off(active: bool) -> String:
	return "On" if active else "Off"

func _build() -> void:
	panel = PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = -325
	panel.offset_bottom = 325
	panel.custom_minimum_size = Vector2(600, 650)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.065, 0.06, 0.98)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	var layout: VBoxContainer = VBoxContainer.new()
	panel.add_child(layout)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	var title: Label = Label.new()
	title.text = "  FIELD SETTINGS  /  F10"
	box.add_child(title)
	for key: String in ["fov", "sensitivity", "master", "effects", "dialogue", "ambience", "communications", "artillery"]:
		var label: Label = Label.new()
		box.add_child(label)
		label.text = "  " + key.capitalize()
		var slider: HSlider = HSlider.new()
		box.add_child(slider)
		slider.min_value = 60.0 if key == "fov" else 0.01 if key == "sensitivity" else 0.0
		slider.max_value = 110.0 if key == "fov" else 0.4 if key == "sensitivity" else 1.0
		slider.step = 1.0 if key == "fov" else 0.01
		slider.value = float(values[key])
		slider.value_changed.connect(func(value: float) -> void:
			values[key] = value
			label.text = "  %s  %.2f" % [key.capitalize(), value]
			apply())
	for key: String in ["subtitles", "reduced_motion", "distant_combat", "voice_diagnostics", "vsync"]:
		var check: CheckButton = CheckButton.new()
		box.add_child(check)
		check.text = key.capitalize().replace("_", " ")
		if key == "voice_diagnostics": check.text = "Voice diagnostic tones (NON-SPEECH test clips)"
		if key == "distant_combat": check.text = "Distant off-map artillery ambience"
		if key == "vsync": check.text = "V-Sync: ON (caps at refresh rate)" if bool(values[key]) else "V-Sync: OFF (uncapped, may tear)"
		check.button_pressed = bool(values[key])
		check.toggled.connect(func(active: bool) -> void:
			values[key] = active
			if key == "vsync": check.text = "V-Sync: ON (caps at refresh rate)" if active else "V-Sync: OFF (uncapped, may tear)"
			apply())
	var voice_status: Label = Label.new()
	voice_status.text = "English/German recordings missing: subtitles only.\nDiagnostic tones test routing; they are not soldier speech."
	box.add_child(voice_status)
	quality = OptionButton.new()
	box.add_child(quality)
	for preset: String in ["Auto (recommended)", "Low", "Medium", "High"]: quality.add_item("Graphics: " + preset)
	quality.select(clampi(int(values.graphics_preset), 0, 3))
	quality.item_selected.connect(func(index: int) -> void:
		values.graphics_preset = index
		apply())
	graphics_summary = Label.new()
	graphics_summary.add_theme_font_size_override("font_size", 14)
	box.add_child(graphics_summary)
	var detect: Button = Button.new()
	detect.text = "Auto-detect recommended settings"
	detect.pressed.connect(auto_detect)
	box.add_child(detect)
	var close: Button = Button.new()
	layout.add_child(close)
	close.text = "SAVE AND RETURN"
	close.pressed.connect(toggle)
	panel.hide()
