## DialogManager.gd
## Autoload singleton — agregar en Project > Project Settings > Autoload
## Nombre: DialogManager
##
## Uso desde cualquier sala:
##   DialogManager.queue_dialog([
##       {"speaker": "GLADOS", "text": "Ah. Estás despierto."},
##       {"speaker": "GLADOS", "text": "Tomó más de lo esperado."},
##   ])
##   DialogManager.queue_dialog([...], callback)   # callback se llama al terminar
##
## El jugador se detiene automáticamente durante el diálogo.
## Presionar ui_accept (Espacio/Enter) avanza o cierra.

extends CanvasLayer

signal dialog_started
signal dialog_finished

# --- Configuración visual ---
const TYPING_SPEED      := 0.035   # segundos por caracter
const FAST_TYPING_SPEED := 0.008   # velocidad al mantener presionado
const PAUSE_AFTER_LINE  := 0.3     # pausa antes de mostrar el indicador "continuar"

# Colores por hablante
const SPEAKER_COLORS := {
	"GLADOS": Color(0.4, 0.85, 0.5),       # verde Aperture
	"RUST":   Color(0.85, 0.45, 0.1),       # naranja oxidado
	"AXIOM":  Color(0.85, 0.85, 0.95),      # blanco frío
	"ECHO":   Color(0.75, 0.5, 0.9),        # violeta
	"VOID":   Color(0.35, 0.35, 0.5),       # gris oscuro
	"NOTA":   Color(0.75, 0.65, 0.4),       # papel amarillento
}

# --- Estado interno ---
var _queue      : Array   = []
var _callback   = null
var _typing     : bool    = false
var _full_text  : String  = ""
var _char_index : int     = 0
var _can_advance: bool    = false
var _active     : bool    = false

# --- Nodos de la UI (se crean en _ready) ---
var _panel      : PanelContainer
var _speaker_label : Label
var _text_label : RichTextLabel
var _continue_indicator : Label
var _typing_timer : Timer

func _ready() -> void:
	layer = 10       # siempre encima de todo
	_build_ui()
	_panel.hide()
	set_process_unhandled_input(true)

# ============================================================
# API pública
# ============================================================

## Muestra una secuencia de líneas de diálogo.
## lines: Array de dicts {"speaker": "GLADOS", "text": "..."}
## on_finish: Callable opcional que se ejecuta al cerrar el diálogo
func queue_dialog(lines: Array, on_finish = null) -> void:
	if lines.is_empty():
		return
	_queue    = lines.duplicate()
	_callback = on_finish
	_active   = true
	_panel.show()
	emit_signal("dialog_started")
	_next_line()

## Cierra el diálogo inmediatamente (para cutscenes que se interrumpen)
func close() -> void:
	_typing_timer.stop()
	_queue.clear()
	_active = false
	_panel.hide()
	emit_signal("dialog_finished")

func is_active() -> bool:
	return _active

# ============================================================
# Lógica interna
# ============================================================

func _next_line() -> void:
	if _queue.is_empty():
		_finish()
		return

	var line : Dictionary = _queue.pop_front()
	var speaker : String  = line.get("speaker", "")
	var text    : String  = line.get("text", "")

	# Nombre del hablante
	_speaker_label.text = speaker
	var col : Color = SPEAKER_COLORS.get(speaker, Color.WHITE)
	_speaker_label.add_theme_color_override("font_color", col)

	# Efecto máquina de escribir
	_full_text  = text
	_char_index = 0
	_can_advance = false
	_continue_indicator.hide()
	_text_label.text = ""
	_typing = true
	_typing_timer.wait_time = TYPING_SPEED
	_typing_timer.start()

func _on_typing_tick() -> void:
	if _char_index >= _full_text.length():
		_typing = false
		_typing_timer.stop()
		await get_tree().create_timer(PAUSE_AFTER_LINE).timeout
		_continue_indicator.show()
		_can_advance = true
		return

	_char_index += 1
	_text_label.text = _full_text.left(_char_index)

	# Pausa natural en puntos/comas
	var ch := _full_text[_char_index - 1]
	if ch in [".", "!", "?"]:
		_typing_timer.wait_time = TYPING_SPEED * 6.0
	elif ch == ",":
		_typing_timer.wait_time = TYPING_SPEED * 3.0
	else:
		_typing_timer.wait_time = TYPING_SPEED

func _finish() -> void:
	_active = false
	_panel.hide()
	emit_signal("dialog_finished")
	if _callback is Callable:
		_callback.call()
	_callback = null

# ============================================================
# Input
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	# Solo procesar teclas físicas (evita crashes con otros tipos de InputEvent)
	if not event is InputEventKey:
		return

	var key := event as InputEventKey
	var is_accept := key.keycode == KEY_SPACE or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER

	if is_accept and key.pressed and not key.echo:
		if _typing:
			# Skip: muestra el texto completo al instante
			_typing_timer.stop()
			_typing = false
			_text_label.text = _full_text
			_can_advance = true
			_continue_indicator.show()
		elif _can_advance:
			_can_advance = false
			_next_line()
		get_viewport().set_input_as_handled()

	# Mantener pulsado = escritura rápida
	if is_accept and key.pressed and _typing:
		_typing_timer.wait_time = FAST_TYPING_SPEED

# ============================================================
# Construcción de la UI por código
# ============================================================

func _build_ui() -> void:
	# Panel de fondo
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left   =  40
	_panel.offset_right  = -40
	_panel.offset_top    = -160
	_panel.offset_bottom = -20

	# Estilo del panel
	var style := StyleBoxFlat.new()
	style.bg_color          = Color(0.04, 0.06, 0.1, 0.92)
	style.border_color      = Color(0.25, 0.7, 0.35, 0.8)
	style.set_border_width_all(1)
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	# Layout interno
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left",   20)
	margins.add_theme_constant_override("margin_right",  20)
	margins.add_theme_constant_override("margin_top",    14)
	margins.add_theme_constant_override("margin_bottom", 14)
	margins.add_child(vbox)
	_panel.add_child(margins)

	# Nombre del hablante
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 13)
	_speaker_label.add_theme_color_override("font_color", Color(0.4, 0.85, 0.5))
	vbox.add_child(_speaker_label)

	# Separador decorativo
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.25, 0.7, 0.35, 0.4))
	vbox.add_child(sep)

	# Texto principal
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled    = false
	_text_label.autowrap_mode     = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(0, 72)
	_text_label.add_theme_font_size_override("normal_font_size", 16)
	_text_label.add_theme_color_override("default_color", Color(0.88, 0.88, 0.88))
	vbox.add_child(_text_label)

	# Indicador "continuar"
	_continue_indicator = Label.new()
	_continue_indicator.text = "▼  [Espacio]"
	_continue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_indicator.add_theme_font_size_override("font_size", 11)
	_continue_indicator.add_theme_color_override("font_color", Color(0.4, 0.85, 0.5, 0.7))
	vbox.add_child(_continue_indicator)

	# Timer para el efecto typing
	_typing_timer = Timer.new()
	_typing_timer.one_shot = false
	_typing_timer.connect("timeout", _on_typing_tick)
	add_child(_typing_timer)
