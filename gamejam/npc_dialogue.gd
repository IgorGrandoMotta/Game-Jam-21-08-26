extends CharacterBody2D

## Falas que esse NPC diz ao ser interagido, em ordem. Edite no Inspector.
@export var dialogue_lines: Array[String] = ["..."]

@onready var interaction_area: Area2D = $InteractionArea
@onready var interact_prompt: Node2D = $InteractPrompt

var player_in_range: bool = false
var player_ref: Node = null


func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	print("Body entrou na InteractionArea: ", body.name)
	if body.is_in_group("player"):
		print("É o player! player_in_range = true")
		player_in_range = true
		player_ref = body
		interact_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_in_range = false
		player_ref = null
		interact_prompt.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return

	if DialogueBox.is_open():
		return

	if event.is_action_pressed("interact"):
		print("Abrindo diálogo!")
		interact_prompt.visible = false
		DialogueBox.show_dialogue_lines(dialogue_lines)
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	# Volta a mostrar o prompt quando o diálogo fecha, se o player ainda estiver na área
	if player_in_range and not DialogueBox.is_open():
		interact_prompt.visible = true
