extends Node3D

@onready var health: HealthComponent = $HealthComponent
@onready var label: Label3D = $Status
@onready var board: MeshInstance3D = $DamageReceiver/Board
@onready var reset_timer: Timer = $ResetTimer


func _ready() -> void:
	health.health_changed.connect(_update_health)
	health.died.connect(_on_destroyed)
	reset_timer.timeout.connect(health.reset)
	_update_health(health.current_health, health.max_health)


func _update_health(current: float, maximum: float) -> void:
	label.text = "TEST TARGET\n%d / %d" % [ceili(current), ceili(maximum)]
	board.transparency = 0.0 if current > 0.0 else 0.7


func _on_destroyed() -> void:
	label.text = "DESTROYED\nResets in 3 seconds"
	reset_timer.start()
