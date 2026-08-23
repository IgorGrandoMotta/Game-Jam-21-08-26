extends Node

## Guarda o estado do Player que precisa sobreviver entre trocas de cena.
## Registrado como Autoload (singleton), acessível globalmente como "PlayerData".

var current_health: int = -1  # -1 indica "ainda não inicializado"
var max_health: int = 50


## Chame isso no _ready() do Player pra restaurar (ou inicializar) a vida.
func load_into(player: Node) -> void:
	print("PlayerData.load_into ANTES -> PlayerData.current_health: ", current_health, " | player.max_health: ", player.max_health)

	if current_health < 0:
		# Primeira vez rodando o jogo: começa com vida cheia
		max_health = player.max_health
		current_health = max_health
	else:
		# Já existia estado salvo (troca de cena): restaura
		player.max_health = max_health

	player.current_health = current_health

	print("PlayerData.load_into DEPOIS -> player.current_health: ", player.current_health, "/", player.max_health)


## Chame isso sempre que a vida do Player mudar (dano, cura), pra manter sincronizado.
func save_from(player: Node) -> void:
	current_health = player.current_health
	max_health = player.max_health
