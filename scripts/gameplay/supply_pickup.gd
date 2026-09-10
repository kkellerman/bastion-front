extends Area3D
enum Kind { HEALTH, AMMO, GRENADES }
@export var kind: Kind = Kind.AMMO
@export var amount: int = 40
@export var respawn_seconds: float = 25.0
var _cooldown: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	visible = _cooldown <= 0.0
	if not visible:
		return
	for body: Node3D in get_overlapping_bodies():
		if collect(body):
			break


func collect(body: Node3D) -> bool:
	if _cooldown > 0.0 or not body.has_meta(&"weapon_rig"):
		return false
	var health: HealthComponent = body.get_node("HealthComponent") as HealthComponent
	if health.current_health <= 0.0:
		return false
	var rig: Node3D = body.get_meta(&"weapon_rig") as Node3D
	var gained: int = 0
	if kind == Kind.HEALTH:
		gained = mini(amount, int(health.max_health - health.current_health))
		if gained > 0:
			health.current_health += gained
			health.health_changed.emit(health.current_health, health.max_health)
	elif rig.inventory.pool != null:
		if kind == Kind.GRENADES:
			gained = rig.inventory.pool.add(rig.inventory.faction.grenade.reserve_ammo_type, 3)
		else:
			var handled: Array[StringName] = []
			for item: WeaponBase in rig.inventory.weapons:
				var ammo_type: StringName = item.data.reserve_ammo_type
				if ammo_type not in handled:
					gained += rig.inventory.pool.add(ammo_type, 2 if item.data.weapon_class == &"launcher" else amount)
					handled.append(ammo_type)
	if gained <= 0:
		return false
	_cooldown = respawn_seconds
	visible = false
	return true
