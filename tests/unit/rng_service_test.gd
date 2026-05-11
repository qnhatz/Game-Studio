# Example unit test — validates GdUnit4 is wired up correctly.
# Tests RngService determinism: seeded output must be reproducible.
extends GdUnitTestSuite

const RNG_SEED: int = 12345

func test_seeded_sequence_is_reproducible() -> void:
	# Two RNG instances with the same seed must produce identical sequences.
	var rng_a := RandomNumberGenerator.new()
	var rng_b := RandomNumberGenerator.new()
	rng_a.seed = RNG_SEED
	rng_b.seed = RNG_SEED

	for _i in range(10):
		assert_float(rng_a.randf()).is_equal(rng_b.randf())

func test_randf_range_returns_within_bounds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = RNG_SEED
	var lo: float = 0.0
	var hi: float = 1.0

	for _i in range(100):
		var value: float = rng.randf_range(lo, hi)
		assert_float(value).is_greater_equal(lo)
		assert_float(value).is_less_equal(hi)
