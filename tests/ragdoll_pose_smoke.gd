extends SceneTree

const IMPULSES: Array[Vector3] = [
	Vector3(1.2,0.7,0.0),
	Vector3(-1.0,0.8,0.5),
	Vector3(0.3,0.6,-1.3),
	Vector3(-0.4,1.1,-0.8),
]
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var floor := StaticBody3D.new()
	floor.collision_layer = 1
	floor.collision_mask = 0
	stage.add_child(floor)
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(16.0,0.2,8.0)
	floor_shape.shape = box
	floor_shape.position.y = -0.1
	floor.add_child(floor_shape)
	var simulators: Array[PhysicalBoneSimulator3D] = []
	for index: int in range(IMPULSES.size()):
		var faction: String = "allied" if index%2==0 else "german"
		var model: Node3D = load("res://assets/characters/%s/infantry_rigged.tscn"%faction).instantiate()
		stage.add_child(model)
		model.position = Vector3(-4.5+index*3.0,0.0,0.0)
		var player: AnimationPlayer = model.get_node("AnimationPlayer")
		player.play("death")
		player.advance(0.45)
		player.pause()
		var simulator: PhysicalBoneSimulator3D = Ragdoll.build(model.get_node("Skeleton3D"))
		simulators.append(simulator)
		Ragdoll.start(simulator,IMPULSES[index])
	for frame: int in range(300): await physics_frame
	for index: int in range(simulators.size()): _check_pose(simulators[index],index)
	print("Ragdoll pose smoke: %d failure(s)"%failures)
	quit(0 if failures==0 else 1)

func _check_pose(simulator: PhysicalBoneSimulator3D, scenario: int) -> void:
	var positions: Dictionary = {}
	for child: Node in simulator.get_children():
		if child is PhysicalBone3D:
			positions[child.bone_name] = (child.global_transform*child.body_offset.affine_inverse()).origin
	var feet: Vector3 = (positions.LeftFoot+positions.RightFoot)*0.5
	var length: float = positions.Head.distance_to(feet)
	var widest: float = 0.0
	for first: Vector3 in positions.values():
		for second: Vector3 in positions.values(): widest = maxf(widest,first.distance_to(second))
	_check(length>1.0,"Scenario %d keeps head and feet separated (%.3f m)"%[scenario+1,length])
	_check(widest>1.15,"Scenario %d keeps a full-body silhouette (%.3f m)"%[scenario+1,widest])
	_check(_segment_error(positions)<0.025,"Scenario %d preserves anatomical segment lengths"%(scenario+1))

func _segment_error(positions: Dictionary) -> float:
	var expected: Dictionary = {
		"Hips:Spine":0.24,"Spine:Chest":0.21,"Chest:Neck":0.12,"Neck:Head":0.12,
		"LeftThigh:LeftShin":0.39,"RightThigh:RightShin":0.39,
		"LeftShin:LeftFoot":0.38,"RightShin:RightFoot":0.38,
	}
	var worst: float = 0.0
	for pair: String in expected:
		var names: PackedStringArray = pair.split(":")
		worst = maxf(worst,absf(positions[names[0]].distance_to(positions[names[1]])-expected[pair]))
	return worst

func _check(value: bool, label: String) -> void:
	if value: print("PASS: ",label)
	else:
		failures += 1
		push_error("FAIL: "+label)
