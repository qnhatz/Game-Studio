class_name RngService
extends Node

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func seed_rng(value: int) -> void:
	_rng.seed = value


func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)
