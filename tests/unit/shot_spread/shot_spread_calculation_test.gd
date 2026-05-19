extends GdUnitTestSuite

# AC-1 to AC-3: Half-angle formula F1
func test_half_angle_power_zero() -> void:
	var h: float = ShotSpreadCalculation._compute_half_angle(0.0)
	assert_float(h).is_equal_approx(2.0, 0.0001)


func test_half_angle_power_one() -> void:
	var h: float = ShotSpreadCalculation._compute_half_angle(1.0)
	assert_float(h).is_equal_approx(30.0, 0.0001)


func test_half_angle_power_half() -> void:
	var h: float = ShotSpreadCalculation._compute_half_angle(0.5)
	assert_float(h).is_equal_approx(16.0, 0.0001)


func test_half_angle_custom_spread_deg() -> void:
	# With spread_deg=16, power=1.0 → half_angle = 2 + 1*(16-2) = 16
	var h: float = ShotSpreadCalculation._compute_half_angle(1.0, 16.0)
	assert_float(h).is_equal_approx(16.0, 0.0001)


# AC-4: Cone bounds — 1000 samples at max power all within ±30°
func test_cone_bounds_max_power_all_within_30_degrees() -> void:
	var rng: RngService = RngService.new()
	add_child(rng)
	rng.seed_rng(42)
	var base_dir := Vector2(1.0, 0.0)
	for i in range(1000):
		var event := FlickEvent.new(base_dir, 1.0, 0)
		var result: Vector2 = ShotSpreadCalculation.apply_spread(event, 30.0)
		var angle_deg: float = rad_to_deg(base_dir.angle_to(result))
		assert_float(absf(angle_deg)).is_less_equal(30.0)
	rng.queue_free()


# AC-5: Result is always a unit vector
func test_result_is_unit_vector() -> void:
	var rng: RngService = RngService.new()
	add_child(rng)
	rng.seed_rng(42)
	var power_values: Array[float] = [0.0, 0.25, 0.5, 0.75, 1.0]
	for i in range(100):
		var angle: float = i * TAU / 100.0
		var dir := Vector2(cos(angle), sin(angle))
		var power: float = power_values[i % power_values.size()]
		var event := FlickEvent.new(dir, power, 0)
		var result: Vector2 = ShotSpreadCalculation.apply_spread(event)
		assert_float(result.length()).is_equal_approx(1.0, 0.0001)
	rng.queue_free()


# AC-6: Zero vector fallback (tested via _apply_spread_raw, bypassing FlickEvent assert)
func test_zero_direction_returns_fallback() -> void:
	var result: Vector2 = ShotSpreadCalculation._apply_spread_raw(Vector2.ZERO, 0.5)
	assert_vector2(result).is_equal_approx(Vector2(1.0, 0.0), Vector2(0.0001, 0.0001))


# AC-7: Seeded determinism
func test_seeded_determinism() -> void:
	var rng: RngService = RngService.new()
	add_child(rng)
	var event := FlickEvent.new(Vector2(1.0, 0.0), 0.5, 0)

	rng.seed_rng(99)
	var first: Vector2 = ShotSpreadCalculation.apply_spread(event)

	rng.seed_rng(99)
	var second: Vector2 = ShotSpreadCalculation.apply_spread(event)

	assert_vector2(first).is_equal_approx(second, Vector2(0.0001, 0.0001))
	rng.queue_free()


# Triangular distribution: mean offset should be near zero across many samples
func test_distribution_mean_near_zero() -> void:
	var rng: RngService = RngService.new()
	add_child(rng)
	var base_dir := Vector2(1.0, 0.0)
	var sum_angle: float = 0.0
	var n: int = 500
	rng.seed_rng(12345)
	for i in range(n):
		var event := FlickEvent.new(base_dir, 1.0, 0)
		var result: Vector2 = ShotSpreadCalculation.apply_spread(event)
		sum_angle += rad_to_deg(base_dir.angle_to(result))
	# Mean should be within ±5° of zero (triangular distribution centred at 0)
	assert_float(absf(sum_angle / n)).is_less_equal(5.0)
	rng.queue_free()
