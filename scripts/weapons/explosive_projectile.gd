class_name ExplosiveProjectile
extends RigidBody3D

var data: WeaponData
var source: CollisionObject3D
var _remaining: float = 8.0
var _detonated: bool = false
var _contact_surface: StringName = &""
var _contact_normal: Vector3 = Vector3.UP


func _ready() -> void:
	add_to_group(&"explosive_projectiles")
	_remaining = data.fuse_time
	gravity_scale = data.projectile_gravity
	body_entered.connect(_on_contact)
	if is_instance_valid(source):
		add_collision_exception_with(source)


func _physics_process(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		detonate()


func _on_contact(_body: Node) -> void:
	if data.explode_on_contact:
		_contact_surface = _body.get_meta(&"surface", &"concrete")
		_contact_normal = -linear_velocity.normalized() if linear_velocity.length() > 0.1 else Vector3.UP
		# Physics queries and deletion run after the contact callback finishes.
		detonate.call_deferred()


func detonate() -> void:
	if _detonated:
		return
	_detonated = true
	for node: Node in get_tree().get_nodes_in_group(&"damage_receivers"):
		var receiver: DamageReceiver = node as DamageReceiver
		var point: Vector3 = receiver.center()
		var distance: float = global_position.distance_to(point)
		if distance > data.blast_radius or receiver.health.current_health <= 0.0:
			continue
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position, point, 7, [get_rid()])
		var obstruction: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		if obstruction.is_empty() or obstruction["collider"] == receiver.body:
			receiver.take_damage(data.damage * (1.0 - distance / data.blast_radius), source)
	get_node("/root/CombatAudio").play(&"explosion", global_position, source)
	var ground: Dictionary = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.1, global_position - Vector3.UP * 2, 1))
	var surface: StringName = &"dirt" if ground.is_empty() else ground.collider.get_meta(&"surface", &"dirt")
	if _contact_surface != &"": surface = _contact_surface
	CombatEffects.burst(self, global_position, _contact_normal if _contact_surface != &"" else ground.get("normal", Vector3.UP), surface, true)
	queue_free()
