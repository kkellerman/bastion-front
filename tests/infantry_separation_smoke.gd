extends SceneTree
## Two infantry must remain distinct even when moving toward the same point.
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var mission: Node3D = load("res://scenes/missions/forest_command_post.tscn").instantiate()
	root.add_child(mission)
	current_scene = mission
	for frame: int in range(10): await physics_frame
	for enemy: InfantryBrain in mission.get_node("Enemies").get_children():
		enemy.set_physics_process(false)
	var first: InfantryBrain = mission.get_node("Enemies/ForestPatrol")
	var second: InfantryBrain = mission.get_node("Enemies/RoadGuard")
	first.position = Vector3(-2, 0.05, 5)
	second.position = Vector3(2, 0.05, 5)
	for frame: int in range(180):
		await physics_frame
		first.motor._move(Vector3.RIGHT * 2.8, 1.0 / 60.0)
		second.motor._move(Vector3.LEFT * 2.8, 1.0 / 60.0)
	print("Separation: ", first.position.distance_to(second.position))
	# Allow the physics engine's contact penetration tolerance.
	_check(first.position.distance_to(second.position) >= 0.65, "Converging soldiers retain capsule separation")
	_check(first.position.x < second.position.x, "Soldiers cannot walk through one another")
	_check(absf(first.position.x) < 1.0, "Collision still permits approach")
	second.health.take_damage(1000.0)
	for frame: int in range(90):
		await physics_frame
		first.motor._move(Vector3.RIGHT * 2.8, 1.0 / 60.0)
	_check(first.position.x > 2.0, "Dead infantry no longer block movement")
	var overlay: CanvasLayer = mission.get_node("Presentation/AudioSourceDebug")
	_check(not overlay.visible, "Audit is opt-in")
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_F9
	key.pressed = true
	overlay._input(key)
	for frame: int in range(15): await process_frame
	var panel: Label = overlay.get_child(0) as Label
	_check("ForestPatrol" in panel.text, "Audit identifies actual mission soldiers")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		_check(root.get_visible_rect().encloses(panel.get_global_rect()), "Audit panel fits the viewport")
		root.get_texture().get_image().save_png("res://.godot/validation/audio_source_debug.png")
	mission.queue_free()
	for frame: int in range(3): await process_frame
	quit(0 if failures == 0 else 1)

func _check(ok: bool, description: String) -> void:
	print("PASS: " if ok else "FAIL: ", description)
	if not ok: failures += 1
