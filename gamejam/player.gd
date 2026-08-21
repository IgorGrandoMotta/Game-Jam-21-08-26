extends CharacterBody2D

@export var walk_speed := 80.0
@export var dash_speed := 240.0
@export var dash_duration := 0.25
@export var dash_cooldown := 0.55

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_dashing := false
var can_dash := true

var facing_direction := Vector2.RIGHT
var dash_direction := Vector2.RIGHT


func _ready() -> void:
	sprite.play("idle")


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if not is_dashing and direction != Vector2.ZERO:
		facing_direction = direction.normalized()

	if Input.is_action_just_pressed("dash") and can_dash:
		var chosen_direction := direction

		if chosen_direction == Vector2.ZERO:
			chosen_direction = facing_direction

		start_dash(chosen_direction)

	if is_dashing:
		velocity = dash_direction * dash_speed
	else:
		velocity = direction * walk_speed
		update_animation(direction)

	move_and_slide()


func start_dash(direction: Vector2) -> void:
	is_dashing = true
	can_dash = false
	dash_direction = direction.normalized()

	update_flip(dash_direction)
	sprite.play("dash")

	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false

	await get_tree().create_timer(
		max(dash_cooldown - dash_duration, 0.0)
	).timeout

	can_dash = true


func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		if sprite.animation != "idle":
			sprite.play("idle")
	else:
		update_flip(direction)

		if sprite.animation != "walk":
			sprite.play("walk")


func update_flip(direction: Vector2) -> void:
	if direction.x != 0:
		sprite.flip_h = direction.x > 0
