extends Node
## Caps simultaneous ragdolls and freezes them once they stop moving. Combat is
## already the heaviest moment in a mission, so corpses must not accumulate cost.
const MAX_ACTIVE: int = 6
## A resting ragdoll still reports a few tenths of a metre per second of contact
## jitter when sampled inside the physics step, so speed alone never falls to
## zero. What actually distinguishes settled from falling is that the body stops
## descending: track the pelvis height and freeze once it has stopped dropping.
const SETTLE_DROP: float = 0.02
const SETTLE_TIME: float = 1.5
## Hard ceiling so a corpse wedged on geometry cannot simulate forever.
const MAX_SIMULATE_TIME: float = 12.0
## Beyond this distance a corpse settles on a much shorter fuse: the player
## cannot read the difference, and the simulation stops paying for itself.
const FAR_DISTANCE: float = 28.0
const FAR_SIMULATE_TIME: float = 2.5

var _active: Array[Dictionary] = []

func allows() -> bool:
	_prune()
	return _active.size() < MAX_ACTIVE

func register(simulator: PhysicalBoneSimulator3D, actor: Node) -> void:
	_prune()
	_active.append({"sim": simulator, "actor": actor, "still": 0.0})

func _prune() -> void:
	_active = _active.filter(func(entry: Dictionary) -> bool: return is_instance_valid(entry.sim))

func _physics_process(delta: float) -> void:
	if _active.is_empty(): return
	_prune()
	for entry: Dictionary in _active:
		if entry.get("frozen", false): continue
		var simulator: PhysicalBoneSimulator3D = entry.sim
		var lowest: float = INF
		for child: Node in simulator.get_children():
			if child is PhysicalBone3D: lowest = minf(lowest, child.global_position.y)
		if is_inf(lowest): continue
		entry.age = float(entry.get("age", 0.0)) + delta
		var dropped: float = float(entry.get("floor", lowest)) - lowest
		entry.floor = minf(float(entry.get("floor", lowest)), lowest)
		if dropped > SETTLE_DROP:
			entry.still = 0.0
			continue
		entry.still = float(entry.still) + delta
		var deadline: float = MAX_SIMULATE_TIME
		var camera: Camera3D = simulator.get_viewport().get_camera_3d()
		if camera != null and camera.global_position.distance_to(simulator.global_position) > FAR_DISTANCE:
			deadline = FAR_SIMULATE_TIME
		if float(entry.still) < SETTLE_TIME and float(entry.age) < deadline: continue
		# Settled. The simulator must keep owning the pose: stopping it hands the
		# skeleton back to its animation rest and the corpse stands up. Instead
		# pin every body in place, which costs nothing once the solver has no
		# velocity to integrate.
		entry.frozen = true
		for child: Node in simulator.get_children():
			if child is PhysicalBone3D:
				child.linear_velocity = Vector3.ZERO
				child.angular_velocity = Vector3.ZERO
				# Zero gravity plus full damping: nothing left to push the body.
				child.gravity_scale = 0.0
				child.linear_damp_mode = PhysicalBone3D.DAMP_MODE_REPLACE
				child.angular_damp_mode = PhysicalBone3D.DAMP_MODE_REPLACE
				child.linear_damp = 100.0
				child.angular_damp = 100.0
