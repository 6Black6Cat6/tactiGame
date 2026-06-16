extends Panel
class_name TrackUI

var order_ui = preload("res://scenes/order_ui.tscn") 

var parent
var type: Timeline.Track

var unit: Unit:
	get:
		if parent:
			return parent.unit
		else:
			return null
var orders: Array[OrderData]:
	get:
		if unit:
			return unit.timeline.orders[type]
		else:
			return []
var timescale: float:
	get:
		if parent:
			return parent.timescale
		else:
			return 1

signal need_resize

func _ready() -> void:
	name = Timeline.Track.keys()[type]
	refresh()

func refresh() -> void:
	for child in get_children():
		child.queue_free()
	for order in orders:
		add_orderui(-1,order)
	_need_resize()

func redraw_children(changed: OrderUI) -> void:
	var i = 0
	if changed.order:
		if orders.count(changed.order):
			orders.erase(changed.order)
		i = orders.bsearch_custom(changed.order,func(a,b): return a.start_time < b.start_time)
		orders.insert(i,changed.order)
	var c = get_children()
	i = c.bsearch_custom(changed,func(a,b): return a.position.x < b.position.x)
	move_child(changed, i) 
	i = max(changed.get_index(),1)
	c = get_children()
	var cc = get_child_count()
	while i < cc:
		var current_x = c[i-1].start + c[i-1].length
		if c[i].start < current_x:
			c[i].start = current_x
		i += 1

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed() and unit:
			var neworderui = add_orderui(get_local_mouse_position().x)
			neworderui.grab_focus()
			_need_resize()

func add_orderui(start: float = -1, order: OrderData = null) -> OrderUI:
	var neworderui = order_ui.instantiate()
	neworderui.position.y = 1
	neworderui.parent = self
	if start > 0:
		neworderui.start = start
	add_child(neworderui)
	neworderui.need_resize.connect(_need_resize)
	if order:
		neworderui.order = order
	_need_resize()
	return neworderui

func _need_resize() -> void:
	need_resize.emit()
