## SalaBase.gd
## Clase padre que heredan TODAS las salas (1–13)
##
## Uso en cada sala:
##   extends SalaBase
##
##   func _sala_ready() -> void:
##       # Tu código de la sala aquí (en lugar de _ready)
##
##   func get_dialogs_on_enter() -> Array:
##       return [
##           {"speaker": "GLADOS", "text": "Esta sección fue construida en 1974."},
##       ]

class_name SalaBase
extends Node2D  # o lo que corresponda

# Override en cada sala para dar diálogos de entrada
func get_dialogs_on_enter() -> Array:
	return []

# Override en cada sala para código de inicialización
func _sala_ready() -> void:
	pass

func _ready() -> void:
	SceneLoader.fade_in_only()
	_sala_ready()

	var dialogs := get_dialogs_on_enter()
	if not dialogs.is_empty():
		# Pequeño delay para que el fade in termine primero
		await get_tree().create_timer(0.5).timeout
		DialogManager.queue_dialog(dialogs)
