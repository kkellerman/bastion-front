class_name PlayerLean
extends Node
## Tactical lean. The head slides sideways and rolls, so the player can clear a
## corner without stepping into it. A wall check stops the camera passing through
## cover, which would otherwise let you see through it.

## Metres the head shifts and degrees it rolls at full lean.
const OFFSET: float = 0.45
const ROLL: float = 12.0
const SPEED: float = 9.0
## Leaning while crouched is steadier, so it gives up less accuracy.
const STANDING_PENALTY: float = 1.0
const CROUCH_PENALTY: float = 0.45

@export var player: CharacterBody3D
@export var head: Node3D

## 0 when upright, 1 at full lean. Weapons read this for the accuracy cost.
var amount: float = 0.0
var _target: float = 0.0
var _probe: ShapeCast3D

func _ready() -> void:
	# A sphere swept sideways from the head: cheap, and it cannot tunnel through
	# thin cover the way a ray between two frames can.
	_probe = ShapeCast3D.new()
	var ball: SphereShape3D = SphereShape3D.new()
	ball.radius = 0.22
	_probe.shape = ball
	_probe.enabled = true
	_probe.collision_mask = 1
	_probe.add_exception(player)
	head.add_child(_probe)

func _physics_process(delta: float) -> void:
	var accepts_input: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var wants: float = 0.0
	if accepts_input:
		wants = Input.get_action_strength("lean_right") - Input.get_action_strength("lean_left")
	# Sprinting with a shoulder out reads as wrong and would let players peek at
	# full speed, so the lean folds away while sprinting.
	if player.velocity.length() > player.walk_speed + 0.5: wants = 0.0
	_target = clampf(wants, -1.0, 1.0)
	var blocked: float = _clearance(_target)
	amount = move_toward(amount, _target * blocked, SPEED * delta * maxf(0.2, absf(_target - amount)))
	head.position.x = amount * OFFSET
	head.rotation.z = deg_to_rad(-amount * ROLL)

func _clearance(direction: float) -> float:
	## How much of the intended lean actually fits before hitting cover.
	if is_zero_approx(direction): return 1.0
	_probe.position = Vector3.ZERO
	_probe.target_position = Vector3(signf(direction) * OFFSET, 0.0, 0.0)
	_probe.force_shapecast_update()
	return _probe.get_closest_collision_safe_fraction() if _probe.is_colliding() else 1.0

func accuracy_penalty() -> float:
	## 0 when upright, rising with lean. Standing costs more than crouched.
	var stance: float = CROUCH_PENALTY if player.is_crouching else STANDING_PENALTY
	return absf(amount) * stance
