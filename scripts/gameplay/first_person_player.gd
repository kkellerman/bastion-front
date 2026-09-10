class_name FirstPersonPlayer
extends CharacterBody3D

@export_range(0.1, 20.0) var walk_speed: float = 4.0
@export_range(0.1, 20.0) var sprint_speed: float = 6.5
@export_range(0.1, 20.0) var crouch_speed: float = 2.0
@export_range(0.1, 50.0) var acceleration: float = 24.0
@export_range(0.1, 15.0) var jump_velocity: float = 4.5

const STANDING_HEIGHT: float = 1.8
const CROUCH_HEIGHT: float = 1.15
const STANDING_EYE_HEIGHT: float = 1.65
const CROUCH_EYE_HEIGHT: float = 1.0

var is_crouching: bool = false

@onready var body_collision: CollisionShape3D = $BodyCollision
@onready var capsule: CapsuleShape3D = body_collision.shape as CapsuleShape3D
@onready var head: Node3D = $Head
@onready var standing_clearance: ShapeCast3D = $StandingClearance


func _physics_process(delta: float) -> void:
	var accepts_input: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	_update_stance(accepts_input and Input.is_action_pressed("crouch"))
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif accepts_input and Input.is_action_just_pressed("jump") and not is_crouching:
		velocity.y = jump_velocity

	var input_direction: Vector2 = Vector2.ZERO
	if accepts_input:
		input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = global_basis * Vector3(input_direction.x, 0.0, input_direction.y)
	var speed: float = walk_speed
	if is_crouching:
		speed = crouch_speed
	elif accepts_input and Input.is_action_pressed("sprint"):
		speed = sprint_speed
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	move_and_slide()


func _update_stance(wants_crouch: bool) -> void:
	if wants_crouch == is_crouching:
		return
	if not wants_crouch:
		# Test the standing volume before growing the capsule beneath a ceiling.
		standing_clearance.force_shapecast_update()
		if standing_clearance.is_colliding():
			return
	is_crouching = wants_crouch
	var height: float = CROUCH_HEIGHT if is_crouching else STANDING_HEIGHT
	capsule.height = height
	body_collision.position.y = height * 0.5
	head.position.y = CROUCH_EYE_HEIGHT if is_crouching else STANDING_EYE_HEIGHT
