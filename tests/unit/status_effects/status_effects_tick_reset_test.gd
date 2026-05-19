extends GdUnitTestSuite

var _se: StatusEffects


func before_each() -> void:
	_se = StatusEffects.new()
	add_child(_se)


func after_each() -> void:
	_se.queue_free()


# AC-1: Tick 2→1 — flag stays false
func test_tick_fire_counter_two_to_one_stays_false() -> void:
	_se.set_disarmed(0)
	_se.tick_effects(0)
	assert_int(_se._turns_remaining_fire[0]).is_equal(1)
	assert_bool(_se.can_fire(0)).is_false()


func test_tick_move_counter_two_to_one_stays_false() -> void:
	_se.set_immobilized(0)
	_se.tick_effects(0)
	assert_int(_se._turns_remaining_move[0]).is_equal(1)
	assert_bool(_se.can_move(0)).is_false()


# AC-2: Tick 1→0 — flag restores to true
func test_tick_fire_counter_one_to_zero_restores_flag() -> void:
	_se.set_disarmed(0)
	_se._turns_remaining_fire[0] = 1
	_se.tick_effects(0)
	assert_int(_se._turns_remaining_fire[0]).is_equal(0)
	assert_bool(_se.can_fire(0)).is_true()


func test_tick_move_counter_one_to_zero_restores_flag() -> void:
	_se.set_immobilized(0)
	_se._turns_remaining_move[0] = 1
	_se.tick_effects(0)
	assert_int(_se._turns_remaining_move[0]).is_equal(0)
	assert_bool(_se.can_move(0)).is_true()


# AC-3: No-op on Healthy player (counters=0, flags=true)
func test_tick_healthy_player_is_noop_p0() -> void:
	_se.tick_effects(0)
	assert_bool(_se.can_fire(0)).is_true()
	assert_bool(_se.can_move(0)).is_true()
	assert_int(_se._turns_remaining_fire[0]).is_equal(0)
	assert_int(_se._turns_remaining_move[0]).is_equal(0)


func test_tick_healthy_player_is_noop_p1() -> void:
	_se.tick_effects(1)
	assert_bool(_se.can_fire(1)).is_true()
	assert_bool(_se.can_move(1)).is_true()


# AC-4: Staggered counters tick independently
func test_tick_staggered_counters_fire_clears_move_stays() -> void:
	_se.set_disarmed(0)
	_se.tick_effects(0)  # fire: 2→1
	_se.set_immobilized(0)  # move counter = 2
	_se.tick_effects(0)  # fire: 1→0 (restores), move: 2→1 (stays false)
	assert_bool(_se.can_fire(0)).is_true()
	assert_bool(_se.can_move(0)).is_false()
	assert_int(_se._turns_remaining_fire[0]).is_equal(0)
	assert_int(_se._turns_remaining_move[0]).is_equal(1)


# AC-5: Both Restricted (both counters=2) — both tick to 1, both stay false
func test_tick_both_restricted_both_stay_false() -> void:
	_se.set_disarmed(0)
	_se.set_immobilized(0)
	_se.tick_effects(0)
	assert_int(_se._turns_remaining_fire[0]).is_equal(1)
	assert_int(_se._turns_remaining_move[0]).is_equal(1)
	assert_bool(_se.can_fire(0)).is_false()
	assert_bool(_se.can_move(0)).is_false()


# AC-6: reset_all clears all effects for both players
func test_reset_all_clears_active_effects() -> void:
	_se.set_disarmed(0)
	_se.set_immobilized(1)
	_se.reset_all()
	assert_bool(_se.can_fire(0)).is_true()
	assert_bool(_se.can_move(0)).is_true()
	assert_int(_se._turns_remaining_fire[0]).is_equal(0)
	assert_int(_se._turns_remaining_move[0]).is_equal(0)
	assert_bool(_se.can_fire(1)).is_true()
	assert_bool(_se.can_move(1)).is_true()
	assert_int(_se._turns_remaining_fire[1]).is_equal(0)
	assert_int(_se._turns_remaining_move[1]).is_equal(0)


# AC-7: reset_all is idempotent on already-clean state
func test_reset_all_idempotent_on_healthy_state() -> void:
	_se.reset_all()
	assert_bool(_se.can_fire(0)).is_true()
	assert_bool(_se.can_move(0)).is_true()
	assert_int(_se._turns_remaining_fire[0]).is_equal(0)
	assert_int(_se._turns_remaining_move[0]).is_equal(0)


# Two full tick cycles verify end-to-end restriction duration
func test_two_tick_cycle_fire_restriction() -> void:
	_se.set_disarmed(0)
	_se.tick_effects(0)  # 2→1: still restricted
	assert_bool(_se.can_fire(0)).is_false()
	_se.tick_effects(0)  # 1→0: flag restored
	assert_bool(_se.can_fire(0)).is_true()


func test_two_tick_cycle_move_restriction() -> void:
	_se.set_immobilized(1)
	_se.tick_effects(1)
	assert_bool(_se.can_move(1)).is_false()
	_se.tick_effects(1)
	assert_bool(_se.can_move(1)).is_true()


# Tick only affects the specified player
func test_tick_does_not_affect_other_player() -> void:
	_se.set_disarmed(0)
	_se.set_disarmed(1)
	_se.tick_effects(0)  # only tick P0
	assert_int(_se._turns_remaining_fire[0]).is_equal(1)
	assert_int(_se._turns_remaining_fire[1]).is_equal(2)  # P1 untouched
