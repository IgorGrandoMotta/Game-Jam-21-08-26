extends Area2D
class_name BossProjectile

@export var speed: float = 270.0
@export var reflected_speed: float = 410.0
@export var damage: int = 8
@export var lifetime: float = 6.0
@export_file("*.png") var normal_texture_path: String = "res://Imagens/BOSS/spr_projeteis_2.png"
@export_file("*.png") var special_texture_path: String = "res://Imagens/BOSS/spr_projeteis_1.png"

var direction: Vector2 = Vector2.RIGHT
var is_special: bool = false
var reflected: bool = false
var lived_time: float = 0.0

var visual: Sprite2D
var collision: CollisionShape2D


func _ready() -> void:
	add_to_group("boss_projectile")
	_build_if_needed()
	_configure_normal_collision()

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	_update_visual()


func setup(target_position: Vector2, special: bool) -> void:
	is_special = special
	var new_direction := target_position - global_position
	if new_direction.length_squared() > 0.01:
		direction = new_direction.normalized()
	_update_visual()


func _physics_process(delta: float) -> void:
	var current_speed := reflected_speed if reflected else speed
	global_position += direction * current_speed * delta
	rotation += delta * (10.0 if reflected else 6.0)

	lived_time += delta
	if lived_time >= lifetime:
		queue_free()


func get_damage() -> int:
	return 0 if reflected else damage


func _build_if_needed() -> void:
	collision = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		add_child(collision)

	if collision.shape == null:
		var shape := CircleShape2D.new()
		shape.radius = 11.0
		collision.shape = shape

	visual = get_node_or_null("Visual") as Sprite2D
	if visual == null:
		visual = Sprite2D.new()
		visual.name = "Visual"
		add_child(visual)


func _configure_normal_collision() -> void:
	# Ataque inimigo na camada 4. Detecta Hurtbox (2) e espada (3).
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(4, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(3, true)
	monitoring = true
	monitorable = true


func _configure_reflected_collision() -> void:
	# Rebatido passa para a camada da espada e procura Hurtbox inimiga (5).
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true)
	set_collision_mask_value(5, true)


func _on_area_entered(area: Area2D) -> void:
	if reflected:
		return

	if area.name == "AttackArea" or area.get_parent().name == "WeaponPivot":
		if is_special:
			_reflect()
		else:
			# A espada destroi tiros comuns, mas eles nao ferem o boss.
			queue_free()
		return

	if area.name == "Hurtbox" and area.get_parent().is_in_group("player"):
		call_deferred("queue_free")


func _reflect() -> void:
	reflected = true
	add_to_group("deflected_projectile")
	_configure_reflected_collision()

	var boss := get_tree().get_first_node_in_group("boss") as Node2D
	if boss != null:
		direction = (boss.global_position - global_position).normalized()
	else:
		direction = -direction

	lived_time = 0.0
	_update_visual()


func _update_visual() -> void:
	if visual == null:
		return

	var selected_path := special_texture_path if is_special else normal_texture_path
	if ResourceLoader.exists(selected_path):
		visual.texture = load(selected_path) as Texture2D

	if reflected:
		visual.modulate = Color(0.35, 1.0, 1.0, 1.0)
		visual.scale = Vector2(5.0, 5.0)
	elif is_special:
		visual.modulate = Color.WHITE
		visual.scale = Vector2(4.5, 4.5)
	else:
		visual.modulate = Color.WHITE
		visual.scale = Vector2(4.0, 4.0)
