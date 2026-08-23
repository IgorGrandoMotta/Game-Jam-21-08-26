extends Area2D

@export_file("*.tscn")
var next_scene: String = "res://level_02.tscn"

@onready var lock_sprite: Sprite2D = $LockSprite

var changing_scene: bool = false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if changing_scene:
		return

	if not body.is_in_group("player"):
		return

	if not PlayerData.has_maze_key:
		print("A porta está trancada. Encontre a chave!")
		return

	changing_scene = true
	PlayerData.has_maze_key = false

	lock_sprite.visible = false

	print("Porta aberta!")

	get_tree().call_deferred(
		"change_scene_to_file",
		next_scene
	)
