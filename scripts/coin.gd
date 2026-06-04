extends Area2D

# Coin — collectible PandaPoint coin

var speed: float = 300.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	var main = get_tree().get_first_node_in_group("main")
	if main:
		speed = main.scroll_speed
	position.x -= speed * delta
	if position.x < -60:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameManager.collect_coin()
		queue_free()
