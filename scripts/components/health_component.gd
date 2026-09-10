class_name HealthComponent
extends Node

signal health_changed(current: float, maximum: float)
signal died

@export_range(1.0, 10000.0) var max_health: float = 100.0
var current_health: float = 0.0


func _ready() -> void:
	reset()


func take_damage(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	if current_health == 0.0:
		died.emit()


func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
