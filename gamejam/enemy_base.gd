class_name EnemyBase
extends CharacterBody2D


enum EnemyState {
	IDLE,
	CHASE,
	HURT,
	ATTACKING,
	DEAD
}

@export_category("Movimento")
@export var move_speed := 45.0
@export var detection_range := 350.0
@export var stop_distance := 58.0

@export_category("Vida")
@export var max_health: int = 5

@export_category("Dano")
@export var contact_damage: int = 3

@export_category("Knockback")
@export var knockback_speed := 110.0
@export var knockback_duration := 0.16


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $BodyCollision
@onready var hurtbox_collision: CollisionShape2D = $Hurtbox/HurtboxCollision
@onready var contact_damage_area: Area2D = $ContactDamage
@onready var damage_collision: CollisionShape2D = $ContactDamage/DamageCollision
@onready var hurt_timer: Timer = $HurtTimer


var current_health: int
var state: EnemyState = EnemyState.IDLE
var target: Node2D
var knockback_velocity := Vector2.ZERO
var facing_direction := Vector2.DOWN


func _ready() -> void:
	current_health = max_health

	hurt_timer.one_shot = true
	hurt_timer.wait_time = knockback_duration
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)

	contact_damage_area.set("damage", contact_damage)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	find_player()


func _physics_process(delta: float) -> void:
	if state == EnemyState.DEAD:
		return

	if not is_instance_valid(target):
		find_player()

	if not is_instance_valid(target):
		velocity = Vector2.ZERO
		return

	match state:
		EnemyState.IDLE, EnemyState.CHASE:
			update_chase()
		
		EnemyState.HURT:
			velocity = knockback_velocity
			knockback_velocity = knockback_velocity.move_toward(
				Vector2.ZERO,
				700.0 * delta
			)
		EnemyState.ATTACKING:
			velocity = Vector2.ZERO
	move_and_slide()


func find_player() -> void:
	target = get_tree().get_first_node_in_group("player") as Node2D


func update_chase() -> void:
	var distance_to_player := global_position.distance_to(
		target.global_position
	)

	if distance_to_player > detection_range:
		state = EnemyState.IDLE
		velocity = Vector2.ZERO
		play_animation(get_directional_animation("idle"))
		return

	if distance_to_player <= stop_distance:
		state = EnemyState.IDLE
		velocity = Vector2.ZERO
		play_animation(get_directional_animation("idle"))
		return

	state = EnemyState.CHASE

	var direction := global_position.direction_to(
		target.global_position
	)

	velocity = direction * move_speed
	facing_direction = direction

	play_animation(get_directional_animation("walk"))


func get_directional_animation(prefix: String) -> StringName:
	# Decide se o movimento é mais horizontal ou vertical
	if abs(facing_direction.x) > abs(facing_direction.y):
		sprite.flip_h = facing_direction.x > 0
		return "%s_side" % prefix
	else:
		sprite.flip_h = false
		if facing_direction.y < 0:
			return "%s_up" % prefix
		else:
			return "%s_down" % prefix


func take_damage(amount: int, damage_source: Vector2) -> void:
	if state == EnemyState.DEAD:
		return

	current_health = max(current_health - amount, 0)
	print(get_script().get_global_name(), ": ", current_health, "/", max_health)

	if current_health <= 0:
		die()
		return
	cancel_attack()
	state = EnemyState.HURT

	var knockback_direction := (
		global_position - damage_source
	).normalized()

	knockback_velocity = knockback_direction * knockback_speed
	hurt_timer.start()

	play_hit_effect()


func play_hit_effect() -> void:
	sprite.modulate = Color(1.0, 0.25, 0.25)

	var tween := create_tween()
	tween.tween_property(
		sprite,
		"modulate",
		Color.WHITE,
		0.16
	)


func _on_hurt_timer_timeout() -> void:
	if state == EnemyState.HURT:
		state = EnemyState.IDLE
		knockback_velocity = Vector2.ZERO


func play_animation(animation_name: StringName) -> void:
	if sprite.animation != animation_name:
		sprite.play(animation_name)


func die() -> void:
	cancel_attack()
	state = EnemyState.DEAD
	velocity = Vector2.ZERO

	body_collision.set_deferred("disabled", true)
	hurtbox_collision.set_deferred("disabled", true)
	damage_collision.set_deferred("disabled", true)

	var tween := create_tween()

	tween.tween_property(
		sprite,
		"scale",
		Vector2.ZERO,
		0.25
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	tween.finished.connect(queue_free)
	
func cancel_attack() -> void:
	pass
