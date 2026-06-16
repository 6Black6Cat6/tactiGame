extends Node2D
class_name Weapon

@export var distance: float = 400.0
@export var angle: float = 20.0
@export var damage: float = 1

@onready var vis_poly = $Polygon2D
@onready var fireray: RayCast2D = $RayCast2D

func _init():
	distance = Runtime.config.weapon_distance
	angle = Runtime.config.weapon_angle
	damage = Runtime.config.weapon_damage

func _ready():
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)
	var half_angle := angle / 2.0
	var step := 10.0 # Шаг в градусах
	var steps_count := int(angle / step + 1)
	step = angle / steps_count
	for i in range(steps_count + 1):
		var current_deg = -half_angle + (i * step)
		var point = Vector2.RIGHT.rotated(deg_to_rad(current_deg)) * distance
		points.append(point)
	vis_poly.polygon = points
	vis_poly.color = Color(1, 0, 0, 0.2) # Полупрозрачный желтый
	fireray.add_exception(get_parent())

func bang():
	if Runtime.state == Runtime.RunState.SIMULATE:
		var random_angle := deg_to_rad(randf_range(-angle/2, angle/2))
		var direction := Vector2.RIGHT.rotated(random_angle)
		fireray.target_position = direction * distance
		fireray.force_raycast_update()
		if fireray.is_colliding():
			var target = fireray.get_collider()
			if target is Unit:
				target.apply_hit(damage)
	return false
