class_name ExplosiveProjectile
extends RigidBody3D

var data: WeaponData
var source: CollisionObject3D
var _remaining: float = 8.0
var _detonated: bool = false
var _contact_surface: StringName = &""
var _contact_normal: Vector3 = Vector3.UP
## Rockets (explode_on_contact) briefly accelerate after launch instead of coasting
## at muzzle velocity, and trail smoke; thrown grenades do neither.
var _motor_time: float = 0.0
var _smoke_timer: float = 0.0
const MOTOR_DURATION: float = 0.35
const MOTOR_ACCEL: float = 55.0


func _ready() -> void:
	add_to_group(&"explosive_projectiles")
	_remaining = data.fuse_time
	gravity_scale = data.projectile_gravity
	# A spinning body can settle below the sleep threshold at an unpredictable frame
	# depending on its random spin, which let contact/cleanup timing vary run to run.
	# The fuse timer frees this node well before that would matter regardless.
	sleeping = false
	can_sleep = false
	body_entered.connect(_on_contact)
	if is_instance_valid(source):
		add_collision_exception_with(source)
	if data.explode_on_contact:
		_motor_time = MOTOR_DURATION


func _physics_process(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		detonate()
		return
	if _motor_time > 0.0:
		_motor_time = maxf(0.0, _motor_time - delta)
		apply_central_force(-global_basis.z * MOTOR_ACCEL * mass)
	if data.explode_on_contact and not _detonated:
		_smoke_timer -= delta
		if _smoke_timer <= 0.0:
			_smoke_timer = 0.22
			CombatEffects.smoke(self, global_position)


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
			receiver.take_damage(data.damage * (1.0 - distance / data.blast_radius), source, data.weapon_class, global_position)
	get_node("/root/CombatAudio").play(&"explosion", global_position, source)
	var ground: Dictionary = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.1, global_position - Vector3.UP * 2, 1))
	var surface: StringName = &"dirt" if ground.is_empty() else ground.collider.get_meta(&"surface", &"dirt")
	if _contact_surface != &"": surface = _contact_surface
	CombatEffects.burst(self, global_position, _contact_normal if _contact_surface != &"" else ground.get("normal", Vector3.UP), surface, true)
	queue_free()
