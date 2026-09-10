class_name HitscanShot
extends Node

signal impact(position: Vector3, normal: Vector3)


func fire(data: WeaponData, camera: Node3D, muzzle: Node3D, shooter: CollisionObject3D, aiming: bool) -> void:
	var direction: Vector3 = -camera.global_basis.z
	var spread_radians: float = deg_to_rad(data.spread * (0.25 if aiming else 1.0))
	var radius: float = sqrt(randf()) * tan(spread_radians)
	var angle: float = randf() * TAU
	direction = (direction + camera.global_basis.x * cos(angle) * radius + camera.global_basis.y * sin(angle) * radius).normalized()
	var end: Vector3 = camera.global_position + direction * data.effective_range
	var aim_hit: Dictionary = _trace(camera, shooter, camera.global_position, end)
	if not aim_hit.is_empty():
		end = aim_hit["position"]
	# Check the barrel path too, so a clear camera cannot shoot through nearby cover.
	var hit: Dictionary = _trace(camera, shooter, camera.global_position, muzzle.global_position)
	if hit.is_empty():
		hit = _trace(camera, shooter, muzzle.global_position, end + direction * 0.01)
	if hit.is_empty():
		hit = aim_hit
	if hit.is_empty():
		return
	var receiver: DamageReceiver = DamageReceiver.from_body(hit["collider"])
	if receiver != null:
		receiver.take_damage(data.damage, shooter)
	impact.emit(hit["position"], hit["normal"])
	var surface: StringName = hit["collider"].get_meta(&"surface", &"dirt")
	get_node("/root/CombatAudio").play(StringName("impact_" + str(surface)), hit["position"])


func _trace(camera: Node3D, shooter: CollisionObject3D, start: Vector3, end: Vector3) -> Dictionary:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, end, 7, [shooter.get_rid()])
	query.hit_from_inside = true
	return camera.get_world_3d().direct_space_state.intersect_ray(query)
