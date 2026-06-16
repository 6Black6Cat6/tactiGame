extends CanvasLayer

@onready var timeline_view: TimelineUI = $VBoxContainer/ScrollContainer/TimelineUI
@onready var timeline_scroll: ScrollContainer = $VBoxContainer/ScrollContainer

var timescale: float = 100

func _ready() -> void:
	timeline_scroll.custom_minimum_size.y = 27 * (Timeline.Track.size() + 1)
	timeline_view.parent = self

func _unhandled_input(event: InputEvent) -> void:
	if Runtime.state == Runtime.RunState.PLANNING:
		var focused = get_viewport().gui_get_focus_owner()
		var neworder: OrderData = null
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_SPACE:
				select_unit(null)
				Runtime.nextstate()
			elif timeline_view.unit:
				if focused is OrderUI:
					if event.keycode == KEY_DELETE:
						if focused.order:
							# доделать удаление только невыполненной части и одновременное удаление действий
							focused.order.drop_me.emit()
							focused.order = null
						focused.queue_free()
					elif !focused.order and focused.tracktype == Timeline.Track.ACTIVITY:
						if event.keycode == KEY_S:
							neworder = new_order(OrderData.OrderType.SHOT,focused.start,timeline_view.unit.reaction_time,Vector2.ZERO)
						elif event.keycode == KEY_A:
							neworder = new_order(OrderData.OrderType.ATTACK,focused.start,focused.length,Vector2.ZERO)
		if event is InputEventMouseButton:
			if event.pressed:
				if event.button_index == MOUSE_BUTTON_LEFT:
					var space_state = get_parent().get_world_2d().direct_space_state
					var query := PhysicsPointQueryParameters2D.new()
					query.position = event.global_position
					query.collide_with_bodies = true
					var result = space_state.intersect_point(query)
					if not result.is_empty():
						var hit_object = result[0].collider
						if hit_object is Unit:
							select_unit(hit_object)
					else:
						select_unit(null)
				elif event.button_index == MOUSE_BUTTON_RIGHT and timeline_view.unit != null:
					# если не выделен OrderUI или выделен "не тот"
					if focused is OrderUI and !focused.order:
						if focused.tracktype == Timeline.Track.ROTATION:
							neworder = OrderData.new()
							if Input.is_key_pressed(KEY_CTRL):
								neworder = new_order(OrderData.OrderType.ROTATE,focused.start,event.global_position.angle() / timeline_view.unit.rotate_speed,event.global_position)
							else:
								neworder = new_order(OrderData.OrderType.WATCH,focused.start,(event.global_position - timeline_view.unit.global_position).angle() / timeline_view.unit.rotate_speed,event.global_position)
						elif focused.tracktype == Timeline.Track.MOVEMENT:
							neworder = new_order(OrderData.OrderType.MOVE,focused.start,(event.global_position - timeline_view.unit.global_position).length() / timeline_view.unit.move_speed,event.global_position)
		if neworder:
			focused.order = neworder
			timeline_view.unit.timeline.add_order(focused.tracktype,neworder)
			neworder.emit_changed()

func new_order(type: OrderData.OrderType,start: float, dur: float, target: Vector2) -> OrderData:
	var neworder: OrderData = OrderData.new()
	neworder.type = type
	neworder.start_time = start / timescale
	neworder.duration = dur
	neworder.target = target
	return neworder

func select_unit(unit: Unit):
	if timeline_view.unit:
		timeline_view.unit.set_selected(false)
		timeline_view.unit = null
	if unit and unit.team_id == Runtime.activeteam:
		unit.set_selected(true)
		timeline_view.unit = unit
