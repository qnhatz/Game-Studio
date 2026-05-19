class_name MockTurnSystem
extends Node

var move_tapped_called: bool = false
var move_tapped_player_id: int = -1
var move_tapped_pos: Vector2 = Vector2.ZERO

var action_selected_called: bool = false
var action_selected_player_id: int = -1
var action_selected_type: StringName = &""

## Optional forward target: if set, on_move_tapped calls are forwarded to Movement.
var _movement: Node = null


# InputSystem calls: on_move_tapped(player_id, tap_position)
func on_move_tapped(player_id: int, tap_position: Vector2) -> void:
	move_tapped_called = true
	move_tapped_player_id = player_id
	move_tapped_pos = tap_position
	if _movement != null:
		# Movement.on_move_tapped signature: (tap_position, player_id)
		_movement.on_move_tapped(tap_position, player_id)


func on_action_selected(player_id: int, action_type: StringName, _event: FlickEvent) -> void:
	action_selected_called = true
	action_selected_player_id = player_id
	action_selected_type = action_type


func reset_calls() -> void:
	move_tapped_called = false
	move_tapped_player_id = -1
	move_tapped_pos = Vector2.ZERO
	action_selected_called = false
	action_selected_player_id = -1
	action_selected_type = &""
