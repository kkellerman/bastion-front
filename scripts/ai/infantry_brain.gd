class_name InfantryBrain
extends CharacterBody3D

signal state_changed(state_name: String)
enum State { IDLE, PATROL, ALERT, CHASE, ATTACK, HURT, DEATH }

@export var target: CollisionObject3D
@export var target_aim: Node3D
@export var patrol_points: Array[Vector3] = []
@export var memory_duration: float = 4.0
@export var alert_delay: float = 0.65
@export var hearing_enabled: bool = false

var state: State = State.IDLE
var last_known_position: Vector3
var sees_target: bool = false
var _memory_remaining: float = 0.0
var _state_time: float = 0.0
var _patrol_index: int = 0
var _previous_health: float = 100.0
var tactics: Node
var mounted_weapon: MountedWeapon
@export var crouching: bool = false

@onready var vision: InfantryVision = $Vision
@onready var motor: InfantryMotor = $Motor
@onready var combat: InfantryCombat = $Combat
@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	_previous_health = health.current_health
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_die)
	get_node("/root/CombatAudio").noise.connect(_hear_noise)
	add_child(load("res://scripts/components/infantry_stance.gd").new())


func _physics_process(delta: float) -> void:
	if state == State.DEATH:
		return
	_state_time += delta
	sees_target = vision.can_see(target, target_aim)
	_memory_remaining = maxf(0.0, _memory_remaining - delta)
	if sees_target:
		# Hidden targets never update this point, even while alert or hurt.
		last_known_position = target.global_position
		_memory_remaining = memory_duration
	if state == State.HURT:
		motor.stop(delta)
		if _state_time >= 0.3:
			_set_state(State.ALERT)
		return
	if sees_target and (state == State.IDLE or state == State.PATROL):
		_set_state(State.ALERT)
	if is_instance_valid(mounted_weapon):
		motor.stop(delta)
		if _state_time >= alert_delay:
			_set_state(State.ATTACK if sees_target else State.IDLE)
		return
	if tactics != null and tactics.tick(delta): return
	match state:
		State.IDLE:
			motor.stop(delta)
			if _state_time >= 1.0 and not patrol_points.is_empty():
				_set_state(State.PATROL)
		State.PATROL:
			if patrol_points.is_empty():
				_set_state(State.IDLE)
			elif motor.travel(patrol_points[_patrol_index], delta):
				_patrol_index = (_patrol_index + 1) % patrol_points.size()
				_set_state(State.IDLE)
		State.ALERT:
			motor.stop(delta)
			if _memory_remaining > 0.0:
				motor.face(last_known_position, delta)
			else:
				rotate_y(delta * 1.5)
			if _state_time >= alert_delay:
				_set_state(State.CHASE if _memory_remaining > 0.0 else State.IDLE)
		State.CHASE, State.ATTACK:
			if _memory_remaining <= 0.0:
				_set_state(State.IDLE)
				motor.stop(delta)
			elif sees_target and global_position.distance_to(last_known_position) <= combat.firing_distance:
				_set_state(State.ATTACK)
				motor.stop(delta)
				motor.face(last_known_position, delta)
				combat.attack(target_aim.global_position)
			else:
				_set_state(State.CHASE)
				motor.travel(last_known_position, delta)


func _set_state(next: State) -> void:
	if next == state or state == State.DEATH:
		return
	state = next
	_state_time = 0.0
	state_changed.emit(State.keys()[state])


func _on_health_changed(current: float, _maximum: float) -> void:
	if current > 0.0 and current < _previous_health and state != State.DEATH:
		_set_state(State.HURT)
		# Rigged presentation owns flinch; competing root tweens used to undo death poses.
	_previous_health = current


func _die() -> void:
	_set_state(State.DEATH)
	combat.disable()
	velocity = Vector3.ZERO
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	$BodyCollision.set_deferred("disabled", true)
	$Visuals.rotation.z = PI * 0.5
	$Visuals.position.y = 0.3
	$Eyes.visible = false
	set_physics_process(false)


func _hear_noise(point: Vector3, radius: float, source: CollisionObject3D) -> void:
	if not get_node("/root/CombatAudio").can_emit(self): return
	if not hearing_enabled or state == State.DEATH or source == self or not FactionData.hostile(self, source):
		return
	if global_position.distance_to(point) > radius or sees_target:
		return
	# Hearing records the sound event, not a live reference to the hidden player's position.
	last_known_position = point.snapped(Vector3(2, 0.1, 2))
	_memory_remaining = memory_duration
	if state != State.HURT:
		_set_state(State.ALERT)

func receive_alert(point: Vector3) -> void:
	if not get_node("/root/CombatAudio").can_emit(self): return
	if state == State.DEATH or sees_target: return
	last_known_position = point
	_memory_remaining = memory_duration
	if state in [State.IDLE, State.PATROL]: _set_state(State.ALERT)
