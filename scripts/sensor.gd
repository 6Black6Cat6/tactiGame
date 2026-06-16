extends Area2D
class_name Sensor

@export var view_distance: float = 300.0
@export var view_angle: float = 90.0 # Общий угол обзора

@onready var col_poly = $CollisionPolygon2D
@onready var vis_poly = $Polygon2D
@onready var lookray: RayCast2D = $RayCast2D

signal see(target: Unit)
signal lost(target: Unit)

var visible_units: Array[Unit] = []

func _init():
	view_distance = Runtime.config.view_distance
	view_angle = Runtime.config.view_cone

func _ready():
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)
	var half_angle := view_angle / 2.0
	var step := 10.0 # Шаг в градусах
	var steps_count := int(view_angle / step + 1)
	step = view_angle / steps_count
	for i in range(steps_count + 1):
		var current_deg = -half_angle + (i * step)
		var point = Vector2.RIGHT.rotated(deg_to_rad(current_deg)) * view_distance
		points.append(point)
	col_poly.polygon = points
	vis_poly.polygon = points
	vis_poly.color = Color(0, 1, 1, 0.2) # Полупрозрачный желтый
	lookray.add_exception(get_parent())

func _physics_process(delta: float):
	if Runtime.state == Runtime.RunState.SIMULATE:
		for target in visible_units:
			if not can_see(target):
				lost.emit(target)
				visible_units.erase(target)

func can_see(target: CharacterBody2D) -> bool:
	if Runtime.state == Runtime.RunState.SIMULATE:
		lookray.target_position = lookray.to_local(target.global_position)
		lookray.force_raycast_update()
		if lookray.is_colliding():
			return lookray.get_collider() == target
	return false

func _on_body_entered(body: Node2D) -> void:
	if Runtime.state == Runtime.RunState.SIMULATE:
		if body is Unit and can_see(body):
			see.emit(body)
			visible_units.append(body)

func _on_body_exited(body: Node2D) -> void:
	if Runtime.state == Runtime.RunState.SIMULATE:
		if visible_units.count(body) > 0: 
			lost.emit(body)
			visible_units.erase(body)
