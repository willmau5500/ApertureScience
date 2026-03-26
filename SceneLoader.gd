## SceneLoader.gd
## Autoload singleton — agregar en Project > Project Settings > Autoload
## Nombre: SceneLoader
##
## Uso:
##   SceneLoader.go_to_sala(2)               # ir a la sala 2
##   SceneLoader.go_to_scene("res://X.tscn") # ir a escena directa

extends CanvasLayer

const FADE_DURATION := 0.4

var _overlay : ColorRect
var _tween   : Tween

func _ready() -> void:
	layer = 100   # encima de todo, incluyendo el DialogManager
	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate.a  = 0.0
	add_child(_overlay)

func go_to_sala(sala: int) -> void:
	var path := GameState.get_scene_for_sala(sala)
	if path.is_empty():
		push_error("SceneLoader: no existe la sala %d" % sala)
		return
	GameState.set_sala(sala)
	go_to_scene(path)

func go_to_scene(path: String) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	# Fade out
	_tween.tween_property(_overlay, "modulate:a", 1.0, FADE_DURATION)
	_tween.tween_callback(func():
		get_tree().change_scene_to_file(path)
	)
	# Fade in (se ejecuta en la nueva escena porque este nodo es autoload)
	_tween.tween_property(_overlay, "modulate:a", 0.0, FADE_DURATION)

func fade_in_only() -> void:
	"""Llamar desde _ready() de cada sala si quieres fade in al entrar."""
	if _tween:
		_tween.kill()
	_overlay.modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_property(_overlay, "modulate:a", 0.0, FADE_DURATION)
