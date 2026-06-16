extends CharacterBody2D
class_name Unit

var team_id: int = 0
var radius: float = 20.0
var hp: float = 1
var detected_enemies: Array[Unit] = []
var detected_allies: Array[Unit] = []
var reaction_time: float = 0.5
var move_speed: float = 180.0
var rotate_speed: float = 90.0
var timeline := Timeline.new()

@onready var weapon: Weapon = $Weapon
@onready var sensor: Sensor = $Sensor
@onready var hurt_shape: CollisionShape2D = $CollisionShape2D
@onready var vis: Sprite2D = $Sprite2D

# TASK: подумать, может по физике менять dir, а поворачивать уже в обычном кадре
# TASK: также и про перемещение тогда...

func init(p_team_id: int):
	team_id = p_team_id
	reaction_time = randf_range(Runtime.config.reaction_min, Runtime.config.reaction_max)
	move_speed = randf_range(Runtime.config.move_speed_min, Runtime.config.move_speed_max)
	rotate_speed = deg_to_rad(randf_range(Runtime.config.rotate_speed_min, Runtime.config.rotate_speed_max))
	radius = Runtime.config.unit_size/2

func set_selected(is_selected: bool) -> void:
	if is_selected:
		vis.modulate = Color(1.5, 1.5, 1.5) # Подсвечиваем
	else:
		vis.modulate = Color(1, 1, 1) # Возвращаем оригинал

func _ready() -> void:
	if not hurt_shape.shape:
		var hurt_circle := CircleShape2D.new()
		hurt_circle.radius = radius
		hurt_shape.shape = hurt_circle
	var circles = [
		"res://resources/circleb.png",
		"res://resources/circler.png"
	]
	vis.texture = load(circles[team_id % 2])
	vis.scale = 2 * Vector2(radius,radius) / vis.texture.get_size()

func _physics_process(delta: float) -> void:
	if Runtime.state == Runtime.RunState.SIMULATE:
		var simtime: float = Runtime.simtime # текущие секунды игры - глобальная переменная
		# сначала смотрим действия, потом приказы
		# приоритет: активность, поворот, движение
		var action_activity: ActionData = _process_action_activity(delta)
		var action_rotation: ActionData = _process_action_rotation(delta)
		var action_movement: ActionData = _process_action_movement(delta)
		# закончили с действиями, теперь приказы - заполнение действий
		if not action_activity: # пустая очередь действий активности
			_process_order_activity(simtime)
			action_rotation = timeline.get_action(Timeline.Track.ROTATION)
			action_movement = timeline.get_action(Timeline.Track.MOVEMENT)
		if not action_rotation: # пустая очередь действий поворота
			_process_order_rotation(simtime)
		if not action_movement: # пустая очередь действий движения
			_process_order_movement(simtime)

func _process_action_activity(delta: float) -> ActionData:
	var action: ActionData = timeline.get_action(Timeline.Track.ACTIVITY)
	if action:
		delta = timeline.change_action_duration(Timeline.Track.ACTIVITY,delta)
		match action.type:
			ActionData.ActionType.SHOT:
				if action.duration == 0:
					weapon.bang()
			ActionData.ActionType.DETECTION:
				if sensor.can_see(action.target_unit):
					if action.duration == 0:
						if action.target_unit.team_id == team_id:
							detected_allies.append(action.target_unit)
						else:
							detected_enemies.append(action.target_unit)
				else:
					action.duration = 0
		if action.duration == 0:
			timeline.drop_action(Timeline.Track.ACTIVITY)
			action = null
			action = _process_action_activity(delta)
	return action

func _process_action_rotation(delta: float) -> ActionData:
	var action: ActionData = timeline.get_action(Timeline.Track.ROTATION)
	if action:
		var step = rotate_speed * delta
		var ang: float = 0
		match action.type:
			ActionData.ActionType.ROTATE:
				ang = action.target.angle()
			ActionData.ActionType.WATCH:
				ang = (action.target - position).angle()
		ang = clamp(ang,-step,step)
		rotation += ang
		delta = timeline.change_action_duration(Timeline.Track.ROTATION,delta)
		if action.duration == 0:
			timeline.drop_action(Timeline.Track.ROTATION)
			action = null
			action = _process_action_rotation(delta)
	return action

func _process_action_movement(delta: float) -> ActionData:
	var action: ActionData = timeline.get_action(Timeline.Track.MOVEMENT)
	if action:
		match action.type:
			ActionData.ActionType.MOVE:
				var to_target := action.target - position
				var step := move_speed * delta
				if to_target.length() <= step:
					position = action.target
				else:
					position += to_target.normalized() * step
		delta = timeline.change_action_duration(Timeline.Track.MOVEMENT,delta)
		if action.duration == 0:
			timeline.drop_action(Timeline.Track.MOVEMENT)
			action = null
			action = _process_action_movement(delta)
	return action

func _process_order_activity(simtime: float):
	var order := timeline.get_order(Timeline.Track.ACTIVITY,simtime)
	if order:
		match order.type:
			OrderData.OrderType.SHOT:
				var action := ActionData.new(order,simtime)
				action.type = ActionData.ActionType.SHOT
				action.duration = reaction_time
				timeline.add_action(Timeline.Track.ACTIVITY,action)
			OrderData.OrderType.ATTACK:
				if not detected_enemies.is_empty():
					var trgunit: Unit = null
					var trgang := 0.0
					var trgdist := INF
					for enemy in detected_enemies:
						if trgdist > global_position.distance_squared_to(enemy.global_position):
							trgunit = enemy
							trgdist = global_position.distance_squared_to(enemy.global_position)
					trgdist = global_position.distance_to(trgunit.global_position)
					if trgdist < weapon.distance:
						trgang = abs((trgunit.global_position - global_position).angle())
						if trgang < 0.4*weapon.angle:
							var action := ActionData.new(order,simtime)
							action.type = ActionData.ActionType.SHOT
							action.duration = reaction_time
							timeline.add_action(Timeline.Track.ACTIVITY,action)
						if trgang > 0.1*weapon.angle:
							var rotAct := timeline.get_action(Timeline.Track.ROTATION)
							if not rotAct or rotAct.order != order or not rotAct.target_unit:
								timeline.drop_action(Timeline.Track.ROTATION)
								rotAct = ActionData.new(order,simtime)
								rotAct.type = ActionData.ActionType.WATCH
								rotAct.target_unit = trgunit
								rotAct.duration = trgang / rotate_speed + reaction_time
								rotAct.duration = clamp(rotAct.duration,0,order.duration-(simtime-order.start_time))
								timeline.add_action(Timeline.Track.ROTATION,rotAct)

func _process_order_rotation(simtime: float):
	var order := timeline.get_order(Timeline.Track.ROTATION,simtime)
	if order:
		var action := ActionData.new(order,simtime)
		match order.type:
			OrderData.OrderType.ROTATE:
				action.type = ActionData.ActionType.ROTATE
				action.duration = order.target.angle() / rotate_speed
			OrderData.OrderType.WATCH:
				action.type = ActionData.ActionType.WATCH
				action.duration = (order.target - position).angle() / rotate_speed
		action.duration = clamp(abs(action.duration),0,order.duration - (simtime-order.start_time))
		timeline.add_action(Timeline.Track.ROTATION,action)

func _process_order_movement(simtime: float):
	var order := timeline.get_order(Timeline.Track.MOVEMENT,simtime)
	if order:
		var action := ActionData.new(order,simtime)
		match order.type:
			OrderData.OrderType.MOVE:
				action.type = ActionData.ActionType.MOVE
				action.duration = (order.target - position).length() / move_speed
		action.duration = clamp(action.duration,0,order.duration - (simtime-order.start_time))
		timeline.add_action(Timeline.Track.MOVEMENT,action)

func apply_hit(damage: float) -> void:
	hp -= damage
	if hp <= 0:
		self.queue_free()

func _on_sensor_lost(target: Unit) -> void:
	if detected_enemies.count(target):
		detected_enemies.erase(target)
	elif detected_allies.count(target):
		detected_allies.erase(target)
	else:
		var index = timeline.actions[Timeline.Track.ACTIVITY].find_custom(func(item): return item.target_unit == target)
		if index != -1:
			timeline.drop_action(Timeline.Track.ACTIVITY)

func _on_sensor_see(target: Unit) -> void:
	var simtime: float = Runtime.simtime # текущие секунды игры - глобальная переменная
	var order := timeline.get_order(Timeline.Track.ACTIVITY,simtime)
	if order and order.type == OrderData.OrderType.ATTACK:
		var action := ActionData.new(order,simtime)
		action.type = ActionData.ActionType.DETECTION
		action.duration = reaction_time
		action.target_unit = target
		timeline.add_action(Timeline.Track.ACTIVITY,action)
