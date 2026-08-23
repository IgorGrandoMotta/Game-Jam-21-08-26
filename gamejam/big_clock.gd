extends EnemyBase


const TONGUE_EXTENSION := [
	0.0,
	0.15,
	0.45,
	0.75,
	0.95,
	1.0,
	1.0,
	0.80,
	0.50,
	0.20,
	0.0
]


@export_category("Linguada")
@export var attack_range := 100.0
@export var attack_cooldown_time := 1.2
@export var tongue_damage: int = 10
@export var tongue_range := 82.0
@export var tongue_width := 20.0
@export var hit_start_frame: int = 3
@export var hit_end_frame: int = 7
@export_category("Origem da língua")
@export var side_mouth_offset := Vector2(20, -6)
@export var up_mouth_offset := Vector2(0, -30)
@export var down_mouth_offset := Vector2(0, 30)
@export_category("Alinhamento do sprite")
@export var sprite_default_x := -33.0
@export var sprite_mirrored_x := 33.0
@export var sprite_position_y := -2.0
@export_category("Posicionamento")
@export var alignment_tolerance := 14.0

@onready var attack_origin: Marker2D = $AttackOrigin
@onready var tongue_attack: Area2D = $AttackOrigin/TongueAttack
@onready var tongue_collision: CollisionShape2D = (
	$AttackOrigin/TongueAttack/TongueCollision
)
@onready var attack_cooldown: Timer = $AttackCooldown


var last_direction := Vector2.DOWN
var locked_attack_direction := Vector2.DOWN


func _ready() -> void:
	super._ready()

	attack_cooldown.one_shot = true
	attack_cooldown.wait_time = attack_cooldown_time

	tongue_attack.monitoring = true
	tongue_attack.monitorable = true
	tongue_attack.set("damage", tongue_damage)

	# Cada BigClock recebe sua própria Shape.
	tongue_collision.shape = tongue_collision.shape.duplicate()
	tongue_collision.disabled = true

	sprite.frame_changed.connect(_on_attack_frame_changed)
	sprite.animation_finished.connect(_on_attack_animation_finished)

	play_directional_animation("idle", Vector2.DOWN)


func update_chase() -> void:
	var offset_to_player := (
		target.global_position - global_position
	)

	if offset_to_player.length() > detection_range:
		state = EnemyState.IDLE
		velocity = Vector2.ZERO

		play_directional_animation(
			"idle",
			last_direction
		)
		return

	var attack_direction := get_aligned_attack_direction(
		offset_to_player
	)

	# Está alinhado e dentro do alcance.
	if attack_direction != Vector2.ZERO:
		velocity = Vector2.ZERO
		last_direction = attack_direction

		if attack_cooldown.is_stopped():
			start_tongue_attack(attack_direction)
		else:
			state = EnemyState.IDLE

			play_directional_animation(
				"idle",
				last_direction
			)

		return

	# Ainda não está alinhado: move somente em um eixo.
	var move_direction := get_lane_move_direction(
		offset_to_player
	)

	state = EnemyState.CHASE
	velocity = move_direction * move_speed
	last_direction = move_direction

	play_directional_animation(
		"walk",
		move_direction
	)

func start_tongue_attack(direction: Vector2) -> void:
	if state == EnemyState.DEAD:
		return

	state = EnemyState.ATTACKING
	velocity = Vector2.ZERO

	locked_attack_direction = get_cardinal_direction(direction)
	last_direction = locked_attack_direction

	configure_attack_origin(locked_attack_direction)
	update_tongue_hitbox(0.0)

	play_directional_animation(
		"attack",
		locked_attack_direction
	)


func configure_attack_origin(direction: Vector2) -> void:
	if direction == Vector2.LEFT:
		attack_origin.position = Vector2(
			-side_mouth_offset.x,
			side_mouth_offset.y
		)

	elif direction == Vector2.RIGHT:
		attack_origin.position = side_mouth_offset

	elif direction == Vector2.UP:
		attack_origin.position = up_mouth_offset

	else:
		attack_origin.position = down_mouth_offset

	attack_origin.rotation = direction.angle()


func _on_attack_frame_changed() -> void:
	if state != EnemyState.ATTACKING:
		return

	var frame_index: int = mini(
		sprite.frame,
		TONGUE_EXTENSION.size() - 1
	)

	var extension: float = TONGUE_EXTENSION[frame_index]

	update_tongue_hitbox(extension)


func update_tongue_hitbox(extension: float) -> void:
	var current_length := tongue_range * extension

	var rectangle := (
		tongue_collision.shape as RectangleShape2D
	)

	rectangle.size = Vector2(
		maxf(current_length, 1.0),
		tongue_width
	)

	tongue_collision.position = Vector2(
		current_length * 0.5,
		0
	)

	var hitbox_active := (
		sprite.frame >= hit_start_frame
		and sprite.frame <= hit_end_frame
		and extension > 0.0
	)

	tongue_collision.set_deferred(
		"disabled",
		not hitbox_active
	)


func _on_attack_animation_finished() -> void:
	if state != EnemyState.ATTACKING:
		return

	update_tongue_hitbox(0.0)

	state = EnemyState.IDLE
	attack_cooldown.start()

	play_directional_animation(
		"idle",
		last_direction
	)


func cancel_attack() -> void:
	update_tongue_hitbox(0.0)

	if state == EnemyState.ATTACKING:
		attack_cooldown.start()


func play_directional_animation(
	animation_prefix: String,
	direction: Vector2
) -> void:
	var horizontal := (
		absf(direction.x) >= absf(direction.y)
	)

	if horizontal:
		var facing_right := direction.x > 0

		sprite.flip_h = facing_right

		if facing_right:
			sprite.position = Vector2(
				sprite_mirrored_x,
				sprite_position_y
			)
		else:
			sprite.position = Vector2(
				sprite_default_x,
				sprite_position_y
			)
	else:
		sprite.flip_h = false
		sprite.position = Vector2(
			sprite_default_x,
			sprite_position_y
		)

	var animation_name := get_directional_animation_name(
		animation_prefix,
		direction
	)

	play_animation(animation_name)


func get_directional_animation_name(
	animation_prefix: String,
	direction: Vector2
) -> StringName:
	if absf(direction.x) >= absf(direction.y):
		return StringName(animation_prefix)

	if direction.y < 0:
		return StringName(animation_prefix + " up")

	return StringName(animation_prefix + " down")


func get_cardinal_direction(direction: Vector2) -> Vector2:
	if absf(direction.x) >= absf(direction.y):
		if direction.x < 0:
			return Vector2.LEFT

		return Vector2.RIGHT

	if direction.y < 0:
		return Vector2.UP

	return Vector2.DOWN
	
func take_damage(
	amount: int,
	_damage_source: Vector2
) -> void:
	if state == EnemyState.DEAD:
		return

	current_health = max(current_health - amount, 0)
	print(name, ": ", current_health, "/", max_health)

	play_hit_effect()

	if current_health <= 0:
		die()

func get_aligned_attack_direction(
	offset: Vector2
) -> Vector2:
	var horizontally_aligned := (
		absf(offset.y) <= alignment_tolerance
	)

	var vertically_aligned := (
		absf(offset.x) <= alignment_tolerance
	)

	# Player está à esquerda ou direita.
	if (
		horizontally_aligned
		and absf(offset.x) <= attack_range
		and absf(offset.x) > 1.0
	):
		if offset.x < 0:
			return Vector2.LEFT

		return Vector2.RIGHT

	# Player está acima ou abaixo.
	if (
		vertically_aligned
		and absf(offset.y) <= attack_range
		and absf(offset.y) > 1.0
	):
		if offset.y < 0:
			return Vector2.UP

		return Vector2.DOWN

	return Vector2.ZERO
	
func get_lane_move_direction(
	offset: Vector2
) -> Vector2:
	# Decide qual linha de ataque é mais fácil alcançar.
	var use_horizontal_lane := (
		absf(offset.y) <= absf(offset.x)
	)

	if use_horizontal_lane:
		# Primeiro alinha o Y.
		if absf(offset.y) > alignment_tolerance:
			if offset.y < 0:
				return Vector2.UP

			return Vector2.DOWN

		# Depois aproxima pela esquerda/direita.
		if offset.x < 0:
			return Vector2.LEFT

		return Vector2.RIGHT

	# Para atacar verticalmente, primeiro alinha o X.
	if absf(offset.x) > alignment_tolerance:
		if offset.x < 0:
			return Vector2.LEFT

		return Vector2.RIGHT

	# Depois aproxima por cima/baixo.
	if offset.y < 0:
		return Vector2.UP

	return Vector2.DOWN
