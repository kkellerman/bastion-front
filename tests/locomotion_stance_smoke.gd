extends SceneTree
var failures: int = 0

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var mission: Node3D = load("res://scenes/missions/forest_command_post.tscn").instantiate()
	root.add_child(mission)
	current_scene = mission
	await _frames(40)
	var actor: InfantryBrain = mission.get_node("Enemies/ForestPatrol")
	var animation: Node
	for child: Node in actor.get_children():
		if child.get_script() == load("res://scripts/presentation/character_animation.gd"): animation = child
	var walking_seen: bool = false
	for i: int in range(100):
		await _frames(1)
		walking_seen = walking_seen or (animation.stride.speed > 0.1 and animation.stride.blend > 0.1)
	_check(walking_seen, "Navigation displacement drives walking pose")
	actor.tactics = null
	actor.patrol_points.clear()
	actor._set_state(InfantryBrain.State.IDLE)
	await _frames(45)
	_check(animation.stride.speed < 0.1, "Deceleration settles to idle without foot cycling")
	actor.crouching = true
	await _frames(40)
	_check(animation.motion_state == &"crouch" and animation.stride.crouch_blend > 0.95, "Crouch blends hip height and bent legs")
	_check(absf(actor.get_node("BodyCollision").shape.height - 1.58) < 0.01 and absf(actor.get_node("Eyes").position.y - 1.28) < 0.01, "Crouch collision and sight height follow presentation")
	var other: InfantryBrain = mission.get_node("Enemies/RoadGuard")
	_check(other.get_node("BodyCollision").shape.height > 1.7, "Actor stance does not mutate shared capsule resources")
	actor.crouching = false
	await _frames(40)
	_check(animation.stride.crouch_blend < 0.05, "Standing pose recovers")
	# Exercise foot adaptation on a real sloped collider outside the route.
	var slope: StaticBody3D = StaticBody3D.new()
	mission.add_child(slope)
	slope.position = Vector3(0, 0.1, 10)
	slope.rotation.z = 0.15
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(3, 0.2, 3)
	collision.shape = shape
	slope.add_child(collision)
	actor.position = Vector3(0, 0.3, 10)
	await _frames(50)
	_check(absf(animation.stride.ground_offsets.x - animation.stride.ground_offsets.y) > 0.01, "Ground rays adapt feet independently on a slope")
	actor.health.take_damage(1000)
	await _frames(110)
	var skeleton: Skeleton3D = animation.model.get_node("Skeleton3D")
	var hip_height: float = skeleton.get_bone_global_pose(skeleton.find_bone("Hips")).origin.y
	var sim: PhysicalBoneSimulator3D = skeleton.get_node_or_null("RagdollSimulator")
	if sim != null:
		for bone: Node in sim.get_children():
			if bone is PhysicalBone3D and bone.bone_name == "Hips": hip_height = skeleton.to_local(bone.global_position).y
	_check(animation.motion_state == &"death" and hip_height < 0.65, "Controlled death lowers the actual pelvis below upright stance")
	mission.queue_free()
	await _frames(5)
	print("Locomotion stance smoke: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)

func _frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func _check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1
