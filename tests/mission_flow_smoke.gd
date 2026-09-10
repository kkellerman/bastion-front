extends SceneTree
var failures: int = 0
var player: FirstPersonPlayer


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("This input and walking test requires a display.")
		quit(1)
		return
	var main: Node3D = (load("res://scenes/missions/forest_command_post.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	current_scene = main
	await _frames(15)
	_key(KEY_F2)
	await _frames(15)
	_check(root.get_node("PrototypeSession").faction_id == &"german", "F2 selects German loadout and restarts")
	_check(current_scene.get_node("Player/Head/Camera3D/WeaponRig").inventory.weapons.size() == 4, "German restart equips four correct weapon slots")
	_key(KEY_F1)
	await _frames(15)
	main = current_scene as Node3D
	player = main.get_node("Player") as FirstPersonPlayer
	var rig: Node3D = player.get_node("Head/Camera3D/WeaponRig") as Node3D
	_check(rig.inventory.weapons.size() == 3, "F1 restores Allied loadout")
	for enemy: Node in main.get_node("Enemies").get_children():
		enemy.get_node("HealthComponent").take_damage(1000)
	await _frames(3)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_key(KEY_2)
	await _frames(3)
	_check(rig.weapon.data.weapon_id == &"thompson", "2 equips Thompson through player input")
	var before: int = rig.weapon.magazine
	_button(MOUSE_BUTTON_LEFT, true)
	await _frames(36)
	_button(MOUSE_BUTTON_LEFT, false)
	_check(rig.weapon.magazine < before - 2, "Holding fire repeats automatic weapon shots")
	_button(MOUSE_BUTTON_WHEEL_UP, true)
	_button(MOUSE_BUTTON_WHEEL_UP, false)
	await _frames(3)
	_check(rig.weapon.data.weapon_id == &"m1911", "Mouse wheel switches weapons")
	var grenades: int = rig.inventory.pool.get_amount(&"mk2")
	_key(KEY_G)
	await _frames(3)
	_check(rig.inventory.pool.get_amount(&"mk2") == grenades - 1, "G throws the faction grenade")
	_check(await _walk(Vector3(-18, 0, 13)), "Player walks from staging to combat range")
	_aim(main.get_node("RangeM1919/Pivot").global_position)
	await _frames(3)
	_key(KEY_E)
	await _frames(3)
	_check(rig.mounted == main.get_node("RangeM1919"), "E mounts the aimed-at gun using its interaction area")
	_key(KEY_E)
	await _frames(3)
	_check(rig.mounted == null and player.is_physics_processing(), "E dismounts and restores movement")
	_check(await _walk(Vector3(0, 0, -56)), "Player physically traverses forest and trench approach")
	await _capture("mission_bunker_approach.png")
	_check(await _walk(Vector3(-5, 0, -72.5)), "Player walks through bunker entrance and operations doorway")
	_aim(main.get_node("Interactions/Documents").global_position + Vector3(0, 0.8, 0))
	await _frames(3)
	_key(KEY_E)
	await _frames(3)
	_check(main.objective_done, "E recovers documents through the camera interaction ray")
	await _capture("mission_documents.png")
	_check(await _walk(Vector3(0, 0, -84)), "Player walks out through the rear exit")
	await _frames(5)
	_check(main.complete, "Walking into extraction completes the playable mission")
	_key(KEY_ENTER)
	await _frames(15)
	_check(current_scene != main and not current_scene.complete, "Enter restarts after mission completion")
	print("Mission flow smoke: %d failure(s)" % failures)
	current_scene.queue_free()
	await _frames(45)
	quit(0 if failures == 0 else 1)


func _walk(destination: Vector3) -> bool:
	var route: PackedVector3Array = NavigationServer3D.map_get_path(player.get_world_3d().navigation_map, player.global_position, destination, true)
	if route.is_empty():
		return false
	player.get_node("Head").rotation = Vector3.ZERO
	Input.action_press("move_forward")
	Input.action_press("sprint")
	for waypoint: Vector3 in route:
		var frames: int = 0
		while Vector2(player.position.x - waypoint.x, player.position.z - waypoint.z).length() > 0.25:
			var offset: Vector3 = waypoint - player.position
			Input.action_press("move_forward", clampf(Vector2(offset.x, offset.z).length() / 1.5, 0.35, 1.0))
			player.rotation.y = atan2(-offset.x, -offset.z)
			await _frames(1)
			frames += 1
			if frames >= 360 or not player.is_physics_processing():
				Input.action_release("move_forward")
				Input.action_release("sprint")
				return player.position.distance_to(destination) < 2.0
	Input.action_release("move_forward")
	Input.action_release("sprint")
	await _frames(20)
	return player.position.distance_to(destination) < 1.0


func _aim(point: Vector3) -> void:
	var offset: Vector3 = point - player.get_node("Head/Camera3D").global_position
	player.rotation.y = atan2(-offset.x, -offset.z)
	player.get_node("Head").rotation.x = atan2(offset.y, Vector2(offset.x, offset.z).length())


func _key(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	Input.parse_input_event(event)


func _button(button: MouseButton, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)


func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/validation")
	root.get_texture().get_image().save_png("res://.godot/validation/" + filename)


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
