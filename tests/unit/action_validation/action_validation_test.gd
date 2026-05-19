extends GdUnitTestSuite

var _se: StatusEffects
var _av: ActionValidation


func before_each() -> void:
	_se = StatusEffects.new()
	add_child(_se)
	_av = ActionValidation.new()
	_av._status_effects = _se
	add_child(_av)


func after_each() -> void:
	_av.queue_free()
	_se.queue_free()


# AC-1: Both can_fire=true, can_move=true → FIRE and MOVE returned
func test_action_validation_both_valid_returns_fire_and_move() -> void:
	var actions: Array[StringName] = _av.get_valid_actions(0)
	assert_bool(actions.has(&"FIRE")).is_true()
	assert_bool(actions.has(&"MOVE")).is_true()
	assert_int(actions.size()).is_equal(2)


# AC-2: can_fire=false → only MOVE returned
func test_action_validation_fire_disabled_returns_only_move() -> void:
	_se.set_disarmed(0)
	var actions: Array[StringName] = _av.get_valid_actions(0)
	assert_bool(actions.has(&"FIRE")).is_false()
	assert_bool(actions.has(&"MOVE")).is_true()
	assert_int(actions.size()).is_equal(1)


# AC-3: can_move=false → only FIRE returned
func test_action_validation_move_disabled_returns_only_fire() -> void:
	_se.set_immobilized(0)
	var actions: Array[StringName] = _av.get_valid_actions(0)
	assert_bool(actions.has(&"FIRE")).is_true()
	assert_bool(actions.has(&"MOVE")).is_false()
	assert_int(actions.size()).is_equal(1)


# AC-4: both disabled → empty set
func test_action_validation_both_disabled_returns_empty_array() -> void:
	_se.set_disarmed(0)
	_se.set_immobilized(0)
	var actions: Array[StringName] = _av.get_valid_actions(0)
	assert_int(actions.size()).is_equal(0)


# AC-4 continued: is_turn_skipped returns true when no actions valid
func test_action_validation_both_disabled_is_turn_skipped_true() -> void:
	_se.set_disarmed(0)
	_se.set_immobilized(0)
	assert_bool(_av.is_turn_skipped(0)).is_true()


# AC-5: is_valid FIRE with can_fire=false returns false
func test_action_validation_is_valid_fire_when_disarmed_returns_false() -> void:
	_se.set_disarmed(0)
	assert_bool(_av.is_valid(0, &"FIRE")).is_false()


# AC-6: is_valid MOVE with can_move=true returns true
func test_action_validation_is_valid_move_when_mobile_returns_true() -> void:
	assert_bool(_av.is_valid(0, &"MOVE")).is_true()


# AC-7: unknown action type returns false
func test_action_validation_is_valid_unknown_action_returns_false() -> void:
	assert_bool(_av.is_valid(0, &"JUMP")).is_false()


# AC-8: is_turn_skipped returns false when at least one action valid
func test_action_validation_one_action_valid_is_turn_skipped_false() -> void:
	_se.set_disarmed(0)
	assert_bool(_av.is_turn_skipped(0)).is_false()


# Player isolation — p0 status does not affect p1
func test_action_validation_player0_disarmed_does_not_affect_player1() -> void:
	_se.set_disarmed(0)
	assert_bool(_av.is_valid(1, &"FIRE")).is_true()


func test_action_validation_player1_immobilized_does_not_affect_player0() -> void:
	_se.set_immobilized(1)
	assert_bool(_av.is_valid(0, &"MOVE")).is_true()


# is_valid with FIRE when can_fire=true returns true
func test_action_validation_is_valid_fire_when_armed_returns_true() -> void:
	assert_bool(_av.is_valid(0, &"FIRE")).is_true()
