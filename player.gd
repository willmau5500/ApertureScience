extends CharacterBody2D

# --- CONFIGURACIÓN DEL PERSONAJE ---
const SPEED          = 250.0
const JUMP_VELOCITY  = -500.0
const GRAVITY        = 1200.0

# Aceleración — cuánto tarda en llegar a velocidad máxima
const ACCEL_GROUND   = 2000.0   # en el suelo: respuesta rápida
const ACCEL_AIR      = 800.0    # en el aire: control reducido
const DECEL_GROUND   = 2200.0   # frenado en el suelo
const DECEL_AIR      = 400.0    # frenado en el aire (más suave)

# Game feel — tiempos de gracia
const COYOTE_TIME    = 0.12     # segundos que puedes saltar tras salir del borde
const JUMP_BUFFER    = 0.10     # segundos que se "guarda" el intento de salto

# --- ESTADO INTERNO ---
var coyote_timer  : float = 0.0
var jump_buffer_timer : float = 0.0
var was_on_floor  : bool = false

# Squash & stretch
var base_scale    := Vector2(1.0, 1.0)
var target_scale  := Vector2(1.0, 1.0)
const SCALE_SPEED := 12.0       # qué tan rápido vuelve al tamaño normal

# --- NODOS ---
@onready var polygon : Polygon2D        = $Polygon2D
@onready var shape   : CollisionShape2D = $CollisionShape2D

func _ready():
	# ---- Silueta humanoide (estilo Hollow Knight) ----
	polygon.polygon = PackedVector2Array([
		Vector2(-12, -40),  # cabeza izquierda
		Vector2( 12, -40),  # cabeza derecha
		Vector2( 18,  -8),  # hombro derecho
		Vector2( 13,  20),  # cadera derecha
		Vector2(  7,  40),  # pie derecho
		Vector2( -7,  40),  # pie izquierdo
		Vector2(-13,  20),  # cadera izquierda
		Vector2(-18,  -8),  # hombro izquierdo
	])
	polygon.color = Color(0.05, 0.08, 0.15)

	# ---- Cápsula de colisión ----
	var col      = CapsuleShape2D.new()
	col.radius   = 14
	col.height   = 80
	shape.shape  = col
	shape.position = Vector2.ZERO

	# ---- Cámara ----
	var cam         = Camera2D.new()
	cam.zoom        = Vector2(1.2, 1.2)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed   = 8.0
	add_child(cam)

func _physics_process(delta):
	# ---- Coyote time ----
	if was_on_floor and not is_on_floor():
		coyote_timer = COYOTE_TIME   # empieza la cuenta al salir del borde
	if is_on_floor():
		coyote_timer = COYOTE_TIME   # se resetea mientras estás en el suelo

	# ---- Jump buffer ----
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = JUMP_BUFFER

	# ---- Gravedad ----
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		# Caída más pesada si sueltas el salto a la mitad
		if velocity.y < 0 and not Input.is_action_pressed("ui_accept"):
			velocity.y += GRAVITY * 0.6 * delta

	# ---- Salto (con coyote + buffer) ----
	var can_jump = coyote_timer > 0.0
	if jump_buffer_timer > 0.0 and can_jump:
		velocity.y   = JUMP_VELOCITY
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		# Squash & stretch: estirarse al saltar
		target_scale = Vector2(0.75, 1.35)

	# ---- Aterrizaje ----
	var just_landed = not was_on_floor and is_on_floor()
	if just_landed:
		# Squash al aterrizar — proporcional a la velocidad de caída
		var impact = clamp(abs(velocity.y) / 1200.0, 0.1, 0.5)
		target_scale = Vector2(1.0 + impact, 1.0 - impact * 0.6)

	# ---- Movimiento horizontal ----
	var direction = Input.get_axis("ui_left", "ui_right")
	var accel = ACCEL_GROUND if is_on_floor() else ACCEL_AIR
	var decel = DECEL_GROUND if is_on_floor() else DECEL_AIR

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, accel * delta)
		# Flip del personaje — se escala el polygon, no el nodo raíz
		# para no afectar la colisión
		polygon.scale.x = sign(direction) * abs(polygon.scale.x)
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	# ---- Squash & stretch suavizado ----
	var current_scale = polygon.scale
	current_scale.x = move_toward(current_scale.x, sign(current_scale.x) * target_scale.x, SCALE_SPEED * delta)
	current_scale.y = move_toward(current_scale.y, target_scale.y, SCALE_SPEED * delta)
	polygon.scale = current_scale
	# Vuelve al tamaño normal
	target_scale = target_scale.move_toward(base_scale, SCALE_SPEED * delta)

	# ---- Timers de gracia ----
	coyote_timer      = max(coyote_timer - delta, 0.0)
	jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

	was_on_floor = is_on_floor()

	move_and_slide()
