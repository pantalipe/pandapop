extends CharacterBody2D

# Player — panda character
# Tap to jump, double jump allowed

signal died

const GRAVITY: float = 1800.0
const JUMP_FORCE: float = -700.0
const DOUBLE_JUMP_FORCE: float = -600.0
const MOVE_SPEED: float = 0.0  # world moves, player stays on X

var jumps_remaining: int = 2
var is_alive: bool = true

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Apply gravity
	velocity.y += GRAVITY * delta

	# Move and slide handles collision
	move_and_slide()

	# Reset jumps when on floor
	if is_on_floor():
		jumps_remaining = 2
		if velocity.y >= 0:
			anim.play("idle")
	else:
		if velocity.y < 0:
			anim.play("jump")
		else:
			anim.play("fall")

func try_jump() -> void:
	if not is_alive:
		return
	if jumps_remaining > 0:
		if jumps_remaining == 2:
			velocity.y = JUMP_FORCE
		else:
			velocity.y = DOUBLE_JUMP_FORCE
		jumps_remaining -= 1

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	anim.play("die")
	emit_signal("died")
