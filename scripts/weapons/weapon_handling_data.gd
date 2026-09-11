class_name WeaponHandlingData
extends Resource
## Degrees and seconds; shared profiles remain independent of meshes/factions.
@export var camera_kick: float = 0.5
@export var recovery: float = 12.0
@export var burst_growth: float = 0.1
@export var max_climb: float = 3.0
@export var lateral: float = 0.08
@export var inertia: float = 0.018
@export var breath: float = 0.002
@export var magazine_position: Vector3 = Vector3(0, -0.1, 0.06)
@export var mechanism_position: Vector3 = Vector3(0.04, 0.01, -0.08)
@export var magazine_size: Vector3 = Vector3(0.025, 0.08, 0.035)

