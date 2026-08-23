extends Area2D

@export var damage: int = 10

@onready var damage_cooldown: Timer = $DamageCooldown


func _physics_process(_delta: float) -> void:
	if not damage_cooldown.is_stopped():
		return

	for body in get_overlapping_bodies():
		if not body.is_in_group("player"):
			continue

		if (
			body.has_method("is_avoiding_ground_hazards")
			and body.is_avoiding_ground_hazards()
		):
			continue

		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
			damage_cooldown.start()
			break
			
