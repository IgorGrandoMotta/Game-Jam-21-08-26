extends CanvasLayer

# Registre esta cena (CanvasLayer + ColorRect + Label) como Autoload
# em Project > Project Settings > Autoload, com o nome "SceneTransition".

signal transition_finished


@export var fade_duration: float = 0.5

## Tempo mínimo (em segundos) que a tela de loading fica visível,
## mesmo que a cena carregue mais rápido que isso. Evita o "piscar".
@export var min_loading_time: float = 0.6


@onready var color_rect: ColorRect = $ColorRect
@onready var loading_label: Label = $LoadingLabel


var _target_scene_path: String
var _loading := false
var _load_start_time_ms := 0


func _ready() -> void:
	# Precisa continuar rodando mesmo se o jogo estiver pausado
	# (ex: transição chamada a partir de uma tela de pause/morte).
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100

	color_rect.color = Color(0, 0, 0, 0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_label.hide()
	visible = false

	set_process(false)


func change_scene(scene_path: String) -> void:
	if _loading:
		return

	_loading = true
	_target_scene_path = scene_path
	visible = true

	var tween := create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
	tween.tween_callback(_start_loading)


func _start_loading() -> void:
	loading_label.show()
	_load_start_time_ms = Time.get_ticks_msec()
	ResourceLoader.load_threaded_request(_target_scene_path)
	set_process(true)


func _process(_delta: float) -> void:
	var status := ResourceLoader.load_threaded_get_status(_target_scene_path)

	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			_wait_minimum_time_then_finish()

		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Falha ao carregar cena: %s" % _target_scene_path)
			set_process(false)
			_loading = false

		# THREAD_LOAD_IN_PROGRESS: continua esperando.
		# Se quiser uma barra de progresso, dá pra passar um Array
		# vazio pro segundo parâmetro de load_threaded_get_status()
		# e ler o percentual em progress[0].


func _wait_minimum_time_then_finish() -> void:
	var elapsed_sec := (Time.get_ticks_msec() - _load_start_time_ms) / 1000.0
	var remaining_sec: float = max(0.0, min_loading_time - elapsed_sec)

	if remaining_sec > 0.0:
		# process_always = true por padrão, então isso funciona mesmo
		# se a árvore estiver pausada.
		await get_tree().create_timer(remaining_sec).timeout

	_finish_loading()


func _finish_loading() -> void:
	var packed_scene: PackedScene = ResourceLoader.load_threaded_get(_target_scene_path)

	get_tree().paused = false
	get_tree().change_scene_to_packed(packed_scene)

	loading_label.hide()

	var tween := create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, fade_duration)
	tween.tween_callback(_on_fade_in_finished)


func _on_fade_in_finished() -> void:
	visible = false
	_loading = false
	transition_finished.emit()
