extends Node
var actor: InfantryBrain
var model: Node3D
var player: AnimationPlayer
var _lock: float = 0.0
var _dead: bool = false
var stride: SkeletonModifier3D
var motion_state: StringName = &"idle"
## How far into the 1s death animation physics takes over. Late enough that the
## authored collapse reads, early enough that the body still falls, rather than
## snapping, onto whatever is beneath it.
const HANDOVER_DELAY: float = 0.55

func _ready() -> void:
	player = model.get_node("AnimationPlayer")
	model.get_node("AnimationTree").active = false
	stride = load("res://scripts/presentation/infantry_stride.gd").new()
	stride.actor = actor
	model.get_node("Skeleton3D").add_child(stride)
	var gunner_pose: SkeletonModifier3D = load("res://scripts/presentation/mounted_gunner_pose.gd").new()
	gunner_pose.actor = actor
	model.get_node("Skeleton3D").add_child(gunner_pose)
	actor.state_changed.connect(_state)
	var active_weapon: WeaponBase = actor.mounted_weapon.weapon if is_instance_valid(actor.mounted_weapon) else actor.combat.weapon
	active_weapon.shot_fired.connect(func() -> void: _play("fire", 0.16))
	active_weapon.reload_changed.connect(func(active: bool) -> void:
		if active and get_node("/root/CombatAudio").can_emit(actor): _play("reload", active_weapon.data.reload_time))
	player.play("idle")

func _process(delta: float) -> void:
	if _dead: return
	motion_state = &"run" if stride.speed > 2.7 else &"walk" if stride.speed > 0.12 else &"turn" if absf(stride.turning) > 0.25 else &"aim" if actor.sees_target else &"idle"
	if actor.crouching: motion_state = &"crouch"
	if is_instance_valid(actor.mounted_weapon): motion_state = &"mounted"
	_lock -= delta
	if _lock > 0: return
	var clip: String = "aim" if actor.sees_target else "idle"
	if stride.speed > 0.12: clip = "run" if stride.speed > 2.7 else "walk"
	if player.current_animation != clip: player.play(clip, 0.18)
	player.speed_scale = clampf(stride.speed / 2.0, 0.5, 1.8) if clip in ["walk", "run"] else 1.0

func _play(clip: String, duration: float) -> void:
	if _dead and clip != "death": return
	if clip != "death" and not get_node("/root/CombatAudio").can_emit(actor): return
	_lock = duration
	player.speed_scale = 1
	player.play(clip, 0.08, player.get_animation(clip).length / maxf(duration, 0.1))

func _state(state: String) -> void:
	if state == "HURT": _play("hurt", 0.3)
	if state == "DEATH":
		_dead = true
		motion_state = &"death"
		# The authored death animation is an anatomically correct collapse, which
		# is the part physics is worst at inventing. Play it, then hand over to
		# the ragdoll only for where the body finally comes to rest: that keeps
		# the fall readable and lets terrain and impact still matter.
		_play("death", 1.0)
		if RagdollBudget.allows():
			_hand_over.call_deferred()
			return
		var visuals: Node3D = actor.get_node("Visuals")
		_settle.call_deferred(visuals)

func _hand_over() -> void:
	## Let the death animation carry the body most of the way down, then switch
	## to physics so it settles against whatever it actually landed on.
	if not is_instance_valid(actor): return
	await actor.get_tree().create_timer(HANDOVER_DELAY).timeout
	if not is_instance_valid(actor) or not is_instance_valid(model): return
	if not RagdollBudget.allows():
		_settle(actor.get_node("Visuals"))
		return
	_ragdoll()

func _ragdoll() -> void:
	## Physics owns the pose from here, so every animation and skeleton modifier
	## must stop first or they fight the simulation for the same bones.
	player.pause()
	player.active = false
	var skeleton: Skeleton3D = model.get_node("Skeleton3D")
	# Every modifier runs after the simulator and would overwrite the simulated
	# pose each frame, leaving the mesh standing while the bodies fall. The
	# gunner pose is as guilty as the stride, so disable them all rather than
	# naming one.
	for child: Node in skeleton.get_children():
		if child is SkeletonModifier3D: child.active = false
	var simulator: PhysicalBoneSimulator3D = Ragdoll.build(skeleton)
	RagdollBudget.register(simulator, actor)
	Ragdoll.start(simulator, actor.death_impulse)

func _settle(visuals: Node3D) -> void:
	visuals.rotation = Vector3.ZERO
	visuals.position = Vector3.ZERO
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(visuals, "rotation:x", -1.45, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(visuals, "position:y", 0.18, 0.75)
