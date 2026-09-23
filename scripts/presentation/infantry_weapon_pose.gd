extends SkeletonModifier3D
## The firing hand owns the gun. The support arm solves to its fore-end after
## locomotion, keeping both grips together during aim, recoil and crouching.
const Grip = preload("res://scripts/presentation/weapon_grip.gd")
const Hand = preload("res://scripts/presentation/grip_hand_mesh.gd")
var actor: InfantryBrain
var data: WeaponData
var _aim_blend: float = 0.0

static func install(model: Node3D, held: Node3D, weapon: WeaponData, owner_actor: InfantryBrain = null) -> SkeletonModifier3D:
	var skeleton: Skeleton3D = model.get_node("Skeleton3D")
	held.position = -Grip.trigger(weapon)
	for left: bool in [false,true]:
		var attachment := BoneAttachment3D.new()
		attachment.name = "SupportGrip" if left else "TriggerGrip"
		attachment.bone_name = "LeftHand" if left else "RightHand"
		skeleton.add_child(attachment)
		var mesh := MeshInstance3D.new()
		var mounted: bool = is_instance_valid(owner_actor) and is_instance_valid(owner_actor.mounted_weapon)
		mesh.mesh = Hand.build(left,left and Grip.cradle(weapon) and not mounted)
		mesh.material_override = Grip.skin()
		attachment.add_child(mesh)
		# Bridge the donor's cuff to the new wrist so removing the open fingers
		# cannot expose a hole when the wrist rotates.
		var cuff := MeshInstance3D.new()
		var shape := SphereMesh.new()
		shape.radius = 0.024
		shape.height = 0.048
		shape.radial_segments = 16
		shape.rings = 8
		cuff.mesh = shape
		cuff.material_override = mesh.material_override
		attachment.add_child(cuff)
	var modifier: SkeletonModifier3D = load("res://scripts/presentation/infantry_weapon_pose.gd").new()
	modifier.name = "WeaponGripPose"
	modifier.actor = owner_actor
	modifier.data = weapon
	skeleton.add_child(modifier)
	return modifier

func _process_modification() -> void:
	if is_instance_valid(actor):
		if actor.health.current_health <= 0 or is_instance_valid(actor.mounted_weapon): return
	var skeleton: Skeleton3D = get_skeleton()
	var right_hand: int = skeleton.find_bone("RightHand")
	var right: Transform3D = skeleton.get_bone_global_pose(right_hand)
	var aiming: bool = actor.sees_target if is_instance_valid(actor) else skeleton.get_parent().get_node("AnimationPlayer").current_animation in ["aim","fire"]
	_aim_blend = move_toward(_aim_blend,1.0 if aiming else 0.0,get_process_delta_time()*5.0)
	if is_instance_valid(actor) and actor.combat.weapon.is_reloading: return
	var chest: Basis = skeleton.get_bone_global_pose(skeleton.find_bone("Chest")).basis
	_solve(skeleton,right_hand,["RightForearm","RightUpperArm"],right.origin+chest*Vector3(0,0.10,-0.035)*_aim_blend)
	var right_parent: Basis = skeleton.get_bone_global_pose(skeleton.get_bone_parent(right_hand)).basis
	skeleton.set_bone_pose_rotation(right_hand,(right_parent.inverse()*right.basis).get_rotation_quaternion())
	right = skeleton.get_bone_global_pose(right_hand)
	var target: Vector3 = right * (Grip.support(data)-Grip.trigger(data))
	var hand: int = skeleton.find_bone("LeftHand")
	_solve(skeleton,hand,["LeftForearm","LeftUpperArm"],target)
	var parent: Basis = skeleton.get_bone_global_pose(skeleton.get_bone_parent(hand)).basis
	skeleton.set_bone_pose_rotation(hand,(parent.inverse()*right.basis).get_rotation_quaternion())

func _solve(skeleton: Skeleton3D, hand: int, joints: Array[String], target: Vector3) -> void:
	for iteration: int in range(10):
		if skeleton.get_bone_global_pose(hand).origin.distance_to(target)<0.001: break
		for joint: String in joints:
			var bone: int = skeleton.find_bone(joint)
			var pose: Transform3D = skeleton.get_bone_global_pose(bone)
			var from: Vector3 = skeleton.get_bone_global_pose(hand).origin-pose.origin
			var to: Vector3 = target-pose.origin
			if from.length_squared()<0.00001 or to.length_squared()<0.00001: continue
			var rotation_delta := Basis(Quaternion(from.normalized(),to.normalized()))
			var parent: Basis = skeleton.get_bone_global_pose(skeleton.get_bone_parent(bone)).basis
			skeleton.set_bone_pose_rotation(bone,(parent.inverse()*rotation_delta*pose.basis).get_rotation_quaternion())
