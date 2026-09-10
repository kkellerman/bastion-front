extends Node
var actor: InfantryBrain
var model: Node3D
var player: AnimationPlayer
var _lock: float = 0.0
var _dead: bool = false

func _ready() -> void:
	player = model.get_node("AnimationPlayer")
	actor.state_changed.connect(_state)
	actor.combat.weapon.shot_fired.connect(func() -> void: _play("fire", 0.16))
	actor.combat.weapon.reload_changed.connect(func(active: bool) -> void:
		if active: _play("reload", actor.combat.weapon.data.reload_time))
	player.play("idle")

func _process(delta: float) -> void:
	if _dead: return
	_lock -= delta
	if _lock > 0: return
	var clip: String = "aim" if actor.sees_target else "idle"
	if actor.velocity.length() > 0.2: clip = "run" if actor.velocity.length() > 2.7 else "walk"
	if player.current_animation != clip: player.play(clip, 0.18)

func _play(clip: String, duration: float) -> void:
	if _dead: return
	_lock = duration
	player.play(clip, 0.08, player.get_animation(clip).length / maxf(duration, 0.1))

func _state(state: String) -> void:
	if state == "HURT": _play("hurt", 0.3)
	if state == "DEATH":
		_play("death", 0.7)
		_dead = true
		# The gameplay death signal disables collision immediately; the rig settles visually.
		var visuals: Node3D = actor.get_node("Visuals")
		_settle.call_deferred(visuals)

func _settle(visuals: Node3D) -> void:
	visuals.rotation = Vector3.ZERO
	visuals.position = Vector3.ZERO
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(visuals, "rotation:x", -1.45, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(visuals, "position:y", 0.18, 0.75)
