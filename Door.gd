## Door.gd
## Componente reutilizable — puerta que lleva a la siguiente sala
##
## Nodos requeridos en la escena:
##   Door (Area2D)
##   ├── CollisionShape2D   (rectángulo, el ancho de la puerta)
##   ├── ColorRect          (visual de la puerta)
##   └── Label              (símbolo ">>>")
##
## Propiedades exportadas (configurables desde el editor):
##   next_sala : int — número de sala destino
##   locked    : bool — si está bloqueada (espera jefe)

extends Area2D
class_name Door

@export var next_sala : int  = 0
@export var locked    : bool = false

@onready var visual : ColorRect = $ColorRect
@onready var label  : Label     = $Label

# Animación de parpadeo
var _time : float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_visual()

func _process(delta: float) -> void:
	if locked:
		return
	_time += delta
	var pulse := 0.6 + sin(_time * 3.0) * 0.3
	visual.color = Color(0.3 * pulse, 0.7 * pulse, 0.35 * pulse)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if locked:
		DialogManager.queue_dialog([
			{"speaker": "GLADOS",
			 "text": "Esta puerta está bloqueada. Estadísticamente, intentar abrirla a la fuerza reduce tu esperanza de vida un 47%."}
		])
		return
	if next_sala <= 0:
		push_error("Door: next_sala no configurado")
		return
	SceneLoader.go_to_sala(next_sala)

func unlock() -> void:
	locked = false
	_update_visual()

func _update_visual() -> void:
	if locked:
		visual.color = Color(0.2, 0.08, 0.05)
		label.text   = "[ ]"
		label.add_theme_color_override("font_color", Color(0.4, 0.2, 0.1))
	else:
		visual.color = Color(0.3, 0.7, 0.35)
		label.text   = ">>>"
		label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.55))


## ============================================================
## CÓMO CREAR LA ESCENA Door.tscn EN GODOT:
## ============================================================
##
## 1. Escena nueva → nodo raíz: Area2D → renombrar "Door"
## 2. Agregar hijos:
##    - CollisionShape2D (RectangleShape2D: 40 × 80 px)
##    - ColorRect (size: 40 × 80, position: -20, -80)
##    - Label (text: ">>>", position: -8, -50)
## 3. Attach script: Door.gd
## 4. Guardar como res://scenes/Door.tscn
##
## Uso en Sala1.gd:
##   var door = preload("res://scenes/Door.tscn").instantiate()
##   door.position = Vector2(1080, 520)
##   door.next_sala = 2
##   add_child(door)
