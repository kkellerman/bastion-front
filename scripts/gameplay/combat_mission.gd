extends Node3D

@export var data: MissionData
@export var allied: FactionData
@export var german: FactionData
var objective_done: bool = false
var complete: bool = false
@onready var player: FirstPersonPlayer = $Player
@onready var status: Label = $MissionUI/Status
@onready var rig: Node3D = $Player/Head/Camera3D/WeaponRig


func _ready() -> void:
	var chosen: FactionData = german if get_node("/root/PrototypeSession").faction_id == german.faction_id else allied
	var opposing: FactionData = allied if chosen == german else german
	rig.inventory.configure(chosen)
	player.get_node("DamageReceiver").set_faction(chosen)
	var variation: int = 0
	for node: Node in $Enemies.get_children():
		var enemy: InfantryBrain = node as InfantryBrain
		enemy.get_node("DamageReceiver").set_faction(opposing)
		enemy.hearing_enabled = true
		enemy.combat.burst_control = true
		enemy.motor.move_speed = 2.4 + float(variation % 3) * 0.3
		enemy.alert_delay = 0.6 + float(variation % 3) * 0.12
		var weapon_data: WeaponData = opposing.weapons[variation % (opposing.weapons.size() - 1)].duplicate() as WeaponData
		weapon_data.damage = 8.0
		weapon_data.spread = 2.0
		enemy.combat.weapon.data = weapon_data
		enemy.combat.weapon.magazine = weapon_data.magazine_capacity
		enemy.combat.weapon.reserve = weapon_data.starting_reserve
		variation += 1
	$Enemies/Gunner.motor.move_speed = 0.0
	$Enemies/Gunner.combat.enabled = false
	$Enemies/Gunner.combat.firing_distance = 24.0
	for point: Node in $Interactions.get_children():
		point.activated.connect(_interact)
	$Extraction.body_entered.connect(_extract)
	var checkpoints: Node = load("res://scripts/gameplay/mission_checkpoint.gd").new()
	checkpoints.name = "Checkpoints"
	add_child(checkpoints)
	var encounters: Node = load("res://scripts/gameplay/encounter_staging.gd").new()
	add_child(encounters)
	_update_status()


func _process(_delta: float) -> void:
	if not complete:
		_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if complete and event.is_action_pressed("restart"):
		get_node("/root/PrototypeSession").checkpoint.clear()
		get_tree().reload_current_scene()
	if player.position.z >= 10.0 and player.get_node("HealthComponent").current_health > 0.0:
		if event.is_action_pressed("allied_loadout"):
			_select_faction(allied.faction_id)
		elif event.is_action_pressed("german_loadout"):
			_select_faction(german.faction_id)


func _select_faction(id: StringName) -> void:
	get_node("/root/PrototypeSession").checkpoint.clear()
	get_node("/root/PrototypeSession").faction_id = id
	get_tree().reload_current_scene()


func _interact(action: StringName, _player: CharacterBody3D) -> void:
	match action:
		&"allied": _select_faction(allied.faction_id)
		&"german": _select_faction(german.faction_id)
		&"documents":
			objective_done = true
			$Interactions/Documents.prompt = "Operations documents secured"
			_update_status()


func _extract(body: Node3D) -> void:
	if body != player or not objective_done or complete or player.get_node("HealthComponent").current_health <= 0.0:
		return
	complete = true
	status.text = "MISSION COMPLETE — documents recovered\nEnter: restart"
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	player.get_node("PlayerInteraction").process_mode = Node.PROCESS_MODE_DISABLED
	for projectile: Node in get_tree().get_nodes_in_group(&"explosive_projectiles"):
		projectile.queue_free()
	rig.process_mode = Node.PROCESS_MODE_DISABLED
	player.get_node("MouseLook").set_process_unhandled_input(false)
	for enemy: Node in $Enemies.get_children():
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	$DefensiveMG.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _update_status() -> void:
	var grenade: WeaponData = rig.inventory.faction.grenade
	status.text = "%s  ·  G %d" % ["REACH REAR EXIT" if objective_done else "RECOVER OPERATIONS DOCUMENTS", rig.inventory.pool.get_amount(grenade.reserve_ammo_type)]
	if player.position.z >= 10.0:
		status.text += "\nF1 / F2 faction  ·  F10 settings  ·  Range left"
