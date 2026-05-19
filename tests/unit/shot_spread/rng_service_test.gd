extends GdUnitTestSuite

var _rng: RngService


func before_each() -> void:
	_rng = RngService.new()
	add_child(_rng)


func after_each() -> void:
	_rng.queue_free()


# AC-2: seed_rng sets the internal seed
func test_seed_rng_changes_sequence() -> void:
	_rng.seed_rng(1)
	var a: float = _rng.randf_range(0.0, 1.0)
	_rng.seed_rng(99999)
	var b: float = _rng.randf_range(0.0, 1.0)
	# Different seeds should (overwhelmingly likely) produce different first values
	# This is probabilistic but the probability of collision is ~1e-7 for floats
	assert_bool(a != b).is_true()


# AC-3: randf_range returns value in [from, to)
func test_randf_range_within_bounds_zero_to_one() -> void:
	_rng.seed_rng(42)
	for i in range(100):
		var v: float = _rng.randf_range(0.0, 1.0)
		assert_float(v).is_greater_equal(0.0)
		assert_float(v).is_less(1.0)


func test_randf_range_within_bounds_negative_range() -> void:
	_rng.seed_rng(7)
	for i in range(50):
		var v: float = _rng.randf_range(-1.0, 1.0)
		assert_float(v).is_greater_equal(-1.0)
		assert_float(v).is_less(1.0)


# AC-4: randi_range returns value in [from, to]
func test_randi_range_within_bounds() -> void:
	_rng.seed_rng(0)
	for i in range(100):
		var v: int = _rng.randi_range(0, 10)
		assert_int(v).is_greater_equal(0)
		assert_int(v).is_less_equal(10)


func test_randi_range_inclusive_upper_bound_reachable() -> void:
	# With enough samples and a bounded range, we expect to see the upper bound
	_rng.seed_rng(123)
	var saw_upper: bool = false
	for i in range(200):
		if _rng.randi_range(0, 1) == 1:
			saw_upper = true
			break
	assert_bool(saw_upper).is_true()


# AC-5: Determinism — same seed produces same sequence
func test_same_seed_produces_same_randf_sequence() -> void:
	_rng.seed_rng(42)
	var first: float = _rng.randf_range(0.0, 1.0)
	var second_val: float = _rng.randf_range(0.0, 1.0)

	_rng.seed_rng(42)
	var first_replay: float = _rng.randf_range(0.0, 1.0)
	var second_replay: float = _rng.randf_range(0.0, 1.0)

	assert_float(first).is_equal_approx(first_replay, 0.0)
	assert_float(second_val).is_equal_approx(second_replay, 0.0)


func test_same_seed_produces_same_randi_sequence() -> void:
	_rng.seed_rng(77)
	var a: int = _rng.randi_range(0, 100)
	var b: int = _rng.randi_range(0, 100)

	_rng.seed_rng(77)
	assert_int(_rng.randi_range(0, 100)).is_equal(a)
	assert_int(_rng.randi_range(0, 100)).is_equal(b)


# Different seeds produce different first values (non-trivial seeding)
func test_different_seeds_produce_different_values() -> void:
	_rng.seed_rng(1)
	var v1: float = _rng.randf_range(0.0, 1.0)
	_rng.seed_rng(2)
	var v2: float = _rng.randf_range(0.0, 1.0)
	assert_bool(v1 != v2).is_true()
