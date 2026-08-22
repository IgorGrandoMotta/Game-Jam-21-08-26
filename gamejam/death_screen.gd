extends CanvasLayer


@export_category("Fade para preto")
@export var fade_duration: float = 1.0

@export_category("Sprite de morte")
@export var sprite_delay: float = 0.3
@export var sprite_fade_duration: float = 0.5

@export_category("Reinício")
@export var allow_restart: bool = true
@export var restart_delay: float = 0.5


@onready var color_rect: ColorRect = $ColorRect
@onready var death_sprite: TextureRect = $DeathSprite


var can_restart := false


func _ready() -> void:
	# Fica sempre ativa mesmo com o jogo pausado, senão o fade
	# não tocaria depois de dar pause em die().
	process_mode = Node.PROCESS_MODE_ALWAYS

	visible = false
	color_rect.color = Color(0, 0, 0, 0)
	death_sprite.modulate = Color(1, 1, 1, 0)

	var player := get_tree().get_first_node_in_group("player")

	if player:
		player.died.connect(_on_player_died)


func _on_player_died() -> void:
	visible = true

	var tween := create_tween()

	tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
	tween.tween_interval(sprite_delay)
	tween.tween_property(death_sprite, "modulate:a", 1.0, sprite_fade_duration)
	tween.tween_callback(_on_death_screen_finished)


func _on_death_screen_finished() -> void:
	if allow_restart:
		await get_tree().create_timer(restart_delay).timeout
		can_restart = true


func _unhandled_input(event: InputEvent) -> void:
	if not allow_restart or not can_restart:
		return

	if event is InputEventKey and event.pressed:
		get_tree().paused = false
		get_tree().reload_current_scene()
