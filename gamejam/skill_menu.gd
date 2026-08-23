extends CanvasLayer

## Nome da action no Input Map mapeada pra tecla Tab.
## Crie em Project > Project Settings > Input Map, com o nome abaixo.
@export var open_action: String = "skill_menu"

enum Direction { UP, RIGHT, DOWN, LEFT }


@onready var menu: Control = $Menu
@onready var compass_sprite: AnimatedSprite2D = $Menu/CompassSprite

# Nome da animação (dentro do SpriteFrames do relógio) pra cada
# direção. Cadastre as 4 animações com esses mesmos nomes — cada
# uma já mostra o relógio inteiro com o ícone certo destacado.
const DIRECTION_ANIMATIONS := {
	Direction.UP: "up",
	Direction.RIGHT: "right",
	Direction.DOWN: "down",
	Direction.LEFT: "left",
}


## Emitido toda vez que a seleção muda. Conecte aqui quando o
## sistema de habilidades existir de verdade.
signal ability_selected(direction: Direction)


var current_direction: Direction = Direction.UP
var _is_open := false


func _ready() -> void:
	menu.hide()
	compass_sprite.play(DIRECTION_ANIMATIONS[current_direction])

	# Um Node2D dentro de um Control não segue anchors, então
	# centralizamos manualmente aqui — funciona em qualquer resolução.
	compass_sprite.position = get_viewport().get_visible_rect().size / 2.0


func _process(_delta: float) -> void:
	var should_be_open := Input.is_action_pressed(open_action)

	if should_be_open and not _is_open:
		_open_menu()
	elif not should_be_open and _is_open:
		_close_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return

	if event.is_action_pressed("ui_up"):
		_select_direction(Direction.UP)
	elif event.is_action_pressed("ui_right"):
		_select_direction(Direction.RIGHT)
	elif event.is_action_pressed("ui_down"):
		_select_direction(Direction.DOWN)
	elif event.is_action_pressed("ui_left"):
		_select_direction(Direction.LEFT)


func _open_menu() -> void:
	_is_open = true
	menu.show()


func _close_menu() -> void:
	_is_open = false
	menu.hide()


func _select_direction(direction: Direction) -> void:
	if direction == current_direction:
		return

	current_direction = direction
	compass_sprite.play(DIRECTION_ANIMATIONS[direction])
	ability_selected.emit(current_direction)
