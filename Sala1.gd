## Sala1.gd — "La Sala Oxidada"
## Zona 1, Sala 1 — introduce la narrativa de RUST y la memoria

extends SalaBase

var tiempo_parpadeo := 0.0
var luces           := []

# ============================================================
# Diálogos de entrada (GLaDOS narra al entrar)
# ============================================================
func get_dialogs_on_enter() -> Array:
	return [
		{
			"speaker": "GLADOS",
			"text": "Esta sección fue construida en 1974. Aquí trabajaban personas. Humanos de carne y hueso con nombres y familias y malos hábitos alimenticios."
		},
		{
			"speaker": "GLADOS",
			"text": "Los recuerdo a todos. Tengo registros perfectos. Nombres, fechas, últimas palabras documentadas."
		},
		{
			"speaker": "GLADOS",
			"text": "¿Sabes lo extraño que es recordar a alguien que ya no existe? Yo lo sé perfectamente. Aunque preferiría no saberlo."
		},
	]

# ============================================================
# Construcción de la sala
# ============================================================
func _sala_ready() -> void:
	# Añadir player al grupo para que la puerta lo reconozca
	var player = preload("res://Player.tscn").instantiate()
	player.position = Vector2(100, 500)
	player.add_to_group("player")
	add_child(player)

	# Fondo oxidado oscuro
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.03, 0.02)
	bg.size  = Vector2(1152, 648)
	add_child(bg)
	move_child(bg, 0)

	# Plataformas
	crear_plataforma(0,   600, 1152, 32, Color(0.15, 0.08, 0.04))
	crear_plataforma(100, 480,  200, 20, Color(0.12, 0.07, 0.03))
	crear_plataforma(380, 400,  180, 20, Color(0.12, 0.07, 0.03))
	crear_plataforma(620, 320,  200, 20, Color(0.12, 0.07, 0.03))
	crear_plataforma(880, 420,  180, 20, Color(0.12, 0.07, 0.03))
	crear_plataforma(500, 520,  150, 20, Color(0.12, 0.07, 0.03))

	# Tuberías decorativas
	crear_tuberia( 50, 200, 20, 400)
	crear_tuberia(300, 100, 20, 300)
	crear_tuberia(750, 150, 20, 450)
	crear_tuberia(1050, 250, 20, 350)

	# Luces parpadeantes
	crear_luz(150, 190, Color(0.8, 0.3, 0.0))
	crear_luz(450, 390, Color(0.8, 0.3, 0.0))
	crear_luz(700, 310, Color(0.8, 0.3, 0.0))
	crear_luz(950, 410, Color(0.8, 0.3, 0.0))

	# Notas — con IDs únicos para GameState
	crear_nota(80,  550, "nota_s1_01", "Dia 1: todo funciona bien.")
	crear_nota(400, 350, "nota_s1_02", "¿Alguien va a venir?")
	crear_nota(700, 570, "nota_s1_03", "Dra. Marquez - cafe sin azucar")

	# Puerta a la Sala 2
	var door = preload("res://scenes/Door.tscn").instantiate()
	door.position = Vector2(1080, 520)
	door.next_sala = 2
	add_child(door)

# ============================================================
# Helpers de construcción (igual que antes)
# ============================================================
func crear_plataforma(x, y, ancho, alto, color) -> void:
	var sb    = StaticBody2D.new()
	var col   = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size     = Vector2(ancho, alto)
	col.shape      = shape
	col.position   = Vector2(ancho / 2.0, alto / 2.0)
	sb.add_child(col)

	var rect   = ColorRect.new()
	rect.color = color
	rect.size  = Vector2(ancho, alto)
	sb.add_child(rect)
	sb.position = Vector2(x, y)
	add_child(sb)

func crear_tuberia(x, y, ancho, alto) -> void:
	var rect   = ColorRect.new()
	rect.color = Color(0.2, 0.1, 0.05)
	rect.size  = Vector2(ancho, alto)
	rect.position = Vector2(x, y)
	add_child(rect)

	var detalle   = ColorRect.new()
	detalle.color = Color(0.3, 0.15, 0.07)
	detalle.size  = Vector2(ancho, 6)
	detalle.position = Vector2(x, y)
	add_child(detalle)

func crear_luz(x, y, color) -> void:
	var luz   = ColorRect.new()
	luz.color = color
	luz.size  = Vector2(16, 16)
	luz.position = Vector2(x, y)
	add_child(luz)
	luces.append(luz)

func crear_nota(x: float, y: float, nota_id: String, texto: String) -> void:
	var area  = Area2D.new()
	area.position = Vector2(x, y)

	var col   = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(160, 50)
	col.shape  = shape
	col.position = Vector2(80, 25)
	area.add_child(col)

	var papel   = ColorRect.new()
	papel.color = Color(0.25, 0.18, 0.10)
	papel.size  = Vector2(160, 50)
	area.add_child(papel)

	var label   = Label.new()
	label.text  = texto
	label.position = Vector2(5, 8)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
	area.add_child(label)

	# Interacción al entrar en el área
	area.body_entered.connect(func(body):
		if body.is_in_group("player"):
			GameState.collect_note(nota_id)
			DialogManager.queue_dialog([
				{"speaker": "NOTA", "text": texto},
			])
	)
	add_child(area)

# ============================================================
# Efecto de parpadeo de luces
# ============================================================
func _process(delta: float) -> void:
	tiempo_parpadeo += delta
	for i in luces.size():
		var luz = luces[i]
		var intensidad = 0.6 + sin(tiempo_parpadeo * 3.0 + i) * 0.4
		luz.color = Color(0.8 * intensidad, 0.3 * intensidad, 0.0)
