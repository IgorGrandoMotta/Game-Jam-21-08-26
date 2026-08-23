extends Area2D

var collected := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return

	collected = true
	PlayerData.has_maze_key = true

	get_tree().call_group("maze_exit", "unlock")
	queue_free()
