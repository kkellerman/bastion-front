extends SceneTree
## Run headless for mechanics; run with a display to also verify real input/capture.

var failures: int = 0
var impact_count: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var main: Node3D = scene.instantiate() as Node3D
	root.add_child(main)
	await _frames(10)
	var rig: Node3D = main.get_node("Player/Head/Camera3D/WeaponRig") as Node3D
	var weapon: WeaponBase = rig.get_node("WeaponBase") as WeaponBase
	var health: HealthComponent = main.get_node("TestTarget/HealthComponent") as HealthComponent
	var data: WeaponData = weapon.data
	var hitscan: HitscanShot = rig.get_node("HitscanShot") as HitscanShot
	hitscan.impact.connect(func(_position: Vector3, _normal: Vector3) -> void: impact_count += 1)
	_check(weapon.magazine == 7 and weapon.reserve == 35, "Initial magazine and reserve")
	_check(not weapon.try_reload(), "Full magazine cannot reload")
	_check(weapon.try_fire(), "Loaded pistol fires")
	_check(weapon.magazine == 6 and health.current_health == 75.0, "Hitscan consumes one round and deals configured damage")
	_check(not weapon.try_fire() and weapon.magazine == 6, "Fire rate rejects immediate second shot without consuming ammo")
	_check(impact_count == 1, "Shot produces impact feedback")
	await _frames(1)
	_check(rig.viewmodel.flash.visible, "Successful shot displays muzzle flash")
	_check(rig.viewmodel.rotation.x > 0.0, "Successful shot produces viewmodel recoil")
	await _frames(5)
	_check(not rig.viewmodel.flash.visible, "Muzzle flash expires")
	for shot: int in range(3):
		await _frames(14)
		_check(weapon.try_fire(), "Fire cooldown expires")
	_check(health.current_health == 0.0, "Four pistol hits destroy target")
	var status: Label3D = main.get_node("TestTarget/Status") as Label3D
	_check(status.text.begins_with("DESTROYED"), "Target visibly reports destruction")
	_check(weapon.try_reload(), "Partial magazine reload starts")
	_check(not weapon.try_reload(), "Repeated reload does not restart timer")
	_check(not weapon.try_fire(), "Reload blocks firing")
	await _frames(40)
	_check(weapon.is_reloading and weapon.magazine == 3 and weapon.reserve == 35, "Ammo transfers only when reload completes")
	await _frames(75)
	_check(not weapon.is_reloading and weapon.magazine == 7 and weapon.reserve == 31, "Partial reload transfers only missing rounds")
	await _frames(80)
	_check(health.current_health == 100.0, "Target automatically resets")

	# A separate instance shares immutable data but must not share live ammo state.
	var second: WeaponBase = WeaponBase.new()
	second.data = data
	root.add_child(second)
	_check(second.magazine == 7 and second.reserve == 35, "Weapon instances have independent ammo")
	weapon.reserve = 2
	weapon.magazine = 0
	_check(not weapon.try_fire(), "Empty magazine cannot fire")
	_check(weapon.try_reload(), "Empty magazine accepts remaining reserve")
	await _frames(115)
	_check(weapon.magazine == 2 and weapon.reserve == 0, "Insufficient reserve creates a partial magazine without inventing ammo")
	_check(not weapon.try_reload(), "No reserve prevents reload")
	_check(data.magazine_capacity == 7 and data.starting_reserve == 35, "Shared resource stays unchanged")
	second.queue_free()

	var camera: Camera3D = main.get_node("Player/Head/Camera3D") as Camera3D
	var shooter: CollisionObject3D = main.get_node("Player") as CollisionObject3D
	var exact_data: WeaponData = data.duplicate() as WeaponData
	exact_data.spread = 0.0
	var before: float = health.current_health
	var cover: StaticBody3D = StaticBody3D.new()
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(3, 3, 0.2)
	collision.shape = shape
	cover.add_child(collision)
	main.add_child(cover)
	cover.position = Vector3(0, 1.65, 4)
	await _frames(2)
	hitscan.fire(exact_data, camera, rig.viewmodel.muzzle, shooter, false)
	_check(health.current_health == before, "Solid cover blocks target damage")
	# Camera center sees the target, but the offset pistol is behind this thin cover.
	shape.size = Vector3(0.15, 0.5, 0.04)
	cover.position = camera.global_position + Vector3(0.15, -0.15, -0.3)
	await _frames(2)
	hitscan.fire(exact_data, camera, rig.viewmodel.muzzle, shooter, false)
	_check(health.current_health == before, "Cover between camera and muzzle blocks barrel clipping exploit")
	cover.queue_free()
	await _frames(2)
	exact_data.effective_range = 2.0
	hitscan.fire(exact_data, camera, rig.viewmodel.muzzle, shooter, false)
	_check(health.current_health == before, "Hitscan obeys effective range")
	exact_data.effective_range = 80.0
	hitscan.fire(exact_data, camera, rig.viewmodel.muzzle, shooter, true)
	_check(health.current_health == before - 25.0, "Unobstructed aimed shot hits target")

	if DisplayServer.get_name() != "headless":
		weapon.magazine = 7
		weapon.reserve = 35
		health.reset()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_mouse_button(MOUSE_BUTTON_LEFT, true)
		await _frames(3)
		_check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and weapon.magazine == 7, "Recapture click does not fire")
		_mouse_button(MOUSE_BUTTON_LEFT, false)
		_mouse_button(MOUSE_BUTTON_LEFT, true)
		await _frames(3)
		_check(weapon.magazine == 6, "Real left click fires once")
		await _frames(30)
		_check(weapon.magazine == 6, "Holding trigger does not auto-fire pistol")
		_mouse_button(MOUSE_BUTTON_LEFT, false)
		_mouse_button(MOUSE_BUTTON_RIGHT, true)
		await _frames(30)
		_check(camera.fov < 63.0 and rig.viewmodel.aiming, "Right click aims and narrows FOV")
		await _capture("weapon_aim.png")
		_mouse_button(MOUSE_BUTTON_RIGHT, false)
		await _frames(25)
		_check(camera.fov > 77.0, "Releasing aim restores FOV")
		var reload_key: InputEventKey = InputEventKey.new()
		reload_key.physical_keycode = KEY_R
		reload_key.pressed = true
		Input.parse_input_event(reload_key)
		await _frames(2)
		_check(weapon.is_reloading, "R input starts reload")
		reload_key.pressed = false
		Input.parse_input_event(reload_key)
		await _frames(115)
		await _capture("weapon_sandbox.png")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		await _frames(2)
	else:
		print("SKIP: Display-dependent input and screenshot checks (run without --headless)")
	print("Weapon smoke: %d failure(s)" % failures)
	main.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _mouse_button(button: MouseButton, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)


func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/validation")
	_check(root.get_texture().get_image().save_png("res://.godot/validation/" + filename) == OK, "Saved " + filename)


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)
