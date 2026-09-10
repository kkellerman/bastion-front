extends CanvasLayer
## Small persistent options panel; gameplay is paused while editing.
var values: Dictionary = {"fov": 78.0, "sensitivity": 0.1, "master": 0.8, "effects": 1.0, "dialogue": 1.0, "subtitles": true, "reduced_motion": false, "quality": 1}
var panel: PanelContainer
var _old_mouse: int

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	var config: ConfigFile = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		for key: String in values: values[key] = config.get_value("settings", key, values[key])
	for bus: String in ["Effects", "Dialogue", "DialogueInterior"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	AudioServer.set_bus_send(AudioServer.get_bus_index("DialogueInterior"), "Dialogue")
	AudioServer.set_bus_send(AudioServer.get_bus_index("Bunker"), "Effects")
	var reverb: AudioEffectReverb = AudioEffectReverb.new()
	reverb.wet = 0.23
	AudioServer.add_bus_effect(AudioServer.get_bus_index("DialogueInterior"), reverb)
	_build()
	apply()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F10:
		toggle()
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
		var config: ConfigFile = ConfigFile.new()
		for key: String in values: config.set_value("settings", key, values[key])
		config.save("user://settings.cfg")

func apply() -> void:
	for key: String in ["master", "effects", "dialogue"]:
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(key.capitalize()), float(values[key]))
	var scene: Node = get_tree().current_scene
	if scene == null: return
	var player: Node = scene.get_node_or_null("Player")
	if player != null:
		player.get_node("MouseLook").sensitivity_degrees = float(values.sensitivity)
		player.get_node("Head/Camera3D/WeaponRig")._base_fov = float(values.fov)
	var world: WorldEnvironment = scene.find_child("Environment", true, false) as WorldEnvironment
	if world != null:
		world.environment.ssao_enabled = int(values.quality) > 0
		world.environment.ssil_enabled = int(values.quality) > 0
		world.environment.volumetric_fog_enabled = int(values.quality) > 0

func _build() -> void:
	panel = PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-230, -265)
	panel.custom_minimum_size = Vector2(460, 530)
	var box: VBoxContainer = VBoxContainer.new()
	panel.add_child(box)
	var title: Label = Label.new()
	title.text = "  FIELD SETTINGS  /  F10"
	box.add_child(title)
	for key: String in ["fov", "sensitivity", "master", "effects", "dialogue"]:
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
	for key: String in ["subtitles", "reduced_motion"]:
		var check: CheckButton = CheckButton.new()
		box.add_child(check)
		check.text = key.capitalize().replace("_", " ")
		check.button_pressed = bool(values[key])
		check.toggled.connect(func(active: bool) -> void: values[key] = active)
	var quality: OptionButton = OptionButton.new()
	box.add_child(quality)
	quality.add_item("Graphics: performance")
	quality.add_item("Graphics: atmospheric")
	quality.select(int(values.quality))
	quality.item_selected.connect(func(index: int) -> void:
		values.quality = index
		apply())
	var close: Button = Button.new()
	box.add_child(close)
	close.text = "SAVE AND RETURN"
	close.pressed.connect(toggle)
	panel.hide()
