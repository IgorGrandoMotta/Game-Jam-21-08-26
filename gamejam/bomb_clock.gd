class_name CreeperBomb
extends EnemyBase


@export_category("Movimento")
@export var speed_multiplier := 1.6

@export_category("Explosão")
@export var fuse_distance := 90.0
@export var fuse_time := 1.2
@export var blink_min_interval := 0.04
@export var blink_max_interval := 0.22
@export var explosion_lifetime := 0.5


@onready var explosion: Node = $Explosion
@onready var fuse_timer: Timer = Timer.new()


var is_fusing := false
var blink_tween: Tween


func _ready() -> void:
	super._ready()

	move_speed *= speed_multiplier

	fuse_timer.one_shot = true
	fuse_timer.wait_time = fuse_time
	fuse_timer.timeout.connect(_on_fuse_timer_timeout)
	add_child(fuse_timer)


func update_chase() -> void:
	if is_fusing:
		velocity = Vector2.ZERO
		return

	var distance_to_player := global_position.distance_to(
		target.global_position
	)

	if distance_to_player > detection_range:
		state = EnemyState.IDLE
		velocity = Vector2.ZERO
		play_animation(get_directional_animation("idle"))
		return

	if distance_to_player <= fuse_distance:
		start_fuse()
		return

	state = EnemyState.CHASE

	var direction := global_position.direction_to(
		target.global_position
	)

	velocity = direction * move_speed
	facing_direction = direction

	play_animation(get_directional_animation("walk"))


func start_fuse() -> void:
	if is_fusing:
		return

	is_fusing = true
	velocity = Vector2.ZERO
	play_animation(get_directional_animation("boom"))

	fuse_timer.start()
	start_blink()


func start_blink() -> void:
	# Pisca ficando mais rápido conforme o tempo do pavio passa
	blink_tween = create_tween()
	blink_tween.set_loops()

	var steps := 6
	for i in steps:
		var t := float(i) / float(steps - 1)
		var interval: float = lerp(blink_max_interval, blink_min_interval, t)

		blink_tween.tween_property(
			sprite, "modulate", Color(1.0, 0.3, 0.3), interval
		)
		blink_tween.tween_property(
			sprite, "modulate", Color.WHITE, interval
		)


func explode() -> void:
	if state == EnemyState.DEAD:
		return

	state = EnemyState.DEAD
	is_fusing = false
	velocity = Vector2.ZERO

	if blink_tween:
		blink_tween.kill()

	body_collision.set_deferred("disabled", true)
	hurtbox_collision.set_deferred("disabled", true)
	damage_collision.set_deferred("disabled", true)

	sprite.visible = false

	explosion.explode()

	# Espera a explosão terminar (animação/dano) antes de remover o nó,
	# já que $Explosion é filho e seria destruído junto com queue_free().
	await get_tree().create_timer(explosion_lifetime).timeout

	queue_free()


func _on_fuse_timer_timeout() -> void:
	explode()


func take_damage(amount: int, damage_source: Vector2) -> void:
	# Levar dano durante o pavio também pode detonar antes da hora,
	# se preferir isso, descomente a linha abaixo:
	# if is_fusing: explode(); return

	super.take_damage(amount, damage_source)
