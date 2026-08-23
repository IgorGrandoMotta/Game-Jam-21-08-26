extends Area2D
class_name BossClaw

# ============================================
# ATAQUE DE GARRA
# Surge num ponto da parede, mostra um "telegraph" (aviso visual)
# e depois de um tempo desce/golpeia, causando dano se o jogador
# estiver na área.
# ============================================

@export var telegraph_time: float = 0.8   # tempo de aviso antes de bater
@export var strike_duration: float = 0.2  # quanto tempo o hitbox fica ativo
@export var damage: int = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	hitbox.disabled = true
	if sprite:
		sprite.play("telegraph")

	body_entered.connect(_on_body_entered)

	await get_tree().create_timer(telegraph_time).timeout
	_strike()


func _strike() -> void:
	if sprite:
		sprite.play("strike")
	hitbox.disabled = false

	await get_tree().create_timer(strike_duration).timeout
	hitbox.disabled = true

	if sprite:
		sprite.play("retreat")
		await sprite.animation_finished

	queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
