extends CanvasLayer

# Referências aos nodes filhos - ajuste os caminhos conforme sua árvore de nodes
@onready var health_bar: TextureProgressBar = $Control/HealthBar
@onready var health_label: Label = $Control/HealthLabel


func _ready() -> void:
	# Garante que o Label comece com um valor sensato antes do primeiro update
	health_label.text = "0   0"


# Chame isso uma vez quando o Player nascer/spawnar, pra configurar o valor máximo
func set_max_health(max_health: int) -> void:
	health_bar.max_value = max_health


# Chame isso toda vez que a vida mudar (dano, cura, etc.)
func update_health(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	print("health_bar.value = ", health_bar.value, " / max = ", health_bar.max_value)
	health_label.text = "%d     %d" % [current, max_health]
