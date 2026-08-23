extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var tilemap: TileMap = $Ground

func _ready() -> void:
	# Espera um frame pra garantir que o TileMap já processou
	# todos os tiles antes de calcular o used_rect.
	call_deferred("_setup_camera_limits")


func _setup_camera_limits() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	if camera == null:
		push_warning("Camera2D não encontrada dentro do Player.")
		return

	var used_rect: Rect2i = tilemap.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		push_warning("TileMap sem tiles usados — limites de câmera não aplicados.")
		return

	var tile_size: Vector2i = tilemap.tile_set.tile_size

	# Converte os dois CANTOS do mapa (não largura/altura soltas) pra
	# coordenadas globais. Isso funciona certo mesmo se o TileMap tiver
	# escala, rotação ou posição diferente de (0,0).
	var local_top_left: Vector2 = Vector2(used_rect.position * tile_size)
	var local_bottom_right: Vector2 = Vector2((used_rect.position + used_rect.size) * tile_size)

	var global_top_left: Vector2 = tilemap.to_global(local_top_left)
	var global_bottom_right: Vector2 = tilemap.to_global(local_bottom_right)

	camera.limit_left = int(global_top_left.x)
	camera.limit_top = int(global_top_left.y)
	camera.limit_right = int(global_bottom_right.x)
	camera.limit_bottom = int(global_bottom_right.y)

	# Realinha a câmera dentro dos novos limites sem "pulo" visual.
	camera.reset_smoothing()

	print("Limites aplicados -> left: %s top: %s right: %s bottom: %s" % [
		camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom
	])
