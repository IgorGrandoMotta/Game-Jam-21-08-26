
extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var tilemap: TileMap = $Ground

@onready var wall_foreground: Sprite2D = $Wall/WallForeground
@onready var depth_point: Marker2D = $Player/DepthPoint
@onready var wall_material: ShaderMaterial = (
	wall_foreground.material as ShaderMaterial
)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerData.has_maze_key = false
	_setup_camera_limits()
	player.z_as_relative = false
	player.z_index = 2

	wall_foreground.z_as_relative = false
	wall_foreground.z_index = 3

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
	
func _process(_delta: float) -> void:
	var player_depth_y: float = depth_point.global_position.y

	wall_material.set_shader_parameter(
		"player_y",
		player_depth_y
	)

	update_object_depth(player_depth_y)
	
func update_object_depth(player_y: float) -> void:
	for object in get_tree().get_nodes_in_group("depth_sortable"):
		if not is_instance_valid(object):
			continue

		if not object is Node2D:
			continue

		var depth_object: Node2D = object as Node2D
		var object_y: float = depth_object.global_position.y

		# Ignora o Z do nó organizador/pai.
		depth_object.z_as_relative = false

		if object_y < player_y:
			depth_object.z_index = 1
		else:
			depth_object.z_index = 4
			
