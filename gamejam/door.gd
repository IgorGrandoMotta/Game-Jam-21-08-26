extends Area2D

## Caminho do arquivo .tscn do próximo nível.
@export_file("*.tscn") var target_scene: String


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if target_scene.is_empty():
		push_warning("Door sem target_scene configurado: %s" % name)
		return

	SceneTransition.change_scene(target_scene)
