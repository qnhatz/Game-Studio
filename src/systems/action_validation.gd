class_name ActionValidation
extends Node

## Injected StatusEffects reference. Set before use (DI for testability).
var _status_effects: Node = null


## Returns the list of valid action types for the given player this turn.
## Requires _status_effects to be injected before calling.
func get_valid_actions(player_id: int) -> Array[StringName]:
	assert(_status_effects != null, "ActionValidation: _status_effects not injected")
	var actions: Array[StringName] = []
	if _status_effects.can_fire(player_id):
		actions.append(&"FIRE")
	if _status_effects.can_move(player_id):
		actions.append(&"MOVE")
	return actions


## Returns true if the given action type is currently allowed for the player.
## Unknown action types return false without error.
func is_valid(player_id: int, action_type: StringName) -> bool:
	if action_type == &"FIRE":
		return _status_effects.can_fire(player_id)
	if action_type == &"MOVE":
		return _status_effects.can_move(player_id)
	return false


## Returns true when the player has no valid actions (turn must be skipped).
func is_turn_skipped(player_id: int) -> bool:
	return get_valid_actions(player_id).is_empty()
