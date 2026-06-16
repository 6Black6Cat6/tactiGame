extends Resource
class_name OrderData

enum OrderType {
	MOVE,
	ROTATE,
	WATCH,
	SHOT,
	ATTACK,
}

static var OrderNames: Dictionary = {
	OrderType.MOVE: 'Иди',
	OrderType.ROTATE: 'Поверни',
	OrderType.WATCH: 'Смотри',
	OrderType.SHOT: 'Пли',
	OrderType.ATTACK: 'Атакуй',
}

@export var type: OrderType = OrderType.MOVE
@export var target: Vector2 = Vector2.ZERO

@export var start_time: float = -1:
	get:
		return start_time
	set(value):
		start_time = value
		emit_changed()
@export var duration: float = -1:
	get:
		return duration
	set(value):
		duration = value
		emit_changed()
@export var end_time: float:
	get:
		return start_time + duration

signal drop_me
