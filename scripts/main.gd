extends Node2D

const SAVE_PATH := "user://blocky_quest_save.json"

var language := "auto"
var stars := 0
var player_pos := Vector2(480, 300)
var move_speed := 220.0
var keys := {}

func _ready() -> void:
	_load_progress()
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): direction.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): direction.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): direction.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): direction.y += 1
	player_pos += direction.normalized() * move_speed * delta
	player_pos.x = clampf(player_pos.x, 35, 925)
	player_pos.y = clampf(player_pos.y, 105, 505)
	if Input.is_key_pressed(KEY_SPACE):
		_collect_nearby_star()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		# Tap near the character to collect a nearby star.
		_collect_nearby_star()
	elif event is InputEventMouseButton and event.pressed:
		_collect_nearby_star()

func _collect_nearby_star() -> void:
	if player_pos.distance_to(Vector2(740, 330)) < 120:
		stars += 1
		_save_progress()
		queue_redraw()

func _draw() -> void:
	# Bright, simple block-world landscape.
	draw_rect(Rect2(0, 0, 960, 540), Color("#8bd5ff"))
	draw_rect(Rect2(0, 95, 960, 445), Color("#9ce28b"))
	# Distant block hills
	for i in range(8):
		var x := i * 130 - 20
		draw_rect(Rect2(x, 150 + (i % 3) * 20, 110, 65), Color("#70c875"))
	# Path
	draw_rect(Rect2(0, 390, 960, 95), Color("#e8d19b"))
	# Blocky trees
	for p in [Vector2(120, 250), Vector2(835, 220), Vector2(320, 180)]:
		draw_rect(Rect2(p.x + 18, p.y + 35, 22, 50), Color("#98613c"))
		draw_rect(Rect2(p.x, p.y, 58, 52), Color("#2d9c62"))
		draw_rect(Rect2(p.x + 9, p.y - 9, 40, 32), Color("#45bb70"))
	# Collectible star token
	draw_rect(Rect2(716, 306, 48, 48), Color("#ffdb4d"))
	draw_rect(Rect2(728, 294, 24, 72), Color("#ffdb4d"))
	draw_rect(Rect2(704, 318, 72, 24), Color("#ffdb4d"))
	# Player: friendly block character
	draw_rect(Rect2(player_pos.x - 19, player_pos.y - 28, 38, 38), Color("#ff9f68"))
	draw_rect(Rect2(player_pos.x - 14, player_pos.y - 21, 8, 8), Color("#263238"))
	draw_rect(Rect2(player_pos.x + 6, player_pos.y - 21, 8, 8), Color("#263238"))
	draw_rect(Rect2(player_pos.x - 12, player_pos.y + 10, 10, 22), Color("#4263eb"))
	draw_rect(Rect2(player_pos.x + 3, player_pos.y + 10, 10, 22), Color("#4263eb"))
	# HUD
	draw_rect(Rect2(16, 14, 370, 70), Color("#ffffffcc"))
	draw_string(ThemeDB.fallback_font, Vector2(32, 43), "BLOCKY QUEST", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("#25324a"))
	draw_string(ThemeDB.fallback_font, Vector2(32, 69), "Move: WASD / arrows  •  Tap to collect", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#25324a"))
	draw_rect(Rect2(790, 18, 150, 54), Color("#ffffffdd"))
	draw_string(ThemeDB.fallback_font, Vector2(808, 51), "Stars: %d" % stars, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#25324a"))
	draw_string(ThemeDB.fallback_font, Vector2(32, 525), "Prototype • progress saved on this device", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#25324a"))

func _save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"stars": stars, "language": language}))

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data is Dictionary:
			stars = int(data.get("stars", 0))
			language = str(data.get("language", "auto"))
