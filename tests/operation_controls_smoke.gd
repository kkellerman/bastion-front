extends SceneTree
var failures: int = 0

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var session: Node = root.get_node("PrototypeSession")
	var menu: Node3D = load("res://scenes/ui/title_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await _frames(5)
	var seed_input: SpinBox = menu.find_child("OperationSeed",true,false)
	seed_input.value = 1
	_check(session.operation_seed == 1, "Menu seed entry updates session")
	session.checkpoint = {"stage": 1}
	menu.find_child("NewOperation",true,false).pressed.emit()
	_check(session.operation_seed != 1 and session.checkpoint.is_empty() and int(seed_input.value) == session.operation_seed, "New Operation prepares seed and clears old checkpoint")
	seed_input.value = 1
	menu.find_child("MenuButton0",true,false).pressed.emit()
	await _frames(20)
	var mission: Node3D = current_scene
	_check(mission.has_node("MissionVariant") and mission.get_node("MissionVariant").restricted_flank, "Menu launches selected operation")
	_key(KEY_F3)
	await _frames(20)
	_check(current_scene != mission and session.operation_seed != 1, "F3 actually regenerates and reloads staging")
	mission = current_scene
	var seed_value: int = session.operation_seed
	_key(KEY_F9)
	await _frames(10)
	var overlay: CanvasLayer = mission.get_node("Presentation").get_children().filter(func(node: Node) -> bool: return node.get_script() == load("res://scripts/presentation/audio_source_debug.gd"))[0]
	_check(overlay.visible and str(seed_value) in overlay.panel.text, "F9 retains visible operation seed")
	_key(KEY_F9)
	var mouse: InputEventMouseButton = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	await _frames(3)
	mouse = mouse.duplicate() as InputEventMouseButton
	mouse.pressed = false
	Input.parse_input_event(mouse)
	await _frames(3)
	_check(mission.rig.weapon.magazine < mission.rig.weapon.data.magazine_capacity, "Input fires staging pistol")
	_key(KEY_F3)
	await _frames(5)
	_check(current_scene == mission and session.operation_seed == seed_value, "Gunfire prevents F3 regeneration")
	# Re-enter same seed afresh, then cross the departure line without firing.
	reload_current_scene()
	await _frames(20)
	mission = current_scene
	mission.player.position.z = 9
	await _frames(2)
	mission.player.position.z = 18
	_key(KEY_F3)
	await _frames(3)
	_check(current_scene == mission and not mission.get_node("MissionVariant").can_regenerate(), "Returning after departure does not unlock regeneration")
	reload_current_scene()
	await _frames(20)
	mission = current_scene
	var grenade_type: StringName = mission.rig.inventory.faction.grenade.reserve_ammo_type
	var grenades: int = mission.rig.inventory.pool.get_amount(grenade_type)
	_key(KEY_G)
	_key(KEY_F3)
	await _frames(3)
	_check(current_scene == mission and mission.rig.inventory.pool.get_amount(grenade_type) == grenades - 1, "Grenade and F3 in the same frame cannot bypass lock")
	current_scene.queue_free()
	await _frames(5)
	print("Operation controls smoke: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)

func _key(code: Key) -> void:
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = code
	key.pressed = true
	Input.parse_input_event(key)
	key = key.duplicate() as InputEventKey
	key.pressed = false
	Input.parse_input_event(key)

func _frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func _check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures += 1
