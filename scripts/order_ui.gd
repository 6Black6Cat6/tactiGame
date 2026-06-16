extends Label
class_name OrderUI

var parent
var resizer: int = 10 # размер границы для изменения размера
var _is_dragging: bool = false
var _is_resizing: bool = false
var _mouse_offset: Vector2 = Vector2.ZERO

var order: OrderData = null: # null - начальное состояние
	get:
		return order
	set(value):
		order = value
		order.changed.connect(_on_order_changed)
		_on_order_changed()
var timescale: float:
	get:
		if parent:
			return parent.timescale
		else:
			return 1
var tracktype: Timeline.Track:
	get:
		if parent:
			return parent.type
		else:
			return Timeline.Track.ACTIVITY
var start: float:
	get:
		return position.x - 1
	set(value):
		position.x = value + 1
var length: float:
	get:
		return size.x
	set(value):
		size.x = value

signal need_resize

func _ready() -> void:
	if order:
		_on_order_changed()
		order.changed.connect(_on_order_changed)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_mouse_offset = get_local_mouse_position()
			if length - _mouse_offset.x < resizer:
				_is_resizing = true
				mouse_default_cursor_shape = Control.CURSOR_HSIZE
			else:
				_is_dragging = true
				mouse_default_cursor_shape = Control.CURSOR_DRAG
		else:
			if _is_dragging and order:
				order.start_time = start / timescale
			_is_dragging = false
			if _is_resizing and order:
				order.duration = length / timescale
			_is_resizing = false
			mouse_default_cursor_shape = Control.CURSOR_ARROW
	if event is InputEventMouseMotion:
		if _is_dragging:
			global_position.x = get_global_mouse_position().x - _mouse_offset.x
		elif _is_resizing:
			length = get_local_mouse_position().x
		elif length - get_local_mouse_position().x < resizer:
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
		else:
			mouse_default_cursor_shape = Control.CURSOR_ARROW

func _on_focus_exited() -> void:
	if not order:
		self.queue_free()

func _on_order_changed():
	text = OrderData.OrderNames[order.type]
	if order.duration > 0:
		length = order.duration * timescale
	if order.start_time > 0:
		start = order.start_time * timescale
	need_resize.emit()
