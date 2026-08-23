extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Level _ready rodou")
	print("player = ", player)
	print("hud = ", hud)
	player.health_changed.connect(hud.update_health)
	hud.update_health(player.current_health, player.max_health)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
