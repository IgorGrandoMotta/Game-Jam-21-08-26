extends CanvasLayer

@export var next_scene_path: String = "res://level_01.tscn"

@onready var sprites: Array[AnimatedSprite2D] = [
	$TutorialMundo,
	$TutorialMundo,
	$TutorialMundo,
	$TutorialMundo,
	$TutorialMundo,
	$TutorialMundo,
	$TutorialMundo,
	$TutorialMundo,
	$TutorialMundo,
	$TutorialInimigo,
	$TutorialInimigo,
	$TutorialInimigo,
	$TutorialInimigo,
	$TutorialPlayer,
	$TutorialPlayer,
	$TutorialPlayer,
	$TutorialAction,
	$TutorialAction
]

var current_index := 0

func _ready() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size

	for i in range(sprites.size()):
		var sprite := sprites[i]
		sprite.position = screen_size / 2.0

		var tex: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
		var tex_size: Vector2 = tex.get_size()
		var scale_factor: float = max(screen_size.x / tex_size.x, screen_size.y / tex_size.y)
		sprite.scale = Vector2(scale_factor, scale_factor)

		sprite.visible = (i == 0)

	_play_current()

func _play_current() -> void:
	var sprite := sprites[current_index]
	sprite.animation_finished.connect(_on_current_finished, CONNECT_ONE_SHOT)
	sprite.play()

func _on_current_finished() -> void:
	sprites[current_index].visible = false
	current_index += 1

	if current_index >= sprites.size():
		SceneTransition.change_scene(next_scene_path)
	else:
		sprites[current_index].visible = true
		_play_current()
