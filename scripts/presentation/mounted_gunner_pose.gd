extends SkeletonModifier3D
## Small CCD arm solve against mount grip hooks, after the locomotion modifier.
var actor: InfantryBrain

func _process_modification() -> void:
	if actor.health.current_health <= 0 or not is_instance_valid(actor.mounted_weapon): return
	var skeleton: Skeleton3D = get_skeleton()
	var mount: MountedWeapon = actor.mounted_weapon
	for side: int in [-1, 1]:
		var prefix: String = "Left" if side < 0 else "Right"
		var hand: int = skeleton.find_bone(prefix + "Hand")
		var wrist: Vector3 = Vector3(-0.041,-0.075,0.28) if side < 0 else Vector3(0.035,-0.13,0.18)
		var target: Vector3 = skeleton.to_local(mount.pivot.to_global(wrist))
		for iteration: int in range(5):
			for joint: String in ["Forearm", "UpperArm"]:
				var bone: int = skeleton.find_bone(prefix + joint)
				var pose: Transform3D = skeleton.get_bone_global_pose(bone)
				var from: Vector3 = skeleton.get_bone_global_pose(hand).origin - pose.origin
				var to: Vector3 = target - pose.origin
				if from.length_squared() < 0.0001 or to.length_squared() < 0.0001: continue
				var rotation_delta: Quaternion = Quaternion(from.normalized(), to.normalized())
				var parent: Basis = skeleton.get_bone_global_pose(skeleton.get_bone_parent(bone)).basis
				skeleton.set_bone_pose_rotation(bone, (parent.inverse() * Basis(rotation_delta) * pose.basis).get_rotation_quaternion())
		var parent_basis: Basis = skeleton.get_bone_global_pose(skeleton.get_bone_parent(hand)).basis
		var grip_basis: Basis = skeleton.global_basis.inverse()*mount.pivot.global_basis
		skeleton.set_bone_pose_rotation(hand,(parent_basis.inverse()*grip_basis).get_rotation_quaternion())
