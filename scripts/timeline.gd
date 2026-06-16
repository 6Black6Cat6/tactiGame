extends Resource
class_name Timeline

enum Track { # в порядке приоритета
	ACTIVITY,
	ROTATION,
	MOVEMENT,
}

static var OrderTrack: Dictionary = {
	OrderData.OrderType.MOVE: Track.MOVEMENT,
	OrderData.OrderType.ROTATE: Track.ROTATION,
	OrderData.OrderType.WATCH: Track.ROTATION,
	OrderData.OrderType.SHOT: Track.ACTIVITY,
	OrderData.OrderType.ATTACK: Track.ACTIVITY,
}

static var TrackNames: Dictionary = {
	Track.ACTIVITY: 'Активность',
	Track.ROTATION: 'Поворот',
	Track.MOVEMENT: 'Движение',
}

var orders = []
var actions = []

func _init():
	for track in Track.values():
		# многоуровневый список приказы[дорожка[приказ]]
		var trorders: Array[OrderData] = []
		orders.append(trorders)
		# многоуровневый список действия[дорожка[действие]]
		var tractions: Array[ActionData] = []
		actions.append(tractions)

# Actions
func get_action(track: Track) -> ActionData:
	if not actions[track].is_empty():
		return actions[track][0]
	else:
		return null

func add_action(track: Track, action: ActionData):
	var index = 0
	if not actions[track].is_empty():
		if actions[track][0].duration < actions[track][0].full_duration:
			index = 1
	actions[track].insert(index,action)

func drop_action(track: Track):
	if not actions[track].is_empty():
		actions[track].remove_at(0)

func change_action_duration(track: Track, delta: float) -> float:
	var action = actions[track][0]
	action.duration -= delta
	if action.duration < 0:
		delta = -action.duration
		action.duration = 0
	else:
		delta = 0
	return delta

# Orders
func get_order(track: Track, time: float) -> OrderData:
	var result: OrderData = null
	for order in orders[track]:
		if order.start_time <= time and time <= order.start_time + order.duration:
			result = order
	return result

func add_order(track: Track, order: OrderData) -> void:
	if (OrderTrack[order.type] == track):
		_on_order_changed(order)
		order.changed.connect(_on_order_changed.bind(order))
		order.drop_me.connect(_on_order_drop.bind(order))

func drop_order(track: Track, order: OrderData) -> void:
	if (OrderTrack[order.type] == track):
		orders[track].erase(order)

func _on_order_changed(order: OrderData):
	var ortr = orders[OrderTrack[order.type]]
	ortr.erase(order)
	var i = ortr.bsearch_custom(order,func(a,b): return a.start_time < b.start_time)
	if (i > 0 and ortr[i-1].end_time > order.start_time):
		order.start_time = ortr[i-1].end_time
	ortr.insert(i,order)
	if (i < ortr.size() - 1 and order.end_time > ortr[i+1].start_time):
		ortr[i+1].start_time = order.end_time

func _on_order_drop(order: OrderData):
	drop_order(OrderTrack[order.type],order)
