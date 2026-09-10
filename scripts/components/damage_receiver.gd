class_name DamageReceiver
extends StaticBody3D
## A collidable damage surface composed with health, independent of target visuals.

@export var health: HealthComponent
@export_range(0.0, 10.0) var damage_multiplier: float = 1.0


func take_damage(amount: float) -> void:
	if is_instance_valid(health):
		health.take_damage(amount * damage_multiplier)
