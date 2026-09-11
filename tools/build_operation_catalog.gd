extends SceneTree
## Explicit authored anchors, saved as inspectable native resources.
const DIRECTORY: String = "res://resources/missions/variants/"
func _initialize() -> void: _build.call_deferred()

func _build() -> void:
	DirAccess.make_dir_recursive_absolute(DIRECTORY)
	var catalog: MissionVariantCatalog = MissionVariantCatalog.new()
	var ids: Array[String] = ["staging", "forest_approach", "patrol_encounters", "fortification", "bunker", "documents", "extraction"]
	var bounds: Array[AABB] = [
		AABB(Vector3(-23,-1,10),Vector3(46,6,22)), AABB(Vector3(-23,-1,-29),Vector3(46,6,39)),
		AABB(Vector3(-23,-1,-40),Vector3(46,6,20)), AABB(Vector3(-23,-1,-59),Vector3(46,6,19)),
		AABB(Vector3(-9,-1,-70),Vector3(18,6,11)), AABB(Vector3(-9,-1,-80),Vector3(18,6,10)),
		AABB(Vector3(-20,-1,-87),Vector3(40,6,7))]
	var anchors: Array[PackedVector3Array] = [
		PackedVector3Array([Vector3(7,0,25),Vector3(17,0,27),Vector3(-21,0,28)]),
		PackedVector3Array([Vector3(7,0,-7),Vector3(-7,0,-16),Vector3(18,0,-12)]),
		PackedVector3Array([Vector3(-9,0,-24),Vector3(18,0,-33),Vector3(-15,0,-38)]),
		PackedVector3Array([Vector3(18,0,-46),Vector3(-18,0,-50),Vector3(18,0,-55)]),
		PackedVector3Array([Vector3(-7.8,0,-60.8),Vector3(7.8,0,-68.5)]),
		PackedVector3Array([Vector3(7.6,0,-76.5),Vector3(-7.6,0,-78.5)]),
		PackedVector3Array([Vector3(-7,0,-83),Vector3(9,0,-83)])]
	for i: int in range(ids.size()):
		var zone: MissionZoneData = MissionZoneData.new()
		zone.zone_id = StringName(ids[i])
		zone.bounds = bounds[i]
		for index: int in range(3 if i in [1,2] else 2):
			var option: MissionZoneOption = MissionZoneOption.new()
			option.label = ids[i] + "_" + str(index)
			option.dressing_anchors = anchors[i].duplicate()
			# Anchor positions do not jitter. The selected kit and orientation can vary.
			if i == 1 and index > 0:
				option.actor_positions[&"ForestPatrol"] = Vector3(-3 if index == 1 else 2, 0.1, -19 if index == 1 else -23)
				option.patrol_routes[&"ForestPatrol"] = PackedVector3Array([option.actor_positions[&"ForestPatrol"], Vector3(-2 if index == 1 else 2,0,-27)])
			if i == 2 and index > 0:
				option.restricted_flank = index == 2
				option.actor_positions[&"RoadGuard"] = Vector3(-2 if index == 1 else 2,0.1,-32)
				option.patrol_routes[&"RoadGuard"] = PackedVector3Array([option.actor_positions[&"RoadGuard"],Vector3(-2 if index == 1 else 2,0,-37)])
				option.supply_positions[&"ForwardAmmo"] = Vector3(7,0,-32 if index == 1 else -38)
				option.supply_positions[&"ForwardHealth"] = Vector3(8,0,-32 if index == 1 else -38)
				option.supply_positions[&"ForwardGrenades"] = Vector3(9,0,-32 if index == 1 else -38)
			if i == 3 and index == 1:
				option.actor_positions[&"PerimeterGuard"] = Vector3(8,0.1,-46)
			if i == 4 and index == 1:
				option.actor_positions[&"RadioGuard"] = Vector3(3,0.1,-66)
				option.supply_positions[&"BunkerHealth"] = Vector3(6,0,-62)
			zone.options.append(option)
		ResourceSaver.save(zone, DIRECTORY + ids[i] + ".tres")
		catalog.zones.append(zone)
	ResourceSaver.save(catalog, DIRECTORY + "forest_command_post.tres")
	print("Saved seven authored zones and sixteen options; validate with operation_variants_smoke.gd")
	quit()
