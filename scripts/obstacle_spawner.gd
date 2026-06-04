extends Node2D

# ObstacleSpawner — spawns obstacles at random intervals

const OBSTACLE_SCENE = preload("res://scenes/Obstacle.tscn")
const SPAWN_X: float = 560.0
const GROUND_Y: float = 700.0
const MIN_INTERVAL: float = 1.2
const MAX_INTERVAL: float = 2.8

@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.wait_time = randf_range(MIN_INTERVAL, MAX_INTERVAL)
	timer.start()
	timer.timeout.connect(_spawn_obstacle)

func _spawn_obstacle() -> void:
	if not GameManager.is_playing:
		return
	var obs = OBSTACLE_SCENE.instantiate()
	obs.position = Vector2(SPAWN_X, GROUND_Y)
	get_parent().add_child(obs)
	timer.wait_time = randf_range(MIN_INTERVAL, MAX_INTERVAL)
	timer.start()
