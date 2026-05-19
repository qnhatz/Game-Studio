extends GdUnitTestSuite

var _se: StatusEffects


func before_each() -> void:
	_se = StatusEffects.new()
	add_child(_se)


func after_each() -> void:
	_se.queue_free()


# AC-1: Initial state — all flags true, all counters 0
func test_initial_state_can_fire_true() -> void:
	assert_bool(_se.can_fire(0)).is_true()
	assert_bool(_se.can_fire(1)).is_true()


func test_initial_state_can_move_true() -> void:
	assert_bool(_se.can_move(0)).is_true()
	assert_bool(_se.can_move(1)).is_true()


func test_initial_state_counters_zero() -> void:
	assert_int(_se._turns_remaining_fire[0]).is_equal(0)
	assert_int(_se._turns_remaining_fire[1]).is_equal(0)
	assert_int(_se._turns_remaining_move[0]).is_equal(0)
	assert_int(_se._turns_remaining_move[1]).is_equal(0)


# AC-2: set_disarmed sets can_fire=false, counter=2, can_move unchanged
func test_set_disarmed_clears_can_fire() -> void:
	_se.set_disarmed(0)
	assert_bool(_se.can_fire(0)).is_false()


func test_set_disarmed_sets_counter_to_two() -> void:
	_se.set_disarmed(0)
	assert_int(_se._turns_remaining_fire[0]).is_equal(2)


func test_set_disarmed_does_not_affect_can_move() -> void:
	_se.set_disarmed(0)
	assert_bool(_se.can_move(0)).is_true()


# AC-3: set_immobilized sets can_move=false, counter=2, can_fire unchanged
func test_set_immobilized_clears_can_move() -> void:
	_se.set_immobilized(0)
	assert_bool(_se.can_move(0)).is_false()


func test_set_immobilized_sets_counter_to_two() -> void:
	_se.set_immobilized(0)
	assert_int(_se._turns_remaining_move[0]).is_equal(2)


func test_set_immobilized_does_not_affect_can_fire() -> void:
	_se.set_immobilized(0)
	assert_bool(_se.can_fire(0)).is_true()


# AC-4: Both effects simultaneously
func test_both_effects_disarm_then_immobilize() -> void:
	_se.set_disarmed(0)
	_se.set_immobilized(0)
	assert_bool(_se.can_fire(0)).is_false()
	assert_bool(_se.can_move(0)).is_false()
	assert_int(_se._turns_remaining_fire[0]).is_equal(2)
	assert_int(_se._turns_remaining_move[0]).is_equal(2)


func test_both_effects_immobilize_then_disarm() -> void:
	_se.set_immobilized(0)
	_se.set_disarmed(0)
	assert_bool(_se.can_fire(0)).is_false()
	assert_bool(_se.can_move(0)).is_false()


# AC-5: Idempotent re-apply resets counter to 2
func test_set_disarmed_idempotent_resets_counter() -> void:
	_se.set_disarmed(0)
	_se.set_disarmed(0)
	assert_bool(_se.can_fire(0)).is_false()
	assert_int(_se._turns_remaining_fire[0]).is_equal(2)


# AC-6: Re-apply while counter=1 extends restriction back to 2
func test_set_disarmed_extends_when_counter_one() -> void:
	_se.set_disarmed(0)
	_se._turns_remaining_fire[0] = 1  # simulate partial tick
	_se.set_disarmed(0)
	assert_int(_se._turns_remaining_fire[0]).is_equal(2)
	assert_bool(_se.can_fire(0)).is_false()


# AC-7: Player isolation — P0 disarmed does not affect P1
func test_set_disarmed_does_not_affect_other_player() -> void:
	_se.set_disarmed(0)
	assert_bool(_se.can_fire(1)).is_true()
	assert_int(_se._turns_remaining_fire[1]).is_equal(0)


func test_set_immobilized_does_not_affect_other_player() -> void:
	_se.set_immobilized(1)
	assert_bool(_se.can_move(0)).is_true()
	assert_int(_se._turns_remaining_move[0]).is_equal(0)


# get_status returns correct dictionary
func test_get_status_healthy() -> void:
	var status: Dictionary = _se.get_status(0)
	assert_bool(status.can_fire).is_true()
	assert_bool(status.can_move).is_true()


func test_get_status_disarmed() -> void:
	_se.set_disarmed(0)
	var status: Dictionary = _se.get_status(0)
	assert_bool(status.can_fire).is_false()
	assert_bool(status.can_move).is_true()
