class_name InfantryMotor
extends Node

@export var actor: CharacterBody3D
@export var agent: NavigationAgent3D
@export var move_speed: float = 2.8
@export var acceleration: float = 9.0
var _repath_remaining: float = 0.0


func travel(destination: Vector3, delta: float) -> bool:
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		stop(delta)
		return false
	_repath_remaining -= delta
	if _repath_remaining <= 0.0:
		agent.target_position = destination
		_repath_remaining = 0.25
	var next: Vector3 = agent.get_next_path_position()
	var offset: Vector3 = next - actor.global_position
	offset.y = 0.0
	if agent.is_navigation_finished():
		stop(delta)
		return actor.global_position.distance_to(destination) < 1.0
	var direction: Vector3 = offset.normalized()
	face(actor.global_position + direction, delta)
	_move(direction * move_speed * (0.55 if actor.crouching else 1.0), delta)
	return false


func face(point: Vector3, delta: float) -> void:
	var offset: Vector3 = point - actor.global_position
	if Vector2(offset.x, offset.z).length_squared() > 0.01:
		actor.rotation.y = lerp_angle(actor.rotation.y, atan2(-offset.x, -offset.z), minf(delta * 8.0, 1.0))


func stop(delta: float) -> void:
	_move(Vector3.ZERO, delta)


func _move(horizontal: Vector3, delta: float) -> void:
	actor.velocity.x = move_toward(actor.velocity.x, horizontal.x, acceleration * delta)
	actor.velocity.z = move_toward(actor.velocity.z, horizontal.z, acceleration * delta)
	if not actor.is_on_floor():
		actor.velocity += actor.get_gravity() * delta
	actor.move_and_slide()
