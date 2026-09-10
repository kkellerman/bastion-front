class_name MountedWeapon
extends StaticBody3D

@export var data: WeaponData
@export var defender: InfantryBrain
@export var yaw_limit: float = 55.0
@export var pitch_limit: float = 25.0
@onready var weapon: WeaponBase = $WeaponBase
@onready var pivot: Node3D = $Pivot
@onready var muzzle: Marker3D = $Pivot/Muzzle
@onready var flash: MeshInstance3D = $Pivot/Muzzle/Flash
@onready var hitscan: HitscanShot = $HitscanShot
var occupant: CharacterBody3D
var _return_position: Vector3
var _flash_time: float = 0.0
var _npc_rest: float = 0.0
var _npc_burst: int = 4
var _npc_data: WeaponData


func _ready() -> void:
	# The child is configured in the scene; the exported resource also labels the station.
	$Label.text = data.display_name + "\nE: mount / dismount"
	_npc_data = data.duplicate() as WeaponData
	_npc_data.damage = 8.0
	$InteractionArea.set_meta(&"interactable", self)
	hitscan.impact.connect(func(point: Vector3, normal: Vector3) -> void: CombatImpact.show(self, point, normal))


func get_prompt() -> String:
	if is_instance_valid(defender) and defender.health.current_health > 0.0:
		return "Clear the gunner before mounting " + data.display_name
	return "E: mount " + data.display_name


func interact(player: CharacterBody3D) -> void:
	if occupant != null or player.is_crouching:
		return
	if is_instance_valid(defender) and defender.health.current_health > 0.0:
		return
	var rig: Node3D = player.get_meta(&"weapon_rig") as Node3D
	if rig.weapon.is_reloading:
		return
	occupant = player
	_return_position = player.global_position
	player.global_position = to_global(Vector3(0, 0, 1.1))
	player.rotation.y = global_rotation.y
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	rig.mounted = self
	rig.viewmodel.visible = false
	rig.get_node("WeaponHUD").bind(weapon)


func dismount() -> void:
	if not is_instance_valid(occupant):
		return
	var rig: Node3D = occupant.get_meta(&"weapon_rig") as Node3D
	rig.mounted = null
	rig.viewmodel.visible = true
	rig.get_node("WeaponHUD").bind(rig.weapon)
	occupant.global_position = _return_position
	if occupant.get_node("HealthComponent").current_health > 0.0:
		occupant.set_physics_process(true)
	occupant = null


func _physics_process(delta: float) -> void:
	_flash_time = maxf(0.0, _flash_time - delta)
	$Pivot/Gun.position.z = move_toward($Pivot/Gun.position.z, 0.0, delta * 0.5)
	_npc_rest = maxf(0.0, _npc_rest - delta)
	flash.visible = _flash_time > 0.0
	if is_instance_valid(occupant):
		var relative: float = wrapf(occupant.rotation.y - global_rotation.y, -PI, PI)
		occupant.rotation.y = global_rotation.y + clampf(relative, -deg_to_rad(yaw_limit), deg_to_rad(yaw_limit))
		var head: Node3D = occupant.get_node("Head") as Node3D
		head.rotation.x = clampf(head.rotation.x, -deg_to_rad(pitch_limit), deg_to_rad(pitch_limit))
		pivot.rotation = Vector3(head.rotation.x, occupant.rotation.y - global_rotation.y, 0)
	elif is_instance_valid(defender) and defender.health.current_health > 0.0 and defender.sees_target and defender.state == InfantryBrain.State.ATTACK and _npc_rest <= 0.0:
		var local_target: Vector3 = to_local(defender.target_aim.global_position)
		var yaw: float = atan2(-local_target.x, -local_target.z)
		if absf(yaw) <= deg_to_rad(yaw_limit):
			pivot.look_at(defender.target_aim.global_position, Vector3.UP)
			fire(pivot, defender)


func fire(origin: Node3D, shooter: CollisionObject3D) -> void:
	if weapon.magazine <= 0:
		weapon.try_reload()
	elif weapon.try_fire():
		hitscan.fire(data if occupant != null else _npc_data, origin, muzzle, shooter, true)
		_flash_time = 0.06
		$Pivot/Gun.position.z = 0.04
		get_node("/root/CombatAudio").play(&"mounted", muzzle.global_position, shooter, data.muzzle_audio)
		if occupant == null:
			_npc_burst -= 1
			if _npc_burst <= 0:
				_npc_burst = 4
				_npc_rest = 1.0
