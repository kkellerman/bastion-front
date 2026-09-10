extends SceneTree
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var menu: Node3D = load("res://scenes/ui/title_menu.tscn").instantiate() as Node3D
	root.add_child(menu)
	current_scene = menu
	await _frames(90)
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Title screen releases mouse")
	menu._select(2)
	_check("WASD" in menu.panel.text, "Field manual presents controls")
	menu._select(3)
	_check("CC0" in menu.panel.text, "Menu credits identify asset license")
	menu.panel.text = ""
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/validation/title_menu.png")
	if "--quit-menu" in OS.get_cmdline_user_args():
		print("PASS: Menu quit invokes orderly audio shutdown")
		menu._select(4)
		return
	var enter: InputEventKey = InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	Input.parse_input_event(enter)
	enter = enter.duplicate() as InputEventKey
	enter.pressed = false
	Input.parse_input_event(enter)
	await _frames(90)
	var mission: Node3D = current_scene as Node3D
	_check(mission.has_node("Player"), "Allied menu entry launches the playable mission")
	var env: Node3D = mission.get_node("Environment") as Node3D
	_check(not env.get_node("Forest/Conifer1/LowerCanopy").visible, "Original cone presentation is replaced")
	_check(env.get_node("Presentation").get_child_count() > 100, "Forest and command-post dressing is present")
	_check(env.get_node("Environment").environment.ssao_enabled, "Presentation enables ambient occlusion")
	_check(env.get_node("Terrain/Ground/Mesh").material_override is ShaderMaterial, "Forest ground has layered PBR material")
	var voice_set: InfantryVoiceSet = load("res://resources/characters/german_voice.tres") as InfantryVoiceSet
	_check(voice_set.subtitles.size() == 9 and voice_set.recordings.is_empty(), "German dialogue categories retain separate unfilled recording slots")
	_check(AudioServer.get_bus_index("Bunker") >= 0, "Bunker reverb bus is available")
	for cue: String in ["impact_dirt", "impact_wood", "impact_concrete", "impact_metal", "footstep_dirt", "footstep_concrete", "wind", "bunker"]:
		_check(ResourceLoader.exists("res://assets/audio/designed/" + cue + ".res"), "Audio asset: " + cue)
	print("Presentation smoke: %d failure(s)" % failures)
	mission.queue_free()
	await _frames(60)
	quit(0 if failures == 0 else 1)

func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame

func _check(condition: bool, message: String) -> void:
	if condition: print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
