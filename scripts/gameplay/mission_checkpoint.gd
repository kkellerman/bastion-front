extends Node
## In-session checkpoints snapshot resources by value, never live scene objects.
var stage: int = 0
var mission: Node3D

func _ready() -> void:
	mission = get_parent()
	_restore.call_deferred()

func _physics_process(_delta: float) -> void:
	if mission.complete or mission.player.get_node("HealthComponent").current_health <= 0: return
	if stage == 0 and mission.player.position.z < -54 and mission.player.position.z > -60:
		capture(1)
	if stage < 2 and mission.objective_done: capture(2)

func capture(next_stage: int) -> void:
	stage = next_stage
	var rig: Node3D = mission.rig
	var magazines: Array[int] = []
	for weapon: WeaponBase in rig.inventory.weapons: magazines.append(weapon.magazine)
	var defeated: Array[StringName] = []
	for enemy: InfantryBrain in mission.get_node("Enemies").get_children():
		if enemy.health.current_health <= 0: defeated.append(enemy.name)
	get_node("/root/PrototypeSession").checkpoint = {
		"scene": mission.scene_file_path, "faction": rig.inventory.faction.faction_id,
		"stage": stage, "position": mission.player.position, "yaw": mission.player.rotation.y,
		"objective": mission.objective_done, "health": maxf(50, mission.player.get_node("HealthComponent").current_health),
		"ammo": rig.inventory.pool.amounts.duplicate(), "magazines": magazines, "slot": rig.inventory.index, "defeated": defeated}

func _restore() -> void:
	var saved: Dictionary = get_node("/root/PrototypeSession").checkpoint
	if saved.is_empty() or saved.scene != mission.scene_file_path or saved.faction != mission.rig.inventory.faction.faction_id: return
	stage = saved.stage
	mission.player.position = saved.position
	mission.player.rotation.y = saved.yaw
	mission.objective_done = saved.objective
	var health: HealthComponent = mission.player.get_node("HealthComponent")
	health.current_health = saved.health
	health.health_changed.emit(health.current_health, health.max_health)
	mission.rig.inventory.pool.amounts.assign(saved.ammo)
	for i: int in range(mission.rig.inventory.weapons.size()):
		mission.rig.inventory.weapons[i].magazine = saved.magazines[i]
	mission.rig.inventory.select(saved.slot)
	for enemy: InfantryBrain in mission.get_node("Enemies").get_children():
		if enemy.name in saved.defeated: enemy.health.take_damage(enemy.health.max_health)
	mission.rig.inventory.pool.changed.emit()
