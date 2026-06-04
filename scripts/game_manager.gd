extends Node

# GameManager — singleton (autoload)
# Handles score, coins, highscore and game state

signal score_changed(value: int)
signal coins_changed(value: int)
signal game_over

var score: int = 0
var coins: int = 0
var highscore: int = 0
var session_coins: int = 0  # coins collected this run
var is_playing: bool = false

const SAVE_PATH = "user://save.dat"

func _ready() -> void:
	load_data()

func start_game() -> void:
	score = 0
	session_coins = 0
	is_playing = true
	emit_signal("score_changed", score)
	emit_signal("coins_changed", coins)

func add_score(amount: int) -> void:
	score += amount
	if score > highscore:
		highscore = score
		save_data()
	emit_signal("score_changed", score)

func collect_coin() -> void:
	session_coins += 1
	coins += 1
	save_data()
	emit_signal("coins_changed", coins)

func end_game() -> void:
	is_playing = false
	save_data()
	emit_signal("game_over")

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		save_data()
		emit_signal("coins_changed", coins)
		return true
	return false

func save_data() -> void:
	var data = {
		"highscore": highscore,
		"coins": coins
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()

func load_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			file.close()
			if data:
				highscore = data.get("highscore", 0)
				coins = data.get("coins", 0)
