class_name ProjectileLauncher
extends RefCounted


static func launch(data: WeaponData, origin: Node3D, shooter: CollisionObject3D) -> ExplosiveProjectile:
	if not is_instance_valid(shooter) or not shooter.get_node("/root/CombatAudio").can_emit(shooter): return null
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
		# A consistent throw angle above the aim ray, like a real lob, rather than a
		# fixed vertical nudge (which flew flat) or targeting a fixed point (which put
		# a full-strength throw within the grenade's own blast radius of the thrower).
		var throw_direction: Vector3 = (direction + Vector3.UP * 0.5).normalized()
		projectile.linear_velocity = throw_direction * data.projectile_speed
	# Tumble rather than glide: a spin roughly transverse to the flight path, biased by
	# a plausible throw/launch axis rather than a single fixed spin.
	var spin_axis: Vector3 = direction.cross(Vector3.UP)
	if spin_axis.length_squared() < 0.01:
		spin_axis = Vector3.RIGHT
	projectile.angular_velocity = spin_axis.normalized() * randf_range(6.0, 11.0) * (1.0 if randf() < 0.5 else -1.0)
	return projectile
