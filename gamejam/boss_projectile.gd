extends Area2D
class_name BossProjectile

# ============================================
# PROJÉTIL DO BOSS
# - Cor NORMAL: acerta o jogador, causa dano nele, NÃO pode ferir o boss.
# - Cor CORRETA ("is_correct"): se o jogador rebater (ex: com escudo/ataque),
#   o projétil vira "deflected" e passa a poder ferir o boss.
# ============================================

@export var speed: float = 180.0
@export var damage_to_player: int = 1

@export var normal_color: Color = Color(0.8, 0.2, 0.2)   # vermelho = comum
@export var correct_color: Color = Color(0.2, 0.6, 1.0)  # azul = precisa rebater

var direction: Vector2 = Vector2.ZERO
var is_correct: bool = false
var deflected: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func setup(target_pos: Vector2, correct: bool) -> void:
	direction = (target_pos - global_position).normalized()
	is_correct = correct
	_update_color()


func _update_color() -> void:
	if sprite:
		sprite.modulate = correct_color if is_correct else normal_color


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if deflected:
		# Já foi rebatido: só interessa acertar o boss (isso é tratado na hurtbox do boss)
		return

	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage_to_player)
		queue_free()


# Chame esta função a partir do script do jogador quando ele "rebater"
# (ex: um Area2D de escudo que detecta o projétil e chama deflect())
func deflect(new_direction: Vector2) -> void:
	if not is_correct:
		# Rebater um projétil errado não faz nada de especial — pode até destruir
		queue_free()
		return

	deflected = true
	direction = new_direction.normalized()
	speed *= 1.4  # opcional: acelera o projétil rebatido
	add_to_group("deflected_projectile")
	if sprite:
		sprite.modulate = Color(1, 1, 0.3)  # amarelo pra indicar "ativo/rebatido"
