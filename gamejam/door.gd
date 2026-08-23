extends Area2D

## Caminho do arquivo .tscn do próximo nível.
@export_file("*.tscn") var target_scene: String

@export_category("Sprites")
@export var closed_texture: Texture2D
@export var open_texture: Texture2D


@onready var sprite: Sprite2D = $Sprite2D
@onready var door_sound: AudioStreamPlayer = $DoorSound
@onready var entry_area: Area2D = $EntryArea

# Trava a porta assim que a transição começa, pra não disparar de
# novo caso o player saia/entre na EntryArea nesse meio tempo.
var _transitioning := false


func _ready() -> void:
	# Este Area2D (raiz) é a área de PROXIMIDADE: só troca o sprite.
	body_entered.connect(_on_proximity_entered)
	body_exited.connect(_on_proximity_exited)

	# EntryArea é menor, bem na soleira da porta: dispara a transição.
	entry_area.body_entered.connect(_on_entry_entered)
	
	sprite.texture = closed_texture


func _on_proximity_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	sprite.texture = open_texture
	door_sound.play(0.8)


func _on_proximity_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Não fecha se já estiver no meio da transição (a tela já vai
	# estar preta de qualquer forma nesse ponto).
	if not _transitioning:
		sprite.texture = closed_texture


func _on_entry_entered(body: Node2D) -> void:
	if _transitioning:
		return

	if not body.is_in_group("player"):
		return

	if target_scene.is_empty():
		push_warning("Door sem target_scene configurado: %s" % name)
		return

	_transitioning = true
	SceneTransition.change_scene(target_scene)
