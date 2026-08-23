extends Area2D

@onready var collision: CollisionShape2D = $CollisionShape2D

var collected: bool = false


func _ready() -> void:
	monitoring = true
	monitorable = true

	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(1, true)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	print("Chave detectou: ", body.name)

	if collected:
		return

	if not body.is_in_group("player"):
		return

	collected = true
	PlayerData.has_maze_key = true

	print("CHAVE COLETADA: ", PlayerData.has_maze_key)

	collision.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	hide()
	queue_free()
