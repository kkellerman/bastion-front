class_name ProjectileLauncher
extends RefCounted


static func launch(data: WeaponData, origin: Node3D, shooter: CollisionObject3D) -> ExplosiveProjectile:
	var projectile: ExplosiveProjectile = data.projectile_scene.instantiate() as ExplosiveProjectile
	projectile.data = data
	projectile.source = shooter
	var direction: Vector3 = -origin.global_basis.z
	var start: Vector3 = origin.global_position
	var end: Vector3 = start + direction * 0.7
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, end, 7, [shooter.get_rid()])
	var hit: Dictionary = origin.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		end = hit["position"] + hit["normal"] * 0.12
	shooter.get_tree().current_scene.add_child(projectile)
	projectile.global_position = end
	projectile.linear_velocity = direction * data.projectile_speed
	if not data.explode_on_contact:
		projectile.linear_velocity += Vector3.UP * 3.0
	return projectile
