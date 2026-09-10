extends CanvasLayer

var _weapon: WeaponBase
@onready var ammo_label: Label = $Ammo


func bind(weapon: WeaponBase) -> void:
	if is_instance_valid(_weapon) and _weapon.ammo_changed.is_connected(_on_ammo):
		_weapon.ammo_changed.disconnect(_on_ammo)
		_weapon.reload_changed.disconnect(_on_reload)
	_weapon = weapon
	weapon.ammo_changed.connect(_on_ammo)
	weapon.reload_changed.connect(_on_reload)
	_refresh()


func _process(_delta: float) -> void:
	if is_instance_valid(_weapon):
		_refresh()


func _on_ammo(_magazine: int, _reserve: int) -> void:
	_refresh()


func _on_reload(_active: bool) -> void:
	_refresh()


func _refresh() -> void:
	var status: String = ""
	if _weapon.is_reloading:
		status = "\nReloading..."
	elif _weapon.magazine == 0:
		status = "\nR to reload" if _weapon.reserve > 0 else "\nOut of ammunition"
	ammo_label.text = "%s   %d / %d%s" % [_weapon.data.display_name, _weapon.magazine, _weapon.reserve, status]
