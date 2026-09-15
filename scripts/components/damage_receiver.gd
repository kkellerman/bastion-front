class_name DamageReceiver
extends Node
## Binds health to any collision body, including moving CharacterBody3D actors.

@export var health: HealthComponent
@export var body: CollisionObject3D
@export_range(0.0, 10.0) var damage_multiplier: float = 1.0


func _ready() -> void:
	assert(body != null and health != null, "DamageReceiver requires a body and health")
	body.set_meta(&"damage_receiver", self)
	add_to_group(&"damage_receivers")
	if body is CharacterBody3D:
		var feedback: Node = load("res://scripts/presentation/damage_feedback.gd").new()
		feedback.name = "DamageFeedback"
		feedback.actor = body
		feedback.health = health
		add_child(feedback)


static func from_body(collider: Object) -> DamageReceiver:
	if not is_instance_valid(collider) or not collider.has_meta(&"damage_receiver"):
		return null
	return collider.get_meta(&"damage_receiver") as DamageReceiver


func take_damage(amount: float, source: CollisionObject3D = null, weapon_class: StringName = &"") -> void:
	if source != body and not FactionData.hostile(source, body):
		return
	if not is_instance_valid(health): return
	# Recorded before the damage lands, so a killing blow can push the ragdoll
	# the way the shot was travelling instead of dropping it straight down.
	if is_instance_valid(source) and body.has_method("note_hit"):
		body.note_hit(source.global_position, amount * damage_multiplier, weapon_class)
	health.take_damage(amount * damage_multiplier)


func set_faction(data: FactionData) -> void:
	body.set_meta(&"faction", data)


func center() -> Vector3:
	for child: Node in body.get_children():
		if child is CollisionShape3D:
			return (child as CollisionShape3D).global_position
	return body.global_position
