extends VBoxContainer
class_name TimelineUI

const track_ui = preload("res://scenes/track_ui.tscn") 

@onready var ruler: HBoxContainer = $Ruler
@onready var tracks: VBoxContainer = $Tracks

var parent:
	get:
		return parent
	set(value):
		parent = value
		_resize()
var unit: Unit = null:
	get:
		return unit
	set(value):
		unit = value
		_refresh()
var timescale: float:
	get:
		if parent:
			return parent.timescale
		else:
			return 0

func _ready() -> void:
	#if get_parent():
		#if get_parent().get_parent():
			#parent = get_parent().get_parent()
	for trackid in Timeline.Track.values():
		var newtrackui = track_ui.instantiate() as TrackUI
		newtrackui.type = trackid
		newtrackui.parent = self
		newtrackui.need_resize.connect(_resize)
		tracks.add_child(newtrackui)
	_refresh()
	Runtime.state_changed.connect(_resize)

func _refresh() -> void:
	for track in tracks.get_children():
		track.refresh()
	_resize()

func _resize() -> void:
	if timescale > 0:
		var maxlen: float = Runtime.nextstop * timescale
		for track in tracks.get_children():
			if track.get_child_count() > 0:
				var lastchild = track.get_children()[-1]
				maxlen = max(lastchild.start + lastchild.length,maxlen)
		var seconds = int(maxlen/timescale + Runtime.config.turn_duration)
		maxlen = seconds * timescale
		tracks.custom_minimum_size.x = maxlen
		custom_minimum_size.x = maxlen
		for track in tracks.get_children():
			track.size = Vector2(maxlen,27)
		var rulergcc = ruler.get_child_count()
		if rulergcc > seconds:
			for ln in range(seconds + 1, rulergcc - 1):
				var lb = ruler.get_child(ln)
				lb.queue_free()
		else:
			for ln in range(rulergcc,seconds):
				var lb = Label.new()
				lb.text = str(ln)
				lb.custom_minimum_size.x = timescale
				ruler.add_child(lb)

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	#var current_x := Runtime.simtime * timescale - scroll_horizontal
	var current_x := Runtime.simtime * timescale
	if current_x > 0:
		draw_rect(Rect2(0, 0, current_x, size.y), Color(0.0, 0.0, 0.0, 0.4))
		draw_line(Vector2(current_x, 0), Vector2(current_x, size.y), Color(1.0, 0.0, 0.0, 0.8), 2.0)
