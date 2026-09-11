class_name MissionVariantCatalog
extends Resource
@export var revision: int = 1
@export var zones: Array[MissionZoneData] = []

func select(operation_seed: int) -> Array[MissionZoneOption]:
	var result: Array[MissionZoneOption] = []
	for zone: MissionZoneData in zones:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = operation_seed ^ int(zone.zone_id.hash()) ^ revision
		result.append(zone.options[0 if operation_seed == 1944 else rng.randi_range(0, zone.options.size() - 1)])
	return result

func signature(operation_seed: int) -> String:
	var labels: PackedStringArray = []
	for option: MissionZoneOption in select(operation_seed): labels.append(option.label)
	return "/".join(labels)
