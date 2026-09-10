class_name DamageReceiver
extends Node
## Binds health to any collision body, including moving CharacterBody3D actors.

@export var health: HealthComponent
@export var body: CollisionObject3D
@export_range(0.0, 10.0) var damage_multiplier: float = 1.0


func _ready() -> void:
	assert(body != null and health != null, "DamageReceiver requires a body and health")
	body.set_meta(&"damage_receiver", self)


static func from_body(collider: Object) -> DamageReceiver:
	if not is_instance_valid(collider) or not collider.has_meta(&"damage_receiver"):
		return null
	return collider.get_meta(&"damage_receiver") as DamageReceiver


func take_damage(amount: float) -> void:
	if is_instance_valid(health):
		health.take_damage(amount * damage_multiplier)
