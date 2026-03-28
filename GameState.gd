## GameState.gd
## Autoload singleton — agregar en Project > Project Settings > Autoload
## Nombre: GameState
##
## Guarda el estado global de la partida:
## - Zona actual y sala
## - Notas recolectadas
## - Jefes derrotados
## - Progreso de dialogos

extends Node

signal note_collected(note_id: String)
signal boss_died(boss_id: String)
signal zone_changed(zone: int)

# --- Progreso ---
var current_zone  : int    = 1
var current_sala  : int    = 1
var bosses_dead   : Dictionary = {}   # {"RUST": true, "AXIOM": true, ...}
var notes_found   : Array[String] = []

# Mapeo sala → escena
const SALA_SCENES : Dictionary = {
	1:  "res://scenes/Sala1.tscn",
	2:  "res://scenes/Sala2.tscn",
	3:  "res://scenes/Sala3.tscn",
	4:  "res://scenes/Sala4.tscn",
	5:  "res://scenes/Sala5.tscn",
	6:  "res://scenes/Sala6.tscn",
	7:  "res://scenes/Sala7.tscn",
	8:  "res://scenes/Sala8.tscn",
	9:  "res://scenes/Sala9.tscn",
	10: "res://scenes/Sala10.tscn",
	11: "res://scenes/Sala11.tscn",
	12: "res://scenes/Sala12.tscn",
	13: "res://scenes/SalaFinal.tscn",
}

const ZONE_OF_SALA : Dictionary = {
	1: 1, 2: 1, 3: 1,
	4: 2, 5: 2, 6: 2,
	7: 3, 8: 3, 9: 3,
	10: 4, 11: 4, 12: 4,
	13: 5,
}

# ============================================================
# API pública
# ============================================================

func collect_note(note_id: String) -> void:
	if note_id not in notes_found:
		notes_found.append(note_id)
		emit_signal("note_collected", note_id)

func defeat_boss(boss_id: String) -> void:
	bosses_dead[boss_id] = true
	emit_signal("boss_died", boss_id)

func is_boss_dead(boss_id: String) -> bool:
	return bosses_dead.get(boss_id, false)

func set_sala(sala: int) -> void:
	current_sala = sala
	current_zone = ZONE_OF_SALA.get(sala, current_zone)
	emit_signal("zone_changed", current_zone)

func get_scene_for_sala(sala: int) -> String:
	return SALA_SCENES.get(sala, "")

func get_zone_name() -> String:
	match current_zone:
		1: return "Zona Oxidada"
		2: return "Zona Blanca"
		3: return "Zona Espejo"
		4: return "Zona Oscura"
		5: return "Zona Final"
	return "Aperture Science"

# ============================================================
# Guardar / cargar
# ============================================================
const SAVE_PATH := "user://savegame.cfg"

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "sala",        current_sala)
	cfg.set_value("progress", "zone",        current_zone)
	cfg.set_value("progress", "notes",       notes_found)
	cfg.set_value("progress", "bosses_dead", bosses_dead)
	cfg.save(SAVE_PATH)

func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	current_sala  = cfg.get_value("progress", "sala",        1)
	current_zone  = cfg.get_value("progress", "zone",        1)
	notes_found   = cfg.get_value("progress", "notes",       [])
	bosses_dead   = cfg.get_value("progress", "bosses_dead", {})
