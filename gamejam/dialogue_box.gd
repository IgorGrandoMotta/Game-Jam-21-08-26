extends CanvasLayer

## Quantos caracteres por segundo aparecem durante o efeito de digitação
@export var chars_per_second: float = 30.0

@onready var dialogue_label: RichTextLabel = $Panel/DialogueLabel

signal dialogue_closed

var lines: Array[String] = []
var line_index: int = 0

var full_text: String = ""
var visible_chars: int = 0
var char_progress: float = 0.0
var is_typing: bool = false


func _ready() -> void:
	visible = false
	dialogue_label.bbcode_enabled = true
	set_process(false)


func _process(delta: float) -> void:
	if not is_typing:
		return

	char_progress += delta * chars_per_second

	while char_progress >= 1.0 and visible_chars < full_text.length():
		visible_chars += 1
		char_progress -= 1.0

	dialogue_label.visible_characters = visible_chars

	if visible_chars >= full_text.length():
		_finish_typing()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("interact"):
		advance()
		get_viewport().set_input_as_handled()


## Abre a caixa com uma sequência de falas. Ao apertar "E" com o texto
## já completo, avança pra próxima fala; na última, fecha a caixa.
func show_dialogue_lines(new_lines: Array[String]) -> void:
	if new_lines.is_empty():
		return
	lines = new_lines
	line_index = 0
	_show_current_line()


## Mantido por compatibilidade: abre a caixa com uma única fala.
func show_dialogue(text: String) -> void:
	show_dialogue_lines([text])


func _show_current_line() -> void:
	full_text = lines[line_index]
	dialogue_label.text = full_text
	visible_chars = 0
	char_progress = 0.0
	is_typing = true
	visible = true
	set_process(true)
	dialogue_label.visible_characters = 0


## Chamada quando o jogador aperta "E" com a caixa já aberta:
## se ainda está digitando, pula pro texto completo.
## Se já estava completo e tem próxima fala, mostra ela.
## Se era a última fala, fecha a caixa.
func advance() -> void:
	if is_typing:
		_skip_typing()
	elif line_index < lines.size() - 1:
		line_index += 1
		_show_current_line()
	else:
		close_dialogue()


func close_dialogue() -> void:
	visible = false
	is_typing = false
	lines = []
	line_index = 0
	set_process(false)
	dialogue_closed.emit()


func is_open() -> bool:
	return visible


func _skip_typing() -> void:
	visible_chars = full_text.length()
	dialogue_label.visible_characters = visible_chars
	_finish_typing()


func _finish_typing() -> void:
	is_typing = false
	set_process(false)
