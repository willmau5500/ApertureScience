extends Node2D

func _ready():
	# --- FONDO oscuro azul metálico ---
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.04, 0.08)
	bg.size = Vector2(1152, 648)
	bg.position = Vector2(0, 0)
	add_child(bg)
	move_child(bg, 0)

	# --- PISO ---
	var floor_col = $StaticBody2D/CollisionShape2D
	var floor_shape = RectangleShape2D.new()
	floor_shape.size = Vector2(1152, 32)
	floor_col.shape = floor_shape
	floor_col.position = Vector2(576, 616)

	var floor_rect = $StaticBody2D/ColorRect
	floor_rect.color = Color(0.1, 0.15, 0.25)
	floor_rect.size = Vector2(1152, 32)
	floor_rect.position = Vector2(0, 600)

	# --- AGREGAR EL JUGADOR ---
	var player = preload("res://Player.tscn").instantiate()
	player.position = Vector2(200, 400)
	add_child(player)
