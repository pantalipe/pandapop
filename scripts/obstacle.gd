extends Node2D

# Obstacle — moves left, kills player on contact, auto-destroys off screen

var speed: float = 300.0

@onready var collision = $Area2D

func _ready() -> void:
	# Match main scroll speed via GameManager signal or direct read
	collision.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Sync speed with main scene scroll speed
	var main = get_tree().get_first_node_in_group("main")
	if main:
		speed = main.scroll_speed

	position.x -= speed * delta

	if position.x < -80:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.die()
