class_name WeaponBase
extends Node

signal shot_fired
signal ammo_changed(magazine: int, reserve: int)
signal reload_changed(active: bool)

@export var data: WeaponData

var magazine: int = 0
var ammo_pool: AmmoPool
var _reserve: int = 0
var reserve: int:
	get:
		return ammo_pool.get_amount(data.reserve_ammo_type) if ammo_pool != null else _reserve
	set(value):
		if ammo_pool != null:
			ammo_pool.set_amount(data.reserve_ammo_type, value)
		else:
			_reserve = value
var is_reloading: bool = false
var _cooldown: float = 0.0
var _reload_remaining: float = 0.0


func _ready() -> void:
	assert(data != null, "WeaponBase requires WeaponData")
	magazine = data.magazine_capacity
	reserve = data.starting_reserve


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not is_reloading:
		return
	_reload_remaining -= delta
	if _reload_remaining <= 0.0:
		var transferred: int = mini(data.magazine_capacity - magazine, reserve)
		magazine += transferred
		reserve -= transferred
		is_reloading = false
		ammo_changed.emit(magazine, reserve)
		reload_changed.emit(false)


func try_fire() -> bool:
	if is_reloading or magazine <= 0 or _cooldown > 0.0:
		return false
	magazine -= 1
	_cooldown = 60.0 / data.rate_of_fire
	ammo_changed.emit(magazine, reserve)
	shot_fired.emit()
	return true


func try_reload() -> bool:
	if is_reloading or magazine == data.magazine_capacity or reserve <= 0:
		return false
	is_reloading = true
	_reload_remaining = data.reload_time
	reload_changed.emit(true)
	return true
