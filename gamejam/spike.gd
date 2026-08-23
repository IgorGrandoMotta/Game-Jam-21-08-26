extends Area2D

@export var damage: int = 10


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if not body.is_in_group("player"):
			continue

		# Durante o dash o jogador passa pelos espinhos sem tomar dano.
		if body.has_method("is_dashing") and body.is_dashing():
			continue

		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
