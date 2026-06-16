extends Resource
class_name ActionData

enum ActionType {
	MOVE,
	ROTATE,
	WATCH,
	DETECTION,
	SHOT,
}

@export var type: ActionType = ActionType.MOVE
@export var start_time: float = 0
@export var duration: float = 0
@export var full_duration: float = 0
@export var parent_order: OrderData = null
@export var target: Vector2 = Vector2.ZERO:
	get:
		if target_unit:
			return target_unit.global_position
		else:
			return target
	set(value):
		target = value

var target_unit: Node2D = null

func _init(order: OrderData,dur: float):
	target = order.target
	duration = dur
	full_duration = dur
	parent_order = order
