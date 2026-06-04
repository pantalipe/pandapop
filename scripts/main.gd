extends Node2D

# Main — game loop, obstacle spawning, scrolling ground

const INITIAL_SPEED: float = 300.0
const MAX_SPEED: float = 700.0
const SPEED_INCREMENT: float = 15.0  # per second

var scroll_speed: float = INITIAL_SPEED
var score_timer: float = 0.0

@onready var player = $Player
@onready var ground = $Ground
@onready var obstacle_spawner = $ObstacleSpawner
@onready var coin_spawner = $CoinSpawner
@onready var hud = $HUD
@onready var game_over_screen = $GameOverScreen

func _ready() -> void:
	GameManager.start_game()
	GameManager.game_over.connect(_on_game_over)
	player.died.connect(_on_player_died)
	game_over_screen.visible = false

func _process(delta: float) -> void:
	if not GameManager.is_playing:
		return

	# Increase speed over time
	scroll_speed = min(scroll_speed + SPEED_INCREMENT * delta, MAX_SPEED)

	# Score every 0.1s
	score_timer += delta
	if score_timer >= 0.1:
		score_timer = 0.0
		GameManager.add_score(1)

	# Scroll ground tiles
	for tile in ground.get_children():
		tile.position.x -= scroll_speed * delta
		if tile.position.x < -tile.get_rect().size.x:
			tile.position.x += tile.get_rect().size.x * 2

func _input(event: InputEvent) -> void:
	if not GameManager.is_playing:
		return
	if event is InputEventScreenTouch and event.pressed:
		player.try_jump()
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		player.try_jump()

func _on_player_died() -> void:
	GameManager.end_game()

func _on_game_over() -> void:
	game_over_screen.visible = true
	game_over_screen.show_score(GameManager.score, GameManager.highscore)

func restart() -> void:
	get_tree().reload_current_scene()
