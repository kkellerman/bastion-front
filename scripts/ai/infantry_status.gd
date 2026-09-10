extends Label3D

@export var infantry: InfantryBrain


func _ready() -> void:
	infantry.state_changed.connect(_on_state)
	infantry.get_node("HealthComponent").health_changed.connect(_on_health)
	_refresh()


func _on_state(_state_name: String) -> void:
	_refresh()


func _on_health(_current: float, _maximum: float) -> void:
	_refresh()


func _refresh() -> void:
	var health: HealthComponent = infantry.get_node("HealthComponent") as HealthComponent
	text = "%s  |  %d HP" % [InfantryBrain.State.keys()[infantry.state], ceili(health.current_health)]
