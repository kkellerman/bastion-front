class_name WeaponInventory
extends Node

signal selected(weapon: WeaponBase)
var weapons: Array[WeaponBase] = []
var pool: AmmoPool
var faction: FactionData
var index: int = 0


func initialize(first: WeaponBase) -> void:
	weapons = [first]


func configure(data: FactionData) -> void:
	faction = data
	pool = AmmoPool.new()
	var first: WeaponBase = weapons[0]
	for old: WeaponBase in weapons.slice(1):
		old.queue_free()
	weapons.clear()
	for entry: WeaponData in data.weapons:
		var item: WeaponBase = first if weapons.is_empty() else WeaponBase.new()
		item.ammo_pool = null
		item.data = entry
		item.magazine = entry.magazine_capacity
		item.is_reloading = false
		item._cooldown = 0.0
		if item != first:
			add_child(item)
		pool.register(entry.reserve_ammo_type, entry.starting_reserve, maxi(entry.starting_reserve * 3, entry.magazine_capacity * 5))
		item.ammo_pool = pool
		weapons.append(item)
	pool.register(data.grenade.reserve_ammo_type, 3, 8)
	index = 0
	selected.emit(first)


func select(slot: int) -> bool:
	if slot < 0 or slot >= weapons.size() or weapons[index].is_reloading:
		return false
	index = slot
	selected.emit(weapons[index])
	return true
