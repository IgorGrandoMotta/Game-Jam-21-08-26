extends CharacterBody2D
class_name Boss

# ============================================
# CONFIGURAÇÕES GERAIS
# ============================================
@export var max_health: int = 10
@export var move_speed: float = 60.0

# Tempo entre ataques (o boss escolhe um dos dois aleatoriamente)
@export var time_between_attacks: float = 2.5

# --- Ataque de projétil ---
@export var projectile_scene: PackedScene   # arraste o boss_projectile.tscn aqui no editor
@export var projectiles_per_burst: int = 5
@export var time_between_shots: float = 0.25

# --- Ataque de garra ---
@export var claw_scene: PackedScene         # arraste o boss_claw.tscn aqui no editor
@export var claw_wall_points: Array[Marker2D] = []  # pontos nas paredes onde a garra pode surgir
@export var claws_per_attack: int = 3

var current_health: int
var player: Node2D = null

enum State { IDLE, MOVE, TELEGRAPH, ATTACK_PROJECTILE, ATTACK_CLAW, STAGGER, DEAD }
var state: State = State.IDLE

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox        # área que recebe dano do projétil rebatido
@onready var attack_timer: Timer = $AttackTimer


func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")

	attack_timer.wait_time = time_between_attacks
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()

	# Conecta a hurtbox: só recebe dano de projétil que foi rebatido (grupo "deflected")
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE, State.MOVE:
			_process_movement(delta)
		_:
			pass


func _process_movement(_delta: float) -> void:
	if player == null:
		return
	# Movimento simples de perseguição leve — ajuste como preferir
	var dir := (player.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()


# ============================================
# ESCOLHA DE ATAQUE
# ============================================
func _on_attack_timer_timeout() -> void:
	if state == State.DEAD or state == State.STAGGER:
		return

	if randi() % 2 == 0:
		_start_projectile_attack()
	else:
		_start_claw_attack()


func _start_projectile_attack() -> void:
	state = State.ATTACK_PROJECTILE
	velocity = Vector2.ZERO
	if sprite:
		sprite.play("attack_projectile")

	for i in range(projectiles_per_burst):
		_spawn_projectile()
		await get_tree().create_timer(time_between_shots).timeout

	state = State.IDLE
	attack_timer.start()


func _spawn_projectile() -> void:
	if projectile_scene == null or player == null:
		return
	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position

	# Sorteia se este projétil é o "certo" (o que precisa ser rebatido pra dar dano)
	var is_correct := randf() < 0.35  # ~35% de chance por projétil
	proj.setup(player.global_position, is_correct)


func _start_claw_attack() -> void:
	if claw_wall_points.is_empty() or claw_scene == null:
		state = State.IDLE
		attack_timer.start()
		return

	state = State.ATTACK_CLAW
	velocity = Vector2.ZERO
	if sprite:
		sprite.play("attack_claw")

	var points := claw_wall_points.duplicate()
	points.shuffle()
	var count = min(claws_per_attack, points.size())

	for i in range(count):
		var claw = claw_scene.instantiate()
		get_tree().current_scene.add_child(claw)
		claw.global_position = points[i].global_position
		await get_tree().create_timer(0.4).timeout  # espaça o surgimento das garras

	await get_tree().create_timer(1.0).timeout
	state = State.IDLE
	attack_timer.start()


# ============================================
# DANO NO BOSS (só projétil rebatido acerta aqui)
# ============================================
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not area.is_in_group("deflected_projectile"):
		return  # projétil normal não machuca o boss

	take_damage(1)
	area.queue_free()


func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return

	current_health -= amount
	if sprite:
		sprite.modulate = Color(1, 0.4, 0.4)
		get_tree().create_timer(0.1).timeout.connect(func(): sprite.modulate = Color.WHITE)

	if current_health <= 0:
		_die()
	else:
		_stagger()


func _stagger() -> void:
	state = State.STAGGER
	attack_timer.stop()
	if sprite:
		sprite.play("hit")
	await get_tree().create_timer(0.4).timeout
	if state != State.DEAD:
		state = State.IDLE
		attack_timer.start()


func _die() -> void:
	state = State.DEAD
	attack_timer.stop()
	if sprite:
		sprite.play("death")
	# emita um sinal aqui se quiser tocar cutscene de vitória, dropar item, etc.
	set_physics_process(false)
