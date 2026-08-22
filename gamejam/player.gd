extends CharacterBody2D


enum PlayerState {
	NORMAL,
	DASHING,
	KNOCKBACK,
	ATTACKING,
	DEAD
}


@export_category("Movimento")
@export var walk_speed := 80.0
@export_category("Dash")
@export var dash_speed := 240.0
@export var dash_duration := 0.25
@export var dash_cooldown := 0.55
@export_category("Vida")
@export var max_health: int = 5
@export var invulnerability_duration := 0.8
@export_category("Knockback")
@export var knockback_speed := 185.0
@export var knockback_duration := 0.18
@export var hit_shake_strength := 6.0
@export var hit_rotation_strength := 18.0
@export_category("Espada")
@export var sword_damage: int = 1
@export var attack_duration := 0.22
@export var attack_cooldown := 0.40
@export var attack_arc_degrees := 200.0
@export var attack_move_multiplier := 0.35

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var invulnerability_timer: Timer = $InvulnerabilityTimer
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var knockback_timer: Timer = $KnockbackTimer
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var sword_sprite: Sprite2D = $WeaponPivot/SwordSprite
@onready var attack_area: Area2D = $WeaponPivot/AttackArea
@onready var attack_collision: CollisionShape2D = $WeaponPivot/AttackArea/AttackCollision
@onready var attack_cooldown_timer: Timer = $AttackCooldown
@onready var sword_animation: AnimatedSprite2D = $WeaponPivot/SwordAnimation

signal health_changed(current_health: int, max_health: int)
signal died


var current_health: int
var state: PlayerState = PlayerState.NORMAL

var facing_direction := Vector2.RIGHT
var dash_direction := Vector2.RIGHT
var knockback_direction := Vector2.ZERO

var sprite_rest_position := Vector2.ZERO
var hit_tween: Tween

var attack_tween: Tween
var hit_targets: Array[Node] = []

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	sword_animation.visible = false
	current_health = max_health
	sprite_rest_position = sprite.position
	
	configure_combat_layers()
	configure_timers()

	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	knockback_timer.timeout.connect(_on_knockback_timer_timeout)
	attack_area.area_entered.connect(_on_attack_area_entered)

	sword_sprite.visible = true
	attack_collision.disabled = true
	sprite.play("idle_side")
	add_to_group("player")
	
func configure_timers() -> void:
	dash_timer.one_shot = true
	dash_timer.wait_time = dash_duration

	dash_cooldown_timer.one_shot = true
	dash_cooldown_timer.wait_time = dash_cooldown

	knockback_timer.one_shot = true
	knockback_timer.wait_time = knockback_duration

	invulnerability_timer.one_shot = true
	invulnerability_timer.wait_time = invulnerability_duration
	attack_cooldown_timer.one_shot = true
	attack_cooldown_timer.wait_time = attack_cooldown

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	if (
		state != PlayerState.ATTACKING
		and state != PlayerState.DEAD
	):
		update_weapon_aim()

	match state:
		PlayerState.NORMAL:
			if direction != Vector2.ZERO:
				facing_direction = direction.normalized()

			if (
				Input.is_action_just_pressed("attack")
				and attack_cooldown_timer.is_stopped()
			):
				start_sword_attack()

			elif (
				Input.is_action_just_pressed("dash")
				and dash_cooldown_timer.is_stopped()
			):
				var chosen_direction := direction

				if chosen_direction == Vector2.ZERO:
					chosen_direction = facing_direction

				start_dash(chosen_direction)

			else:
				velocity = direction * walk_speed
				update_animation(direction)

		PlayerState.DASHING:
			velocity = dash_direction * dash_speed

		PlayerState.KNOCKBACK:
			velocity = knockback_direction * knockback_speed

		PlayerState.ATTACKING:
			if (
				Input.is_action_just_pressed("dash")
				and dash_cooldown_timer.is_stopped()
			):
				var chosen_direction := direction

				if chosen_direction == Vector2.ZERO:
					chosen_direction = facing_direction

				cancel_sword_attack()
				start_dash(chosen_direction)

			else:
				velocity = direction * walk_speed * attack_move_multiplier
				update_animation(direction)
				check_sword_hits()

		PlayerState.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()
	check_contact_damage()

func start_dash(direction: Vector2) -> void:
	state = PlayerState.DASHING
	dash_direction = direction.normalized()
	velocity = dash_direction * dash_speed

	update_flip(dash_direction)
	sprite.play("dash")

	dash_timer.start()
	dash_cooldown_timer.start()


func _on_dash_timer_timeout() -> void:
	if state == PlayerState.DASHING:
		state = PlayerState.NORMAL
		velocity = Vector2.ZERO


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not invulnerability_timer.is_stopped():
		return

	if area.has_method("get_damage"):
		take_damage(area.get_damage(), area.global_position)


func take_damage(
	amount: int,
	damage_source: Vector2
) -> void:
	if state == PlayerState.DEAD:
		return

	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health, max_health)

	print("Vida: ", current_health, "/", max_health)

	if current_health <= 0:
		die()
		return

	invulnerability_timer.start()
	start_knockback(damage_source)
	play_hit_effect()

func start_knockback(damage_source: Vector2) -> void:
	cancel_sword_attack()

	var direction_before_hit := facing_direction

	if state == PlayerState.DASHING:
		direction_before_hit = dash_direction

	dash_timer.stop()
	state = PlayerState.KNOCKBACK

	var away_from_damage := global_position - damage_source

	if away_from_damage.length_squared() < 0.01:
		away_from_damage = -direction_before_hit

	knockback_direction = away_from_damage.normalized()
	velocity = knockback_direction * knockback_speed

	var frame_count := sprite.sprite_frames.get_frame_count("dash")
	var animation_fps := sprite.sprite_frames.get_animation_speed("dash")
	var animation_duration := float(frame_count) / animation_fps

	var reverse_speed: float = (
		animation_duration
		/ maxf(knockback_duration, 0.01)
	)

	sprite.play("dash", -reverse_speed, true)

	# Esta linha encerra o estado de knockback.
	knockback_timer.stop()
	knockback_timer.wait_time = knockback_duration
	knockback_timer.start()

func _on_knockback_timer_timeout() -> void:
	if state == PlayerState.KNOCKBACK:
		state = PlayerState.NORMAL
		velocity = Vector2.ZERO

	sprite.position = sprite_rest_position
	sprite.rotation_degrees = 0.0
	sprite.modulate = Color.WHITE

func play_hit_effect() -> void:
	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()

	sprite.position = sprite_rest_position
	sprite.rotation_degrees = 0.0
	sprite.modulate = Color(1.0, 0.15, 0.15)

	hit_tween = create_tween()

	var shake_steps := 6
	var step_time := knockback_duration / float(shake_steps + 1)

	for i in range(shake_steps):
		var side := -1.0 if i % 2 == 0 else 1.0
		var vertical_offset := 2.0 if i % 3 == 0 else -2.0

		hit_tween.tween_property(
			sprite,
			"position",
			sprite_rest_position + Vector2(
				side * hit_shake_strength,
				vertical_offset
			),
			step_time
		)

		hit_tween.parallel().tween_property(
			sprite,
			"rotation_degrees",
			side * hit_rotation_strength,
			step_time
		)

	hit_tween.tween_property(
		sprite,
		"position",
		sprite_rest_position,
		step_time
	)

	hit_tween.parallel().tween_property(
		sprite,
		"rotation_degrees",
		0.0,
		step_time
	)

	var color_tween := create_tween()
	color_tween.tween_property(
		sprite,
		"modulate",
		Color.WHITE,
		knockback_duration
	)

func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		play_idle_animation()
		return

	# Prioriza a animação lateral nas diagonais.
	if absf(direction.x) >= absf(direction.y):
		update_flip(direction)
		play_animation_if_different("walk_side")

	elif direction.y < 0:
		sprite.flip_h = false
		play_animation_if_different("walk_up")

	else:
		sprite.flip_h = false
		play_animation_if_different("walk_down")

func update_flip(direction: Vector2) -> void:
	if direction.x != 0:
		sprite.flip_h = direction.x > 0


func die() -> void:
	cancel_sword_attack()
	state = PlayerState.DEAD
	velocity = Vector2.ZERO

	dash_timer.stop()
	knockback_timer.stop()

	hurtbox.set_deferred("monitoring", false)
	sprite.modulate = Color(0.35, 0.35, 0.35)

	died.emit()
	print("O jogador morreu!")
	
func play_idle_animation() -> void:
	if absf(facing_direction.x) >= absf(facing_direction.y):
		play_animation_if_different("idle_side")

	elif facing_direction.y < 0:
		sprite.flip_h = false
		play_animation_if_different("idle_up")

	else:
		sprite.flip_h = false
		play_animation_if_different("idle_down")

func play_animation_if_different(animation_name: StringName) -> void:
	if sprite.animation != animation_name:
		sprite.play(animation_name)

func start_sword_attack() -> void:
	var attack_direction := get_global_mouse_position() - global_position

	if attack_direction.length_squared() < 0.01:
		attack_direction = facing_direction

	attack_direction = attack_direction.normalized()

	var target_angle := attack_direction.angle()
	var half_arc := deg_to_rad(attack_arc_degrees * 0.5)
	var attack_on_right := attack_direction.x >= 0.0
	var swing_direction := 1.0 if attack_on_right else -1.0

	# Espelha o efeito para o rastro continuar atrás da lâmina.
	sword_animation.flip_h = attack_on_right

	var start_angle := target_angle - half_arc * swing_direction
	var end_angle := target_angle + half_arc * swing_direction
	
	state = PlayerState.ATTACKING
	hit_targets.clear()

	if attack_tween and attack_tween.is_valid():
		attack_tween.kill()

	weapon_pivot.rotation = start_angle
	sword_sprite.visible = false
	sword_animation.visible = true

	var frame_count := sword_animation.sprite_frames.get_frame_count("attack")
	var animation_fps := sword_animation.sprite_frames.get_animation_speed("attack")
	var animation_duration := float(frame_count) / animation_fps

	var animation_speed: float = (
		animation_duration
		/ maxf(attack_duration, 0.01)
	)

	sword_animation.stop()
	sword_animation.play("attack", animation_speed)

	attack_collision.set_deferred("disabled", false)

	attack_cooldown_timer.start()

	attack_tween = create_tween()

	attack_tween.tween_property(
		weapon_pivot,
		"rotation",
		end_angle,
		attack_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	attack_tween.finished.connect(finish_sword_attack)


func finish_sword_attack() -> void:
	sword_sprite.visible = true
	sword_animation.stop()
	sword_animation.visible = false
	sword_sprite.visible = true
	attack_collision.set_deferred("disabled", true)
	hit_targets.clear()

	if state == PlayerState.ATTACKING:
		state = PlayerState.NORMAL


func cancel_sword_attack() -> void:
	if attack_tween and attack_tween.is_valid():
		attack_tween.kill()

	sword_sprite.visible = true
	sword_animation.stop()
	sword_animation.visible = false

	attack_collision.set_deferred("disabled", true)
	hit_targets.clear()

func _on_attack_area_entered(area: Area2D) -> void:
	try_sword_hit(area)


func check_sword_hits() -> void:
	for area in attack_area.get_overlapping_areas():
		try_sword_hit(area)


func try_sword_hit(area: Area2D) -> void:
	if state != PlayerState.ATTACKING:
		return

	var target := area.get_parent()

	if target == self:
		return

	if target in hit_targets:
		return

	if target.has_method("take_damage"):
		hit_targets.append(target)
		target.take_damage(sword_damage, global_position)

func update_weapon_aim() -> void:
	var mouse_direction := get_global_mouse_position() - global_position

	if mouse_direction.length_squared() < 0.01:
		return

	weapon_pivot.rotation = mouse_direction.angle()

	# Atrás do personagem quando aponta para cima;
	# na frente quando aponta para baixo.
	if mouse_direction.y < 0:
		weapon_pivot.z_index = 1
	else:
		weapon_pivot.z_index = 1

func check_contact_damage() -> void:
	if state == PlayerState.DEAD:
		return

	if not invulnerability_timer.is_stopped():
		return

	for area in hurtbox.get_overlapping_areas():
		if area.has_method("get_damage"):
			take_damage(area.get_damage(), area.global_position)
			break

func configure_combat_layers() -> void:
	# Hurtbox do jogador: camada 2, detecta dano na camada 4.
	hurtbox.collision_layer = 0
	hurtbox.collision_mask = 0
	hurtbox.set_collision_layer_value(2, true)
	hurtbox.set_collision_mask_value(4, true)
	hurtbox.monitoring = true
	hurtbox.monitorable = true

	# Espada: camada 3, detecta Hurtbox inimiga na camada 5.
	attack_area.collision_layer = 0
	attack_area.collision_mask = 0
	attack_area.set_collision_layer_value(3, true)
	attack_area.set_collision_mask_value(5, true)
	attack_area.monitoring = true
	attack_area.monitorable = true
	
