extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var tilemap: TileMap = $Ground
@onready var boss: Node = $Boss

var boss_bar: ProgressBar


func _ready() -> void:
	call_deferred("_setup_camera_limits")
	_create_boss_bar()

	if boss.has_signal("health_changed"):
		boss.connect("health_changed", _on_boss_health_changed)
	if boss.has_signal("defeated"):
		boss.connect("defeated", _on_boss_defeated)

	_on_boss_health_changed(
		int(boss.get("current_health")),
		int(boss.get("max_health"))
	)


func _setup_camera_limits() -> void:
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null or tilemap.tile_set == null:
		return

	var used_rect: Rect2i = tilemap.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return

	var tile_size: Vector2i = tilemap.tile_set.tile_size
	var local_top_left := Vector2(used_rect.position * tile_size)
	var local_bottom_right := Vector2((used_rect.position + used_rect.size) * tile_size)
	var global_top_left := tilemap.to_global(local_top_left)
	var global_bottom_right := tilemap.to_global(local_bottom_right)

	camera.limit_left = int(global_top_left.x)
	camera.limit_top = int(global_top_left.y)
	camera.limit_right = int(global_bottom_right.x)
	camera.limit_bottom = int(global_bottom_right.y)
	camera.reset_smoothing()


func _create_boss_bar() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)

	boss_bar = ProgressBar.new()
	boss_bar.name = "BossHealthBar"
	boss_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_bar.position = Vector2(-120.0, 18.0)
	boss_bar.size = Vector2(240.0, 20.0)
	boss_bar.show_percentage = false
	layer.add_child(boss_bar)

	var title := Label.new()
	title.text = "CUCKOO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0.0, -18.0)
	title.size = Vector2(240.0, 18.0)
	boss_bar.add_child(title)


func _on_boss_health_changed(current: int, maximum: int) -> void:
	if boss_bar == null:
		return
	boss_bar.max_value = maximum
	boss_bar.value = current


func _on_boss_defeated() -> void:
	if boss_bar != null:
		boss_bar.visible = false

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var victory := Label.new()
	victory.text = "VOCE DERROTOU O CUCKOO!"
	victory.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	victory.add_theme_font_size_override("font_size", 28)
	layer.add_child(victory)

	# Se voces ja tiverem uma cena de creditos com este nome, entra nela.
	await get_tree().create_timer(3.0).timeout
	if ResourceLoader.exists("res://credits.tscn"):
		get_tree().change_scene_to_file("res://credits.tscn")
