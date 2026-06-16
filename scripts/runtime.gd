extends Node

enum RunState {
	STOPPED,
	PLANNING,
	SIMULATE,
}

var simtime: float = 0
var activeteam: int = 0
var teams: Dictionary = {0: [], 1: []}
var nextstop: float = 5
var config: GameConfig = preload("res://resources/game_config.tres")

var state = RunState.STOPPED:
	get:
		return state
	set(value):
		state = value
		state_changed.emit()

signal state_changed

func _physics_process(delta: float) -> void:
	if state == RunState.SIMULATE:
		simtime += delta
		if simtime >= nextstop:
			nextstop += config.turn_duration
			nextstate()

func stop() -> void:
	state = RunState.STOPPED

func nextstate() -> void:
	if state == RunState.PLANNING:
		if activeteam < teams.size() - 1:
			activeteam += 1
		else:
			state = RunState.SIMULATE
	else:
		activeteam = 0
		state = RunState.PLANNING
