extends Node2D

# CoinSpawner — spawns collectible PandaPoint coins

const COIN_SCENE = preload("res://scenes/Coin.tscn")
const SPAWN_X: float = 560.0
const MIN_Y: float = 500.0
const MAX_Y: float = 680.0
const MIN_INTERVAL: float = 2.0
const MAX_INTERVAL: float = 4.0

@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.wait_time = randf_range(MIN_INTERVAL, MAX_INTERVAL)
	timer.start()
	timer.timeout.connect(_spawn_coin)

func _spawn_coin() -> void:
	if not GameManager.is_playing:
		return
	# Spawn a line of 3-5 coins
	var count = randi_range(3, 5)
	for i in range(count):
		var coin = COIN_SCENE.instantiate()
		coin.position = Vector2(SPAWN_X + i * 55, randf_range(MIN_Y, MAX_Y))
		get_parent().add_child(coin)
	timer.wait_time = randf_range(MIN_INTERVAL, MAX_INTERVAL)
	timer.start()
