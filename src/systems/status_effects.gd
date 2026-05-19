class_name StatusEffects
extends Node

var _can_fire: Array[bool] = [true, true]
var _can_move: Array[bool] = [true, true]
var _turns_remaining_fire: Array[int] = [0, 0]
var _turns_remaining_move: Array[int] = [0, 0]


func can_fire(player_id: int) -> bool:
	return _can_fire[player_id]


func can_move(player_id: int) -> bool:
	return _can_move[player_id]


func get_status(player_id: int) -> Dictionary:
	return {can_fire = _can_fire[player_id], can_move = _can_move[player_id]}


func set_disarmed(player_id: int) -> void:
	_can_fire[player_id] = false
	_turns_remaining_fire[player_id] = 2


func set_immobilized(player_id: int) -> void:
	_can_move[player_id] = false
	_turns_remaining_move[player_id] = 2


func tick_effects(player_id: int) -> void:
	if _turns_remaining_fire[player_id] > 0:
		_turns_remaining_fire[player_id] -= 1
		if _turns_remaining_fire[player_id] == 0:
			_can_fire[player_id] = true
	if _turns_remaining_move[player_id] > 0:
		_turns_remaining_move[player_id] -= 1
		if _turns_remaining_move[player_id] == 0:
			_can_move[player_id] = true


func reset_all() -> void:
	for pid in range(2):
		_can_fire[pid] = true
		_can_move[pid] = true
		_turns_remaining_fire[pid] = 0
		_turns_remaining_move[pid] = 0
