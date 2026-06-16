extends Resource
class_name GameConfig

@export var units_per_side: int = 3
@export var reaction_min: float = 0.3
@export var reaction_max: float = 1.5
@export var view_distance: float = 200.0
@export var view_cone: float = 120.0
@export var weapon_distance: float = 150.0
@export var weapon_angle: float = 40.0
@export var weapon_damage: float = 1.0
@export var move_speed_min: float = 50.0
@export var move_speed_max: float = 150.0
@export var rotate_speed_min: float = 60.0
@export var rotate_speed_max: float = 120.0
@export var unit_size: float = 20.0
@export var turn_duration: float = 5

#static var current: Resource = preload("res://resources/game_config.tres")
