extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var tilemap: TileMap = $Ground


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_setup_camera_limits()


# Calcula os limites do mapa a partir da área usada do TileMap
# e aplica na Camera2D que está dentro do Player.
func _setup_camera_limits() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	if camera == null:
		push_warning("Camera2D não encontrada dentro do Player.")
		return

	var used_rect: Rect2i = tilemap.get_used_rect()
	var tile_size: Vector2i = tilemap.tile_set.tile_size

	# Converte a área de tiles (em "coordenadas de tile") pra pixels do mundo
	var map_position: Vector2 = tilemap.to_global(used_rect.position * tile_size)
	var map_size: Vector2 = Vector2(used_rect.size * tile_size)

	camera.limit_left = int(map_position.x)
	camera.limit_top = int(map_position.y)
	camera.limit_right = int(map_position.x + map_size.x)
	camera.limit_bottom = int(map_position.y + map_size.y)
