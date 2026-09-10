extends Node3D
## Input and scene composition only; ammunition and damage live in components.

@export var camera: Camera3D
@export var shooter: CollisionObject3D

@onready var weapon: WeaponBase = $WeaponBase
@onready var hitscan: HitscanShot = $HitscanShot
@onready var impact_marker: MeshInstance3D = $ImpactMarker

var viewmodel: WeaponViewModel
var inventory: WeaponInventory
var mounted: MountedWeapon
var _grenade_pending: bool = false
var _grenade_cooldown: float = 0.0
var _dry_cooldown: float = 0.0
var _fire_pending: bool = false
var _fire_held: bool = false
var _aim_held: bool = false
var _reload_pending: bool = false
var _aiming: bool = false
var _base_fov: float = 78.0
var _impact_remaining: float = 0.0


func _ready() -> void:
	assert(camera != null and shooter != null, "Weapon rig requires camera and shooter")
	inventory = WeaponInventory.new()
	add_child(inventory)
	inventory.initialize(weapon)
	inventory.selected.connect(_equip)
	shooter.set_meta(&"weapon_rig", self)
	viewmodel = weapon.data.viewmodel_scene.instantiate() as WeaponViewModel
	add_child(viewmodel)
	_base_fov = camera.fov
	weapon.shot_fired.connect(_on_shot)
	weapon.reload_changed.connect(_on_reload)
	hitscan.impact.connect(_on_impact)
	$WeaponHUD.bind(weapon)


func _input(event: InputEvent) -> void:
	# Observe capture before MouseLook handles a recapture click in _unhandled_input.
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_clear_input()
		return
	if event.is_action("fire"):
		_fire_held = event.is_pressed()
		if event.is_action_pressed("fire"):
			_fire_pending = true
	if event.is_action("aim"):
		_aim_held = event.is_pressed()
	if event.is_action_pressed("reload"):
		_reload_pending = true
	if mounted == null:
		if event.is_action_pressed("grenade"):
			_grenade_pending = true
		for slot: int in range(4):
			if event.is_action_pressed("slot_" + str(slot + 1)):
				inventory.select(slot)
		if event.is_action_pressed("next_weapon"):
			inventory.select((inventory.index + 1) % inventory.weapons.size())
		if event.is_action_pressed("previous_weapon"):
			inventory.select(posmod(inventory.index - 1, inventory.weapons.size()))


func _physics_process(delta: float) -> void:
	_grenade_cooldown = maxf(0.0, _grenade_cooldown - delta)
	_dry_cooldown = maxf(0.0, _dry_cooldown - delta)
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_clear_input()
	if mounted != null:
		if _reload_pending:
			if mounted.weapon.try_reload():
				get_node("/root/CombatAudio").play(&"reload", camera.global_position, shooter)
		if _fire_held:
			mounted.fire(camera, shooter)
		_fire_pending = false
		_reload_pending = false
		return
	if _grenade_pending:
		throw_grenade()
	_grenade_pending = false
	_aiming = _aim_held and not weapon.is_reloading
	viewmodel.aiming = _aiming
	if _reload_pending:
		weapon.try_reload()
	if _fire_pending or (weapon.data.automatic and _fire_held):
		if not weapon.try_fire() and weapon.magazine <= 0 and _dry_cooldown <= 0.0:
			get_node("/root/CombatAudio").play(&"dry", camera.global_position, shooter, weapon.data.dry_audio)
			_dry_cooldown = 0.3
	_fire_pending = false
	_reload_pending = false
	_impact_remaining = maxf(0.0, _impact_remaining - delta)
	impact_marker.visible = _impact_remaining > 0.0
	camera.fov = lerpf(camera.fov, 62.0 if _aiming else _base_fov, 1.0 - exp(-15.0 * delta))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_clear_input()


func _clear_input() -> void:
	_grenade_pending = false
	_fire_pending = false
	_fire_held = false
	_aim_held = false
	_reload_pending = false


func _on_shot() -> void:
	if weapon.data.hitscan_or_projectile == WeaponData.ShotType.HITSCAN:
		hitscan.fire(weapon.data, camera, viewmodel.muzzle, shooter, _aiming)
	else:
		ProjectileLauncher.launch(weapon.data, camera, shooter)
	viewmodel.play_shot(weapon.data)
	get_node("/root/CombatAudio").play(&"gunshot", camera.global_position, shooter, weapon.data.muzzle_audio)


func _on_reload(active: bool) -> void:
	viewmodel.set_reloading(active, weapon.data)
	if active:
		get_node("/root/CombatAudio").play(&"reload", camera.global_position, shooter, weapon.data.reload_audio)


func _on_impact(hit_position: Vector3, normal: Vector3) -> void:
	impact_marker.global_position = hit_position + normal * 0.008
	_impact_remaining = 0.18
	get_node("/root/CombatAudio").play(&"impact", hit_position)


func _equip(next: WeaponBase) -> void:
	if weapon.shot_fired.is_connected(_on_shot):
		weapon.shot_fired.disconnect(_on_shot)
		weapon.reload_changed.disconnect(_on_reload)
	weapon = next
	weapon.shot_fired.connect(_on_shot)
	weapon.reload_changed.connect(_on_reload)
	if is_instance_valid(viewmodel):
		viewmodel.queue_free()
	viewmodel = weapon.data.viewmodel_scene.instantiate() as WeaponViewModel
	add_child(viewmodel)
	$WeaponHUD.bind(weapon)
	_clear_input()


func throw_grenade() -> bool:
	if inventory.faction == null or _grenade_cooldown > 0.0 or weapon.is_reloading or mounted != null:
		return false
	var data: WeaponData = inventory.faction.grenade
	if inventory.pool.get_amount(data.reserve_ammo_type) <= 0:
		return false
	inventory.pool.add(data.reserve_ammo_type, -1)
	ProjectileLauncher.launch(data, camera, shooter)
	_grenade_cooldown = 0.8
	return true
