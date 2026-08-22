class_name ExplosionEffect
extends Area2D


@export_category("Dano")
@export var damage: int = 3
@export var explosion_radius: float = 150.0:
	set(value):
		explosion_radius = value
		_update_radius()

@export_category("Animação")
@export var animation_name: StringName = "explosion"
@export var flash_duration: float = 0.12
@export var damage_window: float = 0.1


@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Fica sempre monitorando, mas com a shape desabilitada até explodir.
	# Alternar "disabled" é mais confiável que alternar "monitoring" na
	# hora H, e usar sinais evita problemas de timing com get_overlapping_bodies().
	monitoring = true
	collision_shape.disabled = true
	sprite.visible = false

	_update_radius()

	sprite.animation_finished.connect(_on_animation_finished)
	body_entered.connect(_on_body_entered)


func _update_radius() -> void:
	# Ajusta o raio da área de dano (precisa que o CollisionShape2D
	# esteja usando um CircleShape2D no editor)
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = explosion_radius


func explode() -> void:
	sprite.visible = true
	sprite.play(animation_name)

	flash_white()

	collision_shape.set_deferred("disabled", false)

	# Deixa a área de dano ativa só por uma janela curta, pra não
	# continuar causando dano enquanto a animação ainda está tocando
	await get_tree().create_timer(damage_window).timeout

	collision_shape.set_deferred("disabled", true)


func flash_white() -> void:
	# Pisca branco forte (acima de 1.0 = mais brilhante que o normal)
	# e volta à cor original rapidamente, simulando o clarão do impacto
	sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, flash_duration)


func _on_body_entered(body: Node2D) -> void:
	# Evita que a explosão cause dano em quem a spawnou (o próprio
	# CreeperBomb), já que a Area2D é filha do CharacterBody2D dele
	# e acaba sobrepondo o próprio BodyCollision.
	if body == owner:
		return

	if body.has_method("take_damage"):
		# Ajuste os parâmetros aqui caso o take_damage() do seu
		# Player tenha uma assinatura diferente
		body.take_damage(damage, global_position)


func _on_animation_finished() -> void:
	monitoring = false
