extends SkeletonModifier3D
## Distance-driven legs layer over upper-body clips, without moving the AI body.
@export var stride_length: float = 1.28
@export var foot_lift: float = 0.14
var actor: InfantryBrain
var phase: float = 0.0
var blend: float = 0.0
var speed: float = 0.0
var turning: float = 0.0
var _previous: Vector3
var _yaw: float
var _bones: Dictionary[String, int] = {}
var ground_offsets: Vector2 = Vector2.ZERO
var ground_pitch: Vector2 = Vector2.ZERO
var crouch_blend: float = 0
var acceleration_lean: float = 0
var _last_speed: float = 0
var direction: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not is_instance_valid(actor) or actor.health.current_health <= 0: return
	for side: int in range(2):
		var start: Vector3 = actor.to_global(Vector3(-0.105 if side == 0 else 0.105, 0.5, 0))
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, start - Vector3.UP, 1, [actor.get_rid()])
		var hit: Dictionary = actor.get_world_3d().direct_space_state.intersect_ray(query)
		var height: float = 0
		var pitch: float = 0
		if not hit.is_empty():
			height = clampf(hit.position.y - actor.global_position.y, -0.16, 0.16)
			var normal: Vector3 = actor.global_basis.inverse() * hit.normal
			pitch = clampf(atan2(normal.z, normal.y), -0.4, 0.4)
		ground_offsets[side] = lerpf(ground_offsets[side], height, 1 - exp(-12 * delta))
		ground_pitch[side] = lerpf(ground_pitch[side], pitch, 1 - exp(-12 * delta))

func _ready() -> void:
	_previous = actor.global_position
	_yaw = actor.rotation.y
	for key: String in ["Hips", "LeftThigh", "LeftShin", "LeftFoot", "RightThigh", "RightShin", "RightFoot", "Chest"]:
		_bones[key] = get_skeleton().find_bone(key)

func _process_modification() -> void:
	if not is_instance_valid(actor) or actor.health.current_health <= 0: return
	var delta: float = maxf(get_process_delta_time(), 0.001)
	var distance: float = Vector2(actor.global_position.x - _previous.x, actor.global_position.z - _previous.z).length()
	_previous = actor.global_position
	# Teleports/checkpoints are not strides.
	if distance > 0.5: distance = 0
	speed = lerpf(speed, distance / delta, 1 - exp(-14 * delta))
	acceleration_lean = lerpf(acceleration_lean, clampf((speed - _last_speed) / delta * 0.008, -0.06, 0.06), 1 - exp(-8 * delta))
	_last_speed = speed
	direction = direction.lerp(actor.global_basis.inverse() * actor.velocity, 1 - exp(-10 * delta))
	crouch_blend = move_toward(crouch_blend, 1.0 if actor.crouching else 0.15 if is_instance_valid(actor.mounted_weapon) else 0.0, delta * 4)
	turning = lerpf(turning, angle_difference(_yaw, actor.rotation.y) / delta, 1 - exp(-10 * delta))
	_yaw = actor.rotation.y
	blend = move_toward(blend, 1.0 if speed > 0.08 or absf(turning) > 0.25 else 0.0, delta * 6)
	phase = fmod(phase + distance / stride_length + absf(turning) * delta * 0.12, 1)
	var skeleton: Skeleton3D = get_skeleton()
	var hip: Vector3 = skeleton.get_bone_rest(_bones.Hips).origin
	hip.y -= blend * (0.025 + absf(sin(phase * TAU)) * 0.02)
	hip.y -= crouch_blend * 0.22
	skeleton.set_bone_pose_position(_bones.Hips, hip)
	for side: int in range(2):
		var prefix: String = "Left" if side == 0 else "Right"
		var cycle: float = fmod(phase + side * 0.5, 1)
		# Stance foot travels backward at body speed; swing lifts forward.
		var reach: float = stride_length * 0.25
		var z: float = lerpf(-reach, reach, cycle * 2) if cycle < 0.5 else lerpf(reach, -reach, (cycle - 0.5) * 2)
		var lift: float = 0 if cycle < 0.5 else sin((cycle - 0.5) * TAU) * foot_lift
		z *= blend
		if direction.z > 0.1: z = -z
		var down: float = 0.75 - lift * blend - ground_offsets[side] - crouch_blend * 0.22
		var length: float = clampf(Vector2(z, down).length(), 0.2, 0.765)
		var thigh: float = atan2(-z, down) - acos(clampf((0.39 * 0.39 + length * length - 0.38 * 0.38) / (2 * 0.39 * length), -1, 1))
		var knee: float = PI - acos(clampf((0.39 * 0.39 + 0.38 * 0.38 - length * length) / (2 * 0.39 * 0.38), -1, 1))
		skeleton.set_bone_pose_rotation(_bones[prefix + "Thigh"], Quaternion(Vector3.RIGHT, thigh))
		skeleton.set_bone_pose_rotation(_bones[prefix + "Shin"], Quaternion(Vector3.RIGHT, knee))
		skeleton.set_bone_pose_rotation(_bones[prefix + "Foot"], Quaternion(Vector3.RIGHT, -thigh - knee + ground_pitch[side]))
	# Small upper-body pitch follows the aiming node; never rotates the AI collision.
	if actor.sees_target:
		var chest: int = _bones.Chest
		skeleton.set_bone_pose_rotation(chest, Quaternion(Vector3.RIGHT, clampf(actor.get_node("Eyes").rotation.x, -0.4, 0.4)))
	else:
		skeleton.set_bone_pose_rotation(_bones.Chest, Quaternion(Vector3.RIGHT, -acceleration_lean))
