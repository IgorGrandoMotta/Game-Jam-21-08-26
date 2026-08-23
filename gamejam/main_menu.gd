extends CanvasLayer

func _on_jogar_button_pressed():
	SceneTransition.change_scene("res://Game.tscn")

func _on_opcoes_pressed():
	SceneTransition.change_scene("res://Options.tscn")

func _on_sair_button_pressed():
	var tween = create_tween()
	tween.tween_callback(get_tree().quit)
