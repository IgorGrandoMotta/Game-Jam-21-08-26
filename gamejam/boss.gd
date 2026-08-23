extends CharacterBody2D
class_name Boss

signal health_changed(current: int, maximum: int)
signal defeated

@export_group("Vida")
@export var max_health: int = 20

@export_group("Ritmo")
@export var time_between_attacks: float = 1.35
@export var telegraph_time: float = 0.48

@export_group("Cordas")
@export var cord_damage: int = 10
@export var cord_spacing: float = 105.0
@export var cord_hit_width: float = 30.0
@export var claw_visual_scale: Vector2 = Vector2(1.5, 2.2)
@export_file("*.png") var claw_texture_path: String = "res://Imagens/BOSS/garrasboss.png"

@export_group("Projeteis")
@export var projectile_damage: int = 8
@export var projectiles_per_burst: int = 6
@export var time_between_shots: float = 0.18
@export_range(0.0, 1.0) var special_projectile_chance: float = 0.32
@export_file("*.png") var cuco_loop_texture_path: String = "res://Imagens/BOSS/cucoloopboss.png"

@export_group("Invocacao")
@export_file("*.tscn") var big_clock_path: String = "res://BigClock.tscn"
@export_file("*.tscn") var bomb_clock_path: String = "res://BombClock.tscn"
@export var max_summons_alive: int = 4

enum State { IDLE, ATTACKING, DEAD }

const PROJECTILE_SCRIPT: Script = preload("res://boss_projectile.gd")

var current_health: int
var state: State = State.IDLE
var player: Node2D
var attack_number: int = 0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var body_collision: CollisionShape2D = $BodyCollision
@onready var attack_timer: Timer = $AttackTimer


func _ready() -> void:
	add_to_group("boss")
	current_health = max_health

	# Na cena recebida, o Boss estava em (0,0) e somente o sprite havia
	# sido levado ate a arena. Isto coloca o corpo inteiro no lugar do sprite.
	_fix_old_scene_position()
	_add_cuco_loop_animation()
	_configure_collisions()
	_remove_old_attack_examples()
	_find_player()

	attack_timer.one_shot = true
	attack_timer.wait_time = time_between_attacks
	if not attack_timer.timeout.is_connected(_on_attack_timer_timeout):
		attack_timer.timeout.connect(_on_attack_timer_timeout)

	if not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	_play_if_exists(&"idle")
	attack_timer.start(0.8)
	health_changed.emit(current_health, max_health)


func _fix_old_scene_position() -> void:
	if global_position.is_equal_approx(Vector2.ZERO) and sprite.position.length_squared() > 4096.0:
		var correct_world_position: Vector2 = sprite.global_position
		global_position = correct_world_position
		sprite.position = Vector2.ZERO


func _configure_collisions() -> void:
	# Corpo do boss: bloqueia o Player, mas o boss permanece parado.
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(4, true)
	set_collision_mask_value(1, true)

	var visual_size := Vector2(120.0, 140.0)
	if sprite.sprite_frames != null and sprite.sprite_frames.get_frame_count(&"idle") > 0:
		var texture := sprite.sprite_frames.get_frame_texture(&"idle", 0)
		if texture != null:
			visual_size = texture.get_size() * sprite.scale.abs()

	if body_collision.shape == null:
		var body_shape := RectangleShape2D.new()
		body_shape.size = Vector2(
			maxf(56.0, visual_size.x * 0.48),
			maxf(64.0, visual_size.y * 0.52)
		)
		body_collision.shape = body_shape

	# Hurtbox inimiga: a espada do Player procura a camada 5.
	hurtbox.collision_layer = 0
	hurtbox.collision_mask = 0
	hurtbox.set_collision_layer_value(5, true)
	hurtbox.set_collision_mask_value(3, true)
	hurtbox.monitoring = true
	hurtbox.monitorable = true

	var hurtbox_collision := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if hurtbox_collision == null:
		hurtbox_collision = CollisionShape2D.new()
		hurtbox_collision.name = "CollisionShape2D"
		hurtbox.add_child(hurtbox_collision)

	if hurtbox_collision.shape == null:
		var hurt_shape := RectangleShape2D.new()
		hurt_shape.size = Vector2(
			maxf(70.0, visual_size.x * 0.62),
			maxf(80.0, visual_size.y * 0.66)
		)
		hurtbox_collision.shape = hurt_shape


func _add_cuco_loop_animation() -> void:
	if sprite.sprite_frames == null or not ResourceLoader.exists(cuco_loop_texture_path):
		return

	var frames := sprite.sprite_frames
	if frames.has_animation(&"CucoLoop"):
		frames.remove_animation(&"CucoLoop")
	frames.add_animation(&"CucoLoop")
	frames.set_animation_loop(&"CucoLoop", true)
	frames.set_animation_speed(&"CucoLoop", 8.0)

	var sheet := load(cuco_loop_texture_path) as Texture2D
	if sheet == null:
		return

	# cucoloopboss.png: grade 3x3, com oito quadros usados.
	var frame_size := Vector2(256.0, 208.0)
	for index in range(8):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(
			Vector2(index % 3, floori(index / 3.0)) * frame_size,
			frame_size
		)
		frames.add_frame(&"CucoLoop", atlas)


func _remove_old_attack_examples() -> void:
	# Estes dois nos soltos eram apenas exemplos e nao devem ficar na arena.
	for path in ["../BossProjectile", "../BossClaw"]:
		var old_node := get_node_or_null(path)
		if old_node != null:
			old_node.queue_free()


func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		player = get_node_or_null("../Player") as Node2D


func _on_attack_timer_timeout() -> void:
	if state != State.IDLE:
		return

	_find_player()
	if player == null:
		attack_timer.start(0.5)
		return

	state = State.ATTACKING

	# Ordem rotativa garante que os tres ataques aparecam na luta.
	match attack_number % 3:
		0:
			await _attack_cords()
		1:
			await _attack_summon()
		2:
			await _attack_projectile_burst()

	attack_number += 1
	_finish_attack()


# ATAQUE 1: tres cordas verticais usando garrasboss.png.
func _attack_cords() -> void:
	var target_x: float = player.global_position.x
	var cord_x_positions: Array[float] = [
		target_x - cord_spacing,
		target_x,
		target_x + cord_spacing
	]
	var cords: Array[Sprite2D] = []
	var claw_texture := load(claw_texture_path) as Texture2D

	for x in cord_x_positions:
		var cord := Sprite2D.new()
		cord.texture = claw_texture
		cord.region_enabled = true
		# Metade esquerda de garrasboss.png = corda vertical.
		cord.region_rect = Rect2(0.0, 0.0, 256.0, 208.0)
		cord.global_position = Vector2(x, player.global_position.y)
		cord.scale = claw_visual_scale
		cord.modulate = Color(1.0, 0.18, 0.12, 0.42)
		cord.z_index = 30
		get_tree().current_scene.add_child(cord)
		cords.append(cord)

	await _play_fitted(&"Sobe garra", telegraph_time)
	if state == State.DEAD:
		_free_cords(cords)
		return

	_play_if_exists(&"Loop garra")
	for cord in cords:
		if is_instance_valid(cord):
			cord.modulate = Color.WHITE

	for x in cord_x_positions:
		if absf(player.global_position.x - x) <= cord_hit_width:
			_damage_player(cord_damage, Vector2(x, player.global_position.y))
			break

	await get_tree().create_timer(0.20).timeout
	_free_cords(cords)


# ATAQUE 2: um BigClock e um TimeBomb, respeitando o limite da arena.
func _attack_summon() -> void:
	_play_if_exists(&"idle")

	var alive_summons: int = get_tree().get_nodes_in_group("boss_summon").size()
	if alive_summons >= max_summons_alive:
		await get_tree().create_timer(0.35).timeout
		return

	var scene_paths: Array[String] = [big_clock_path, bomb_clock_path]
	var offsets: Array[Vector2] = [Vector2(-170.0, 70.0), Vector2(170.0, 70.0)]

	for i in range(scene_paths.size()):
		if get_tree().get_nodes_in_group("boss_summon").size() >= max_summons_alive:
			break
		if not ResourceLoader.exists(scene_paths[i]):
			push_warning("Cena de inimigo nao encontrada: " + scene_paths[i])
			continue

		var packed := load(scene_paths[i]) as PackedScene
		if packed == null:
			continue

		var enemy := packed.instantiate() as Node2D
		get_tree().current_scene.add_child(enemy)
		enemy.add_to_group("boss_summon")
		enemy.global_position = player.global_position + offsets[i]
		await get_tree().create_timer(0.22).timeout

	await get_tree().create_timer(0.30).timeout


# ATAQUE 3: rajada. O projetil amarelo pode ser rebatido pela espada.
func _attack_projectile_burst() -> void:
	await _play_fitted(&"CucoVai", 0.55)
	_play_if_exists(&"CucoLoop")

	for i in range(projectiles_per_burst):
		if state == State.DEAD or player == null:
			return

		var is_special: bool = randf() < special_projectile_chance
		# A ultima bala vira especial se nenhuma das anteriores precisar ser.
		if i == projectiles_per_burst - 1:
			is_special = true
		_spawn_projectile(is_special)
		await get_tree().create_timer(time_between_shots).timeout

	await _play_fitted(&"CucoVolta", 0.50)


func _spawn_projectile(is_special: bool) -> void:
	var projectile := Area2D.new()
	projectile.name = "SpecialProjectile" if is_special else "BossProjectile"
	projectile.set_script(PROJECTILE_SCRIPT)
	get_tree().current_scene.add_child(projectile)

	var direction_to_player := (player.global_position - global_position).normalized()
	projectile.global_position = global_position + direction_to_player * 72.0
	projectile.set("damage", projectile_damage)
	projectile.call("setup", player.global_position, is_special)


func _finish_attack() -> void:
	if state == State.DEAD:
		return
	state = State.IDLE
	_play_if_exists(&"idle")
	attack_timer.start(time_between_attacks)


func _damage_player(amount: int, source: Vector2) -> void:
	if player != null and player.has_method("take_damage"):
		player.call("take_damage", amount, source)


func _free_cords(cords: Array[Sprite2D]) -> void:
	for cord in cords:
		if is_instance_valid(cord):
			cord.queue_free()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not area.is_in_group("deflected_projectile"):
		return
	take_damage(2, area.global_position)
	area.queue_free()


# Compativel com a espada do Player, que envia dano e posicao da origem.
func take_damage(amount: int, _damage_source: Vector2 = Vector2.ZERO) -> void:
	if state == State.DEAD or amount <= 0:
		return

	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	_flash_hit()

	if current_health <= 0:
		_die()


func _flash_hit() -> void:
	var tween := create_tween()
	sprite.modulate = Color(1.0, 0.25, 0.25)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.14)


func _die() -> void:
	if state == State.DEAD:
		return

	state = State.DEAD
	attack_timer.stop()
	velocity = Vector2.ZERO
	body_collision.set_deferred("disabled", true)
	hurtbox.set_deferred("monitoring", false)
	_play_if_exists(&"CucoVolta")
	defeated.emit()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 1.0).set_trans(Tween.TRANS_BACK)
	await tween.finished
	queue_free()


func _play_if_exists(animation_name: StringName) -> void:
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)


func _play_fitted(animation_name: StringName, desired_duration: float) -> void:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation_name):
		await get_tree().create_timer(desired_duration).timeout
		return

	var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
	var fps := sprite.sprite_frames.get_animation_speed(animation_name)
	var normal_duration := float(frame_count) / maxf(fps, 0.01)
	var custom_speed := normal_duration / maxf(desired_duration, 0.01)
	sprite.play(animation_name, custom_speed)
	await get_tree().create_timer(desired_duration).timeout
