class_name Ragdoll
extends RefCounted
## Physics-driven death poses. Joint and body constants follow the Godot
## Foundation's ragdoll demo (MIT, godot-demo-projects/3d/ragdoll_physics),
## rescaled to this rig's bone lengths rather than copied at their proportions.

## Per-joint swing and twist in degrees. One shared cone made every joint equally
## free, so knees bent sideways and elbows spun: that reads as a contorted body,
## not a dead one. Knee and elbow cones get almost no swing or twist; the neck
## and spine stay tight while shoulders and hips keep a useful range.
const JOINT_LIMITS: Dictionary[StringName, Vector2] = {
	&"Spine": Vector2(12.0, 6.0),
	&"Chest": Vector2(10.0, 6.0),
	&"Neck": Vector2(14.0, 8.0),
	&"Head": Vector2(18.0, 10.0),
	&"LeftThigh": Vector2(36.0, 10.0),
	&"RightThigh": Vector2(36.0, 10.0),
	&"LeftFoot": Vector2(16.0, 6.0),
	&"RightFoot": Vector2(16.0, 6.0),
	&"LeftHand": Vector2(20.0, 8.0),
	&"RightHand": Vector2(20.0, 8.0),
	&"LeftShin": Vector2(8.0, 2.0),
	&"RightShin": Vector2(8.0, 2.0),
	&"LeftUpperArm": Vector2(62.0, 22.0),
	&"RightUpperArm": Vector2(62.0, 22.0),
	&"LeftForearm": Vector2(16.0, 6.0),
	&"RightForearm": Vector2(16.0, 6.0),
}
const DEFAULT_LIMIT: Vector2 = Vector2(20.0, 20.0)
const FRICTION: float = 0.6
## The demo's 0.8 bounce suits a toy mannequin dropped for show; a body hitting
## forest floor should not rebound, so limbs are kept nearly dead.
const BOUNCE: float = 0.05
## Corpses must not block movement, bullets or each other, so they occupy a
## layer nothing queries. 1 is world geometry, which they do need to rest on.
const RAGDOLL_LAYER: int = 1 << 8
## Explicit damping: joint solvers leak energy into a chain this long, and a
## corpse that keeps twitching reads worse than one that settles a little fast.
const LINEAR_DAMP: float = 0.8
const ANGULAR_DAMP: float = 1.25

## Branching bones need an anatomical successor. Picking the longest child made
## the chest capsule point toward a shoulder because the upper arms start
## farther away than the neck; that put the torso's collision shape sideways
## and encouraged the whole chain to fold around it.
const BONE_TAILS: Dictionary[StringName, StringName] = {
	&"Hips": &"Spine",
	&"Spine": &"Chest",
	&"Chest": &"Neck",
	&"Neck": &"Head",
	&"LeftThigh": &"LeftShin",
	&"RightThigh": &"RightShin",
	&"LeftShin": &"LeftFoot",
	&"RightShin": &"RightFoot",
	&"LeftUpperArm": &"LeftForearm",
	&"RightUpperArm": &"RightForearm",
	&"LeftForearm": &"LeftHand",
	&"RightForearm": &"RightHand",
}
const LEAF_AXES: Dictionary[StringName, Vector3] = {
	&"Head": Vector3.UP,
	&"LeftFoot": Vector3.FORWARD,
	&"RightFoot": Vector3.FORWARD,
}
const LEAF_LENGTHS: Dictionary[StringName, float] = {
	&"Head": 0.18,
	&"LeftFoot": 0.25,
	&"RightFoot": 0.25,
	&"LeftHand": 0.12,
	&"RightHand": 0.12,
}

## radius as a fraction of bone length, mass in kg. A 75 kg soldier, distributed
## the way a body actually is: torso heavy, extremities light.
## radius in metres, mass in kg, and how much of the bone length the capsule
## spans. Shortening each capsule leaves a gap at the joints so neighbouring
## bodies do not start interpenetrating, which is what made the solver explode.
## radius in metres, mass in kg, and how much of the bone length the capsule
## spans. Every bone in the rig gets a body: an unsimulated bone keeps its
## standing pose while its parent falls away, which tears the mesh apart.
const PARTS: Dictionary[StringName, Array] = {
	&"Hips": [0.115, 11.0, 0.70],
	&"Spine": [0.105, 9.0, 0.70],
	&"Chest": [0.125, 14.0, 0.70],
	&"Neck": [0.055, 1.5, 0.70],
	&"Head": [0.095, 4.5, 0.70],
	&"LeftThigh": [0.080, 7.5, 0.72],
	&"RightThigh": [0.080, 7.5, 0.72],
	&"LeftShin": [0.062, 3.5, 0.75],
	&"RightShin": [0.062, 3.5, 0.75],
	&"LeftFoot": [0.045, 1.0, 0.70],
	&"RightFoot": [0.045, 1.0, 0.70],
	&"LeftUpperArm": [0.052, 3.2, 0.72],
	&"RightUpperArm": [0.052, 3.2, 0.72],
	&"LeftForearm": [0.045, 2.4, 0.75],
	&"RightForearm": [0.045, 2.4, 0.75],
	&"LeftHand": [0.038, 0.9, 0.70],
	&"RightHand": [0.038, 0.9, 0.70],
}

static func build(skeleton: Skeleton3D) -> PhysicalBoneSimulator3D:
	## Returns a simulator parented to the skeleton, bones created but inert.
	var simulator: PhysicalBoneSimulator3D = PhysicalBoneSimulator3D.new()
	simulator.name = "RagdollSimulator"
	skeleton.add_child(simulator)
	for bone_name: StringName in PARTS:
		var index: int = skeleton.find_bone(bone_name)
		if index < 0: continue
		_add_bone(simulator, skeleton, index, bone_name)
	return simulator

static func _add_bone(simulator: PhysicalBoneSimulator3D, skeleton: Skeleton3D, index: int, bone_name: StringName) -> void:
	var spec: Array = PARTS[bone_name]
	# Direction to the child bone in the skeleton's own space. The rig poses arms
	# across the chest for a rifle carry, so assuming every bone runs down local
	# -Y wedges the forearms inside the torso and the solver ejects them.
	var axis: Vector3 = _bone_axis(skeleton, index, bone_name)
	var length: float = _bone_length(skeleton, index, bone_name)
	var bone: PhysicalBone3D = PhysicalBone3D.new()
	bone.name = "Physical " + str(bone_name)
	bone.bone_name = str(bone_name)
	bone.mass = float(spec[1])
	bone.friction = FRICTION
	bone.linear_damp_mode = PhysicalBone3D.DAMP_MODE_REPLACE
	bone.angular_damp_mode = PhysicalBone3D.DAMP_MODE_REPLACE
	bone.linear_damp = LINEAR_DAMP
	bone.angular_damp = ANGULAR_DAMP
	bone.bounce = BOUNCE
	bone.collision_layer = RAGDOLL_LAYER
	# World geometry only. Masking the ragdoll layer made every bone collide with
	# its own neighbours, and since a chest and an upper arm capsule necessarily
	# overlap, the solver levered the arms away from the body and held them up.
	bone.collision_mask = 1
	# Hips are the root: a joint there would anchor the corpse to nothing.
	if skeleton.get_bone_parent(index) >= 0 and bone_name != &"Hips":
		bone.joint_type = PhysicalBone3D.JOINT_TYPE_CONE
		var limit: Vector2 = JOINT_LIMITS.get(bone_name, DEFAULT_LIMIT)
		bone.set("joint_constraints/swing_span", limit.x)
		bone.set("joint_constraints/twist_span", limit.y)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = float(spec[0])
	# Capsule height includes the hemispherical caps, so it cannot be shorter
	# than the diameter or Godot silently clamps it and the limb inflates.
	capsule.height = maxf(capsule.radius * 2.0 + 0.01, length * float(spec[2]))
	shape.shape = capsule
	bone.add_child(shape)
	# A capsule's own long axis is +Y, so rotate it onto the bone direction and
	# slide the body to the bone's midpoint. The joint stays at the bone head.
	var half: Vector3 = axis * (length * 0.5)
	bone.body_offset = Transform3D(_basis_for(axis), half)
	# joint_offset is expressed in the physical body's local frame. Its +Y has
	# already been rotated onto `axis` by body_offset, so using `-half` here
	# rotates the direction a second time (and puts leg joints at the ankle end).
	bone.joint_offset = Transform3D(Basis.IDENTITY, Vector3(0.0,-length*0.5,0.0))
	# A cone-twist constrains around the joint's OWN axis. Without this the cone
	# always pointed along default +Y, so a knee's narrow limit was applied
	# sideways to the shin and constrained nothing that mattered.
	bone.joint_rotation = _basis_for(axis).get_euler()
	# PhysicalBone3D creates its physics joint when it enters the tree. Every
	# offset and constraint must be ready first; changing body_offset afterward
	# moves the capsule but leaves the already-created joint at its default frame.
	simulator.add_child(bone)

static func _bone_axis(skeleton: Skeleton3D, index: int, bone_name: StringName) -> Vector3:
	## Unit vector from this bone's head toward its anatomical tail.
	var here: Vector3 = skeleton.get_bone_global_rest(index).origin
	if BONE_TAILS.has(bone_name):
		var tail: int = skeleton.find_bone(BONE_TAILS[bone_name])
		if tail >= 0:
			var offset: Vector3 = skeleton.get_bone_global_rest(tail).origin - here
			if offset.length() > 0.01: return offset.normalized()
	if LEAF_AXES.has(bone_name): return LEAF_AXES[bone_name]
	var parent: int = skeleton.get_bone_parent(index)
	if parent >= 0:
		var continuation: Vector3 = here - skeleton.get_bone_global_rest(parent).origin
		if continuation.length() > 0.01: return continuation.normalized()
	return Vector3.DOWN

static func _basis_for(axis: Vector3) -> Basis:
	## Rotation taking a capsule's +Y long axis onto the bone direction.
	var up: Vector3 = Vector3.UP
	if absf(up.dot(axis)) > 0.999: return Basis.IDENTITY if axis.y > 0.0 else Basis(Vector3.RIGHT, PI)
	return Basis(up.cross(axis).normalized(), up.angle_to(axis))

static func _bone_length(skeleton: Skeleton3D, index: int, bone_name: StringName) -> float:
	## Distance to the anatomical successor, with measured leaf proportions.
	var here: Vector3 = skeleton.get_bone_global_rest(index).origin
	if BONE_TAILS.has(bone_name):
		var tail: int = skeleton.find_bone(BONE_TAILS[bone_name])
		if tail >= 0:
			var length: float = here.distance_to(skeleton.get_bone_global_rest(tail).origin)
			if length > 0.01: return length
	return LEAF_LENGTHS.get(bone_name, 0.14)

static func start(simulator: PhysicalBoneSimulator3D, impulse: Vector3) -> void:
	simulator.physical_bones_start_simulation()
	if impulse.is_zero_approx(): return
	for child: Node in simulator.get_children():
		if child is PhysicalBone3D: child.apply_central_impulse(impulse * child.mass)
