class_name WeaponHandling
extends Node
## Owns camera pitch/yaw only; mouse look owns the head, suppression owns roll.
var rig: Node3D
var kick: Vector2 = Vector2.ZERO
var burst: float = 0.0
var inertia: Vector2 = Vector2.ZERO
var clock: float = 0.0
var _yaw: float = 0.0
var _pitch: float = 0.0

func _ready() -> void:
	rig = get_parent()
	_yaw = rig.shooter.rotation.y

func shot(data: WeaponData) -> void:
	var profile: WeaponHandlingData = data.handling
	var scale: float = 0.55 if rig._aiming else 1.0
	if rig.shooter.is_crouching: scale *= 0.8
	if get_node("/root/PlayerSettings").values.reduced_motion: scale *= 0.25
	kick.x = minf(kick.x + profile.camera_kick * scale * (1 + burst * profile.burst_growth), profile.max_climb)
	kick.y = clampf(kick.y + sin(burst * 1.7 + 0.8) * profile.lateral * scale, -0.5, 0.5)
	burst = minf(burst + 1, 10)

func _physics_process(delta: float) -> void:
	if not get_node("/root/CombatAudio").can_emit(rig.shooter): return
	if rig.mounted != null:
		reset()
		return
	var profile: WeaponHandlingData = rig.weapon.data.handling
	kick = kick.lerp(Vector2.ZERO, 1 - exp(-profile.recovery * delta))
	burst = maxf(0, burst - delta * 3)
	rig.camera.rotation.x = deg_to_rad(kick.x)
	rig.camera.rotation.y = deg_to_rad(kick.y)
	var pitch: float = rig.shooter.get_node("Head").rotation.x
	var turn: Vector2 = Vector2(angle_difference(_yaw, rig.shooter.rotation.y), pitch - _pitch) / maxf(delta, 0.001)
	_yaw = rig.shooter.rotation.y
	_pitch = pitch
	inertia = inertia.lerp(turn.limit_length(3) * profile.inertia, 1 - exp(-8 * delta))
	clock += delta

func reset() -> void:
	kick = Vector2.ZERO
	burst = 0
	rig.camera.rotation.x = 0
	rig.camera.rotation.y = 0
