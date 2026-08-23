extends Area2D

## Quantidade de vida restaurada ao coletar
@export var heal_amount: int = 20

## Tempo total (em segundos) até a ampulheta ficar cheia de novo.
## Na metade desse tempo, passa pelo estado "half" (meia vida).
@export var cooldown_time: float = 15.0

## Escala aplicada em cada animação. Ajuste os valores no Inspector
## caso os sprites tenham dimensões diferentes entre si.
@export var full_scale: Vector2 = Vector2.ONE
@export var half_scale: Vector2 = Vector2.ONE
@export var empty_scale: Vector2 = Vector2.ONE

## Deslocamento (offset) de cada animação, usado para compensar frames
## com tamanhos diferentes (ex: o frame "full" é 16x37 e os de areia são 16x16,
## então sem esse ajuste a pilha de areia "pula" de posição entre as animações).
@export var full_offset: Vector2 = Vector2(0, -12)
@export var half_offset: Vector2 = Vector2.ZERO
@export var empty_offset: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var cooldown_timer: Timer = $CooldownTimer

enum State { FULL, EMPTY, HALF }
var state: State = State.FULL


func _ready() -> void:
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)

	body_entered.connect(_on_body_entered)

	_enter_full_state()


func _on_body_entered(body: Node2D) -> void:
	if state != State.FULL:
		return

	if not body.has_method("heal"):
		return

	body.heal(heal_amount)
	_enter_empty_state()

	# Primeira metade do cooldown: de "empty" até "half"
	cooldown_timer.wait_time = cooldown_time / 2.0
	cooldown_timer.start()


func _on_cooldown_timer_timeout() -> void:
	match state:
		State.EMPTY:
			_enter_half_state()
			# Segunda metade do cooldown: de "half" até "full"
			cooldown_timer.wait_time = cooldown_time / 2.0
			cooldown_timer.start()

		State.HALF:
			_enter_full_state()


func _enter_empty_state() -> void:
	state = State.EMPTY
	collision_shape.set_deferred("disabled", true)
	animated_sprite.scale = empty_scale
	animated_sprite.offset = empty_offset
	animated_sprite.play("empty")


func _enter_half_state() -> void:
	state = State.HALF
	animated_sprite.scale = half_scale
	animated_sprite.offset = half_offset
	animated_sprite.play("half")


func _enter_full_state() -> void:
	state = State.FULL
	collision_shape.set_deferred("disabled", false)
	animated_sprite.scale = full_scale
	animated_sprite.offset = full_offset
	animated_sprite.play("full")
