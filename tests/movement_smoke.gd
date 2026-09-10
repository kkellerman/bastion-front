extends SceneTree
## Run with a display: godot --path . --script res://tests/movement_smoke.gd

var failures: int = 0
var player: FirstPersonPlayer


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var main: Node3D = scene.instantiate() as Node3D
	root.add_child(main)
	player = main.get_node("Player") as FirstPersonPlayer
	await _frames(45)
	_check(player.is_on_floor(), "Spawn settles on the ground")
	_check(player.position.y > -0.05, "Ground collision prevents falling through")
	for action: StringName in [&"move_forward", &"move_backward", &"move_left", &"move_right", &"sprint", &"jump", &"crouch", &"release_mouse", &"capture_mouse"]:
		_check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "Mapped input: " + action)
	if DisplayServer.get_name() == "headless":
		print("SKIP: Input-dependent checks require a display for mouse capture. Run without --headless.")
		main.queue_free()
		await process_frame
		quit(0 if failures == 0 else 1)
		return

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.action_press("move_forward")
	await _frames(35)
	_check(is_equal_approx(Vector2(player.velocity.x, player.velocity.z).length(), player.walk_speed), "Walk speed")
	Input.action_press("move_right")
	await _frames(25)
	_check(absf(Vector2(player.velocity.x, player.velocity.z).length() - player.walk_speed) < 0.02, "Diagonal movement is normalized")
	Input.action_release("move_right")
	Input.action_press("sprint")
	await _frames(25)
	_check(absf(player.velocity.z + player.sprint_speed) < 0.02, "Sprint speed")
	Input.action_release("sprint")
	Input.action_release("move_forward")
	await _frames(20)

	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	_check(not player.is_on_floor() and player.velocity.y > 0.0, "Jump leaves the ground")
	var rising_speed: float = player.velocity.y
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	_check(player.velocity.y < rising_speed, "Jump cannot repeat in the air")
	await _frames(75)
	_check(player.is_on_floor(), "Gravity returns player to the ground")

	Input.action_press("crouch")
	await _frames(2)
	player.position = Vector3(-7, 0.02, -9)
	player.velocity = Vector3.ZERO
	await _frames(5)
	Input.action_release("crouch")
	await _frames(5)
	_check(player.is_crouching, "Low roof blocks standing")
	player.position = Vector3(-7, 0.02, -5)
	await _frames(5)
	_check(not player.is_crouching, "Player stands when clearance is available")

	player.position = Vector3(7, 0.03, 1)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	await _frames(150)
	Input.action_release("move_forward")
	_check(player.is_on_floor() and player.position.y > 1.7, "Player climbs slope onto landing")
	Input.action_press("move_backward")
	await _frames(130)
	Input.action_release("move_backward")
	_check(player.is_on_floor() and player.position.y < 0.4, "Player descends slope with floor snapping")

	player.position = Vector3(0, 0.03, -32)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	await _frames(60)
	Input.action_release("move_forward")
	_check(player.position.z > -33.75 and absf(player.velocity.z) < 0.01, "Solid perimeter blocks movement")
	var ray: RayCast3D = player.get_node("Head/Camera3D/InteractionRay") as RayCast3D
	ray.force_raycast_update()
	_check(ray.is_colliding(), "Interaction ray detects world geometry")

	var look: Node = player.get_node("MouseLook")
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.screen_relative = Vector2(120, -2000)
	look._unhandled_input(motion)
	_check(player.rotation.y < 0.0, "Mouse rotates player yaw")
	var head: Node3D = player.get_node("Head") as Node3D
	_check(absf(head.rotation.x - deg_to_rad(85.0)) < 0.001, "Mouse pitch clamps comfortably")
	var escape: InputEventAction = InputEventAction.new()
	escape.action = &"release_mouse"
	escape.pressed = true
	look._unhandled_input(escape)
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Escape releases mouse")
	Input.action_press("move_backward")
	await _frames(20)
	Input.action_release("move_backward")
	_check(Vector2(player.velocity.x, player.velocity.z).length() < 0.01, "Released mouse disables movement input")
	var click: InputEventAction = InputEventAction.new()
	click.action = &"capture_mouse"
	click.pressed = true
	look._unhandled_input(click)
	_check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Click recaptures mouse")
	look.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Focus loss releases mouse")

	if DisplayServer.get_name() != "headless":
		player.position = Vector3(0, 0.03, 12)
		player.rotation = Vector3.ZERO
		head.rotation = Vector3.ZERO
		await _frames(10)
		await RenderingServer.frame_post_draw
		var screenshot: Image = root.get_texture().get_image()
		DirAccess.make_dir_recursive_absolute("res://.godot/validation")
		_check(screenshot.save_png("res://.godot/validation/sandbox.png") == OK, "Rendered capture saved")
	print("Movement smoke: %d failure(s)" % failures)
	main.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


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
