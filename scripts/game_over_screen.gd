extends CanvasLayer

# GameOverScreen — shown on death

@onready var score_label: Label = $VBox/ScoreLabel
@onready var highscore_label: Label = $VBox/HighscoreLabel
@onready var coins_label: Label = $VBox/CoinsLabel
@onready var restart_btn: Button = $VBox/RestartButton

func _ready() -> void:
	restart_btn.pressed.connect(_on_restart)

func show_score(score: int, highscore: int) -> void:
	score_label.text = "Score: " + str(score)
	highscore_label.text = "Best: " + str(highscore)
	coins_label.text = "PP Coins: " + str(GameManager.coins)

func _on_restart() -> void:
	var main = get_tree().get_first_node_in_group("main")
	if main:
		main.restart()
