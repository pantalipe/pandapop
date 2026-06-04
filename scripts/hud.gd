extends CanvasLayer

# HUD — live score and coin display

@onready var score_label: Label = $ScoreLabel
@onready var coin_label: Label = $CoinLabel

func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	_on_score_changed(GameManager.score)
	_on_coins_changed(GameManager.coins)

func _on_score_changed(value: int) -> void:
	score_label.text = str(value)

func _on_coins_changed(value: int) -> void:
	coin_label.text = "PP " + str(value)
