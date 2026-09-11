extends SceneTree
## Render real mission actors/projectiles; scripted setup keeps captures repeatable.
var mission: Node3D
var camera: Camera3D

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.get_node("PrototypeSession").checkpoint.clear()
	root.get_node("PlayerSettings").values.graphics_preset = 3
	mission = load("res://scenes/missions/forest_command_post.tscn").instantiate()
	root.add_child(mission)
	current_scene = mission
	await _frames(20)
	camera = mission.player.get_node("Head/Camera3D")
	mission.player.get_node("HealthComponent").max_health = 10000
	mission.player.get_node("HealthComponent").reset()
	for enemy: InfantryBrain in mission.get_node("Enemies").get_children(): enemy.set_physics_process(false)
	var actor: InfantryBrain = mission.get_node("Enemies/ForestPatrol")
	actor.position = Vector3(1, 0.02, 10)
	mission.player.position = Vector3(-2, 0.03, 16)
	mission.player.set_physics_process(false)
	_aim(actor.position + Vector3.UP)
	for frame: int in range(22):
		actor.motor.travel(Vector3(-1, 0.02, 7), 1.0 / 60)
		await _frames(1)
	await _capture("feedback_stride_a")
	for frame: int in range(12):
		actor.motor.travel(Vector3(-1, 0.02, 7), 1.0 / 60)
		await _frames(1)
	await _capture("feedback_stride_b")
	actor.rotation.y = PI
	actor.set_physics_process(true)
	actor.sees_target = true
	actor._set_state(InfantryBrain.State.ATTACK)
	_aim(actor.position + Vector3.UP)
	mission.rig.weapon.try_fire()
	actor.combat.attack(camera.global_position)
	await _capture("feedback_combat")
	actor.health.take_damage(1000)
	mission.player.position = Vector3(0, 0.03, 18)
	_aim(Vector3(0, 0.1, 13))
	mission.rig.throw_grenade()
	await _wait_explosion()
	await _frames(18)
	await _capture("feedback_grenade")
	await _frames(250)
	mission.rig.inventory.select(2)
	await _frames(20)
	_aim(Vector3(0, 0.1, 12))
	mission.rig.weapon.try_fire()
	await _wait_explosion()
	await _frames(12)
	await _capture("feedback_rocket")
	await _frames(240)
	mission.player.get_node("HealthComponent").take_damage(100000)
	await _frames(65)
	await _capture("feedback_player_death")
	mission.queue_free()
	await _frames(5)
	quit()

func _wait_explosion() -> void:
	for frame: int in range(260):
		await _frames(1)
		if not get_nodes_in_group(&"explosion_effects").is_empty():
			var effect: Node3D = get_nodes_in_group(&"explosion_effects")[0]
			# Move the observer close enough to inspect the real detonation's layers.
			mission.player.position = effect.global_position + Vector3(3, 0.1, 5)
			_aim(effect.global_position + Vector3.UP * 0.25)
			return
	push_error("Capture setup failed: no projectile explosion")
	quit(1)

func _aim(point: Vector3) -> void:
	var offset: Vector3 = point - camera.global_position
	mission.player.rotation.y = atan2(-offset.x, -offset.z)
	mission.player.get_node("Head").rotation.x = atan2(offset.y, Vector2(offset.x, offset.z).length())
	camera.rotation = Vector3.ZERO

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/" + label + ".png")
	print("Captured ", label)

func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame
