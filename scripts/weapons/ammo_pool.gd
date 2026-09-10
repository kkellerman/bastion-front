class_name AmmoPool
extends Resource

var amounts: Dictionary[StringName, int] = {}
var capacities: Dictionary[StringName, int] = {}


func register(ammo_type: StringName, initial: int, capacity: int) -> void:
	capacities[ammo_type] = maxi(capacities.get(ammo_type, 0), capacity)
	set_amount(ammo_type, maxi(amounts.get(ammo_type, 0), initial))


func get_amount(ammo_type: StringName) -> int:
	return amounts.get(ammo_type, 0)


func set_amount(ammo_type: StringName, value: int) -> void:
	amounts[ammo_type] = clampi(value, 0, capacities.get(ammo_type, 999))
	changed.emit()


func add(ammo_type: StringName, value: int) -> int:
	var before: int = get_amount(ammo_type)
	set_amount(ammo_type, before + value)
	return get_amount(ammo_type) - before
