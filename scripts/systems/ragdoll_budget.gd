extends Node
## Only actively simulated corpses occupy the budget. Settled poses are baked
## back into the skeleton and their physics bodies are retired.
const MAX_ACTIVE: int = 6
const SETTLE_DISTANCE: float = 0.025
const SETTLE_ANGLE: float = 0.10
const SETTLE_TIME: float = 1.5
const MAX_SIMULATE_TIME: float = 12.0
const FAR_DISTANCE: float = 28.0
const FAR_SIMULATE_TIME: float = 2.5
var _active: Array[Dictionary] = []

func allows() -> bool:
	_prune()
	return _active.size() < MAX_ACTIVE

func register(simulator: PhysicalBoneSimulator3D, actor: Node) -> void:
	_prune()
	_active.append({"sim":simulator,"actor":actor,"still":0.0,"age":0.0,"anchors":{}})

func _prune() -> void:
	_active = _active.filter(func(entry: Dictionary) -> bool: return is_instance_valid(entry.sim) and not entry.get("frozen",false))

func _physics_process(delta: float) -> void:
	_prune()
	for entry: Dictionary in _active:
		var simulator: PhysicalBoneSimulator3D = entry.sim
		entry.age = float(entry.age)+delta
		var moved: bool = false
		var reference: Vector3 = simulator.global_position
		for child: Node in simulator.get_children():
			if not child is PhysicalBone3D: continue
			reference = child.global_position
			var key: int = child.get_instance_id()
			if not entry.anchors.has(key): entry.anchors[key] = child.global_transform
			var anchor: Transform3D = entry.anchors[key]
			if anchor.origin.distance_to(child.global_position)>SETTLE_DISTANCE or anchor.basis.get_rotation_quaternion().angle_to(child.global_basis.get_rotation_quaternion())>SETTLE_ANGLE:
				moved = true
		if moved:
			entry.still = 0.0
			for child: Node in simulator.get_children():
				if child is PhysicalBone3D: entry.anchors[child.get_instance_id()] = child.global_transform
		else: entry.still = float(entry.still)+delta
		var deadline: float = MAX_SIMULATE_TIME
		var camera: Camera3D = simulator.get_viewport().get_camera_3d()
		if camera != null and camera.global_position.distance_to(reference)>FAR_DISTANCE: deadline = FAR_SIMULATE_TIME
		if float(entry.still)>=SETTLE_TIME or float(entry.age)>=deadline:
			entry.frozen = true
			_freeze.call_deferred(simulator, _capture_pose(simulator))

func _capture_pose(simulator: PhysicalBoneSimulator3D) -> Array[Transform3D]:
	var skeleton: Skeleton3D = simulator.get_parent()
	var poses: Array[Transform3D] = []
	for i: int in range(skeleton.get_bone_count()): poses.append(skeleton.get_bone_global_pose(i))
	# Sample the physical bodies directly: SkeletonModifier3D restores the input
	# pose after rendering, so get_bone_global_pose alone can return the live pose.
	for child: Node in simulator.get_children():
		if child is PhysicalBone3D:
			var index: int = skeleton.find_bone(child.bone_name)
			if index >= 0: poses[index] = skeleton.global_transform.affine_inverse()*child.global_transform*child.body_offset.affine_inverse()
	return poses

func _freeze(simulator: PhysicalBoneSimulator3D, poses: Array[Transform3D]) -> void:
	if not is_instance_valid(simulator): return
	var skeleton: Skeleton3D = simulator.get_parent() as Skeleton3D
	if skeleton == null: return
	simulator.physical_bones_stop_simulation()
	simulator.active = false
	simulator.queue_free()
	_apply_pose(skeleton,poses)
	# Let SkeletonModifier3D finish restoring its input buffer before committing
	# the permanent pose; writing during its update can be overwritten that frame.
	await get_tree().process_frame
	if not is_instance_valid(skeleton): return
	_apply_pose(skeleton,poses)

func _apply_pose(skeleton: Skeleton3D, poses: Array[Transform3D]) -> void:
	for i: int in range(poses.size()):
		var parent: int = skeleton.get_bone_parent(i)
		var local: Transform3D = poses[i] if parent < 0 else poses[parent].affine_inverse()*poses[i]
		skeleton.set_bone_pose(i,local)
