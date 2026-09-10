class_name InfantryVision
extends Node

@export var actor: CharacterBody3D
@export var eye: Node3D
@export_range(1.0, 100.0) var visual_range: float = 24.0
@export_range(10.0, 180.0) var field_of_view: float = 100.0


func can_see(target: CollisionObject3D, aim_point: Node3D) -> bool:
	if not is_instance_valid(target) or not is_instance_valid(aim_point):
		return false
	var receiver: DamageReceiver = DamageReceiver.from_body(target)
	if receiver != null and receiver.health.current_health <= 0.0:
		return false
	var offset: Vector3 = aim_point.global_position - eye.global_position
	if offset.length() > visual_range:
		return false
	if offset.length_squared() > 0.001 and (-actor.global_basis.z).dot(offset.normalized()) < cos(deg_to_rad(field_of_view * 0.5)):
		return false
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(eye.global_position, aim_point.global_position, 7, [actor.get_rid()])
	var hit: Dictionary = actor.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit["collider"] == target
