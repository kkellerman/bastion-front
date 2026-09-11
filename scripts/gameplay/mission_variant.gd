class_name MissionVariant
extends Node3D
const CATALOG = preload("res://resources/missions/variants/forest_command_post.tres")
var operation_seed: int
var options: Array[MissionZoneOption] = []
var restricted_flank: bool = false
var signature: String
var combat_started: bool = false
var seed_label: Label
var _restarting: bool = false

func _ready() -> void:
	name = "MissionVariant"
	operation_seed = get_node("/root/PrototypeSession").operation_seed
	options = CATALOG.select(operation_seed)
	signature = CATALOG.signature(operation_seed)
	var mission: Node3D = get_parent()
	for i: int in range(options.size()):
		var option: MissionZoneOption = options[i]
		var zone: Node3D = Node3D.new()
		zone.name = CATALOG.zones[i].zone_id
		zone.set_meta(&"bounds", CATALOG.zones[i].bounds)
		add_child(zone)
		for id: StringName in option.actor_positions:
			var actor: InfantryBrain = mission.get_node("Enemies/" + str(id))
			actor.position = option.actor_positions[id]
		for id: StringName in option.patrol_routes:
			mission.get_node("Enemies/" + str(id)).patrol_points.assign(option.patrol_routes[id])
		for id: StringName in option.supply_positions:
			mission.get_node("Supplies/" + str(id)).position = option.supply_positions[id]
		restricted_flank = restricted_flank or option.restricted_flank
		preload("res://scripts/presentation/variant_dressing.gd").dress(zone, option, operation_seed + i * 631)
	if restricted_flank:
		add_child(preload("res://scenes/missions/variants/flank_restriction.tscn").instantiate())
		var path: String = "res://resources/missions/variants/restricted_navigation.tres"
		mission.get_node("NavigationRegion3D").navigation_mesh = load(path)
	get_node("/root/CombatAudio").noise.connect(_noise)
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	seed_label = Label.new()
	canvas.add_child(seed_label)
	seed_label.position = Vector2(24, 130)
	seed_label.add_theme_font_size_override("font_size", 14)
	seed_label.add_theme_constant_override("outline_size", 4)

func _process(_delta: float) -> void:
	if get_parent().player.position.z < 10: combat_started = true
	if get_parent().rig._grenade_cooldown > 0: combat_started = true
	seed_label.visible = can_regenerate() or Input.is_key_pressed(KEY_F9)
	seed_label.text = "OPERATION %d  /  F3 NEW OPERATION" % operation_seed if can_regenerate() else "OPERATION %d  /  VARIANT LOCKED" % operation_seed

func _noise(_point: Vector3, _radius: float, source: CollisionObject3D) -> void:
	if source == get_parent().player or source is InfantryBrain: combat_started = true

func can_regenerate() -> bool:
	var mission: Node3D = get_parent()
	return (not combat_started and not _restarting and not mission.complete
		and mission.player.position.z >= 10
		and mission.player.get_node("HealthComponent").current_health > 0
		and mission.rig.mounted == null and mission.rig._grenade_cooldown <= 0
		and not mission.rig.combat_input_pending())

func new_operation() -> bool:
	if not can_regenerate(): return false
	_restarting = true
	get_node("/root/PrototypeSession").new_operation()
	get_tree().reload_current_scene.call_deferred()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		new_operation()
