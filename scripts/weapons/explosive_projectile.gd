class_name ExplosiveProjectile
extends RigidBody3D

var data: WeaponData
var source: CollisionObject3D
var _remaining: float = 8.0
var _detonated: bool = false


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
	var burst: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	burst.mesh = sphere
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.65, 0.22)
	burst.material_override = material
	get_tree().current_scene.add_child(burst)
	burst.global_position = global_position
	var tween: Tween = burst.create_tween()
	tween.tween_property(burst, "scale", Vector3.ONE * data.blast_radius * 2.0, 0.22)
	tween.parallel().tween_property(burst, "transparency", 1.0, 0.3)
	tween.tween_callback(burst.queue_free)
	queue_free()
