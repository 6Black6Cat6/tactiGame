extends Control

var track_ui = preload("res://scenes/track_ui.tscn") 
var timescale = 100

func _ready() -> void:
	#_testdata()
	var myarr = [
		{'nm': 'bob', 'age': 12},
		{'nm': 'mike', 'age': 13},
		{'nm': 'tick', 'age': 16},
		{'nm': 'leon', 'age': 17},
	]
	print(myarr)
	var leon = myarr[3]
	leon.age = 14
	moveel(myarr,leon,3)
	print(myarr)
	var bob = myarr[0]
	bob.age = 15
	moveel(myarr,bob,0)
	print(myarr)
	pass # Replace with function body.

func moveel(arr,el,num):
	var i = arr.bsearch_custom(el,func(a,b): return a.age < b.age)
	if i < num:
		num += 1
	arr.insert(i,el)
	arr.remove_at(num)
	pass

#func _testdata() -> void:
	#var testunit: Unit = Unit.new(0)
	#var testorder: OrderData = OrderData.new()
	#testorder.start_time = 1.0
	#testorder.duration = 1.0
	#testunit.timeline.add_order(testorder)
	#testorder = OrderData.new()
	#testorder.start_time = 3.0
	#testorder.duration = 2.0
	#testunit.timeline.add_order(testorder)
	##var newtrackui = track_ui.instantiate()
	##newtrackui.orders = testunit.timeline.orders[Timeline.Track.MOVEMENT]
	##add_child(newtrackui)
	##print(newtrackui.size.x)
	#$TimelineUI.unit = testunit

func _process(delta: float) -> void:
	pass
