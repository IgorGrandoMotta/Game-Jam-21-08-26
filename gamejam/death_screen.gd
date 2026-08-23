extends CanvasLayer


@export_category("Fade para preto")
@export var fade_duration: float = 1.0

@export_category("Reinício")
@export var allow_restart: bool = true
@export var restart_delay: float = 0.5


@onready var color_rect: ColorRect = $ColorRect
@onready var menu: Control = $Menu
@onready var respawn_button: Button = $Menu/VBoxContainer/RespawnButton
@onready var quit_button: Button = $Menu/VBoxContainer/QuitButton


var can_restart := false


func _ready() -> void:
	# Fica sempre ativa mesmo com o jogo pausado, senão o fade
	# não tocaria depois de dar pause em die().
	process_mode = Node.PROCESS_MODE_ALWAYS

	visible = false
	color_rect.color = Color(0, 0, 0, 0)

	menu.visible = false
	respawn_button.disabled = true

	respawn_button.pressed.connect(_on_respawn_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


# Chamada pelo Player (self.died.connect(DeathScreen.show_death_screen))
# em vez de a DeathScreen procurar o Player sozinha.
func show_death_screen() -> void:
	visible = true

	var tween := create_tween()

	tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
	tween.tween_callback(_on_death_screen_finished)


func _on_death_screen_finished() -> void:
	menu.visible = true
	quit_button.grab_focus()

	if allow_restart:
		await get_tree().create_timer(restart_delay).timeout
		can_restart = true
		respawn_button.disabled = false


func _on_respawn_pressed() -> void:
	if not can_restart:
		return

	can_restart = false
	visible = false
	color_rect.color = Color(0, 0, 0, 0)
	menu.visible = false
	respawn_button.disabled = true

	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
