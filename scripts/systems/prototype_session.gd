extends Node
## Only prototype selection persists across scene restarts; combat state does not.
var faction_id: StringName = &"allied"
var checkpoint: Dictionary = {}
var operation_seed: int = 1944

func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--operation-seed="):
			set_operation_seed(argument.trim_prefix("--operation-seed=").to_int())

func set_operation_seed(value: int) -> void:
	operation_seed = clampi(value, 0, 2147483647)
	checkpoint.clear()

func new_operation() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var next: int = rng.randi_range(0, 2147483647)
	if next == operation_seed: next = (next + 1) % 2147483647
	set_operation_seed(next)
