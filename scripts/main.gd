extends Node2D

const unit_o := preload("res://scenes/unit.tscn")

#@onready var timeline_view: TimelineUI = $UI/VBoxContainer/TimelineUI

var teams: Dictionary = {0: [], 1: []}

func _ready() -> void:
	randomize()
	_spawn_units()

func _spawn_units() -> void:
	var h := get_viewport_rect().size.y
	var w := get_viewport_rect().size.x
	var ups: float = Runtime.config.units_per_side + 1
	var tmp: Unit = null
	for i in range(1,ups):
		var y: float = i / ups * h
		tmp = unit_o.instantiate() as Unit
		tmp.init(0)
		tmp.global_position = Vector2(w * 0.2, y)
		add_child(tmp)
		teams[0].append(tmp)
		tmp = unit_o.instantiate() as Unit
		tmp.global_position = Vector2(w * 0.8, y)
		tmp.rotate(PI)
		tmp.init(1)
		teams[1].append(tmp)
		add_child(tmp)
	Runtime.nextstate()
