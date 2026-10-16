extends Node2D

# Blocky Quest: replayable exploration prototype.
const SAVE_PATH := "user://blocky_quest_save.json"
const LEVEL_COUNT := 12
const STARS_PER_LEVEL := 8
const WORLD_NAMES := ["Sunny Meadow", "Candy Canyon", "Frosty Peaks", "Jungle Ruins", "Moon Garden", "Ocean Bay", "Desert Dunes", "Cloud Kingdom", "Crystal Caves", "Autumn Woods", "Lava Lights", "Rainbow Summit"]

var language := "auto"
var total_stars := 0
var level_index := 0
var level_stars := 0
var completed_levels := 0
var player_pos := Vector2(115, 330)
var move_speed := 230.0
var collectibles: Array[Vector2] = []
var collected: Array[bool] = []
var message := "Explore the world and collect every star!"
var message_time := 4.0
var touch_target := Vector2(-1, -1)

func _ready() -> void:
	_load_progress()
	_make_level()
	queue_redraw()

func _process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): direction.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): direction.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): direction.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): direction.y += 1
	if direction.length() > 0:
		player_pos += direction.normalized() * move_speed * delta
	elif touch_target.x >= 0:
		var to_target := touch_target - player_pos
		if to_target.length() < 8:
			touch_target = Vector2(-1, -1)
		else:
			player_pos += to_target.normalized() * move_speed * delta
	player_pos.x = clampf(player_pos.x, 28, 932)
	player_pos.y = clampf(player_pos.y, 125, 492)
	if Input.is_key_pressed(KEY_SPACE):
		_collect_nearby_star()
	if message_time > 0:
		message_time -= delta
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		touch_target = event.position
		_collect_nearby_star()
	elif event is InputEventMouseButton and event.pressed:
		touch_target = event.position
		_collect_nearby_star()

func _make_level() -> void:
	collectibles.clear()
	collected.clear()
	# Deterministic, spread-out locations make every level fair and replayable.
	for i in range(STARS_PER_LEVEL):
		var x := 90.0 + float((i * 113 + level_index * 47) % 780)
		var y := 155.0 + float((i * 67 + level_index * 31) % 300)
		collectibles.append(Vector2(x, y))
		collected.append(false)
	player_pos = Vector2(70, 320)
	touch_target = Vector2(-1, -1)

func _collect_nearby_star() -> void:
	for i in range(collectibles.size()):
		if not collected[i] and player_pos.distance_to(collectibles[i]) < 82:
			collected[i] = true
			total_stars += 1
			level_stars += 1
			message = "Great find! %d of %d stars in this world." % [level_stars, STARS_PER_LEVEL]
			message_time = 2.5
			_save_progress()
			if level_stars >= STARS_PER_LEVEL:
				_complete_level()
			queue_redraw()
			return
	message = "Move closer to a glowing star to collect it."
	message_time = 1.8

func _complete_level() -> void:
	completed_levels = max(completed_levels, level_index + 1)
	if level_index < LEVEL_COUNT - 1:
		level_index += 1
		level_stars = 0
		message = "World complete! Welcome to " + WORLD_NAMES[level_index] + "!"
		message_time = 4.0
		_make_level()
	else:
		level_index = 0
		level_stars = 0
		message = "You explored every world! A new star hunt begins!"
		message_time = 5.0
		completed_levels = LEVEL_COUNT
		_make_level()
	_save_progress()

func _draw() -> void:
	var sky_colors := [Color("#8bd5ff"), Color("#ffb8dc"), Color("#b6dcff"), Color("#9ce4a3"), Color("#c9b6ff"), Color("#8be0e4")]
	var grass_colors := [Color("#9ce28b"), Color("#f4a8cb"), Color("#d5e8fa"), Color("#67c987"), Color("#b4e7a3"), Color("#6bc6c9")]
	var palette_index := level_index % sky_colors.size()
	draw_rect(Rect2(0, 0, 960, 540), sky_colors[palette_index])
	draw_rect(Rect2(0, 110, 960, 430), grass_colors[palette_index])
	# Layered block hills and a winding path.
	for i in range(10):
		var x := i * 110 - 25
		draw_rect(Rect2(x, 145 + (i % 3) * 19, 96, 70), grass_colors[palette_index].darkened(0.12))
	draw_rect(Rect2(0, 402, 960, 66), Color("#e8d19b"))
	draw_rect(Rect2(0, 418, 960, 12), Color("#f7e7bf"))
	# Trees, crystals, or candy-like decorations change between worlds.
	for i in range(7):
		var x := 30 + i * 145
		var y := 230 + (i % 3) * 38
		if level_index % 3 == 0:
			draw_rect(Rect2(x + 13, y + 30, 18, 46), Color("#98613c"))
			draw_rect(Rect2(x, y, 44, 45), Color("#2d9c62"))
			draw_rect(Rect2(x + 7, y - 7, 30, 25), Color("#45bb70"))
		elif level_index % 3 == 1:
			draw_rect(Rect2(x, y, 43, 43), Color("#ff78b7"))
			draw_rect(Rect2(x + 8, y - 8, 27, 27), Color("#ffe07b"))
		else:
			draw_rect(Rect2(x + 5, y + 10, 32, 50), Color("#7b77e8"))
			draw_rect(Rect2(x, y, 42, 22), Color("#b9b5ff"))
	# Collectible tokens.
	for i in range(collectibles.size()):
		if not collected[i]:
			var p := collectibles[i]
			draw_rect(Rect2(p.x - 12, p.y - 12, 24, 24), Color("#ffdb4d"))
			draw_rect(Rect2(p.x - 5, p.y - 20, 10, 40), Color("#fff09a"))
			draw_rect(Rect2(p.x - 20, p.y - 5, 40, 10), Color("#fff09a"))
	# Friendly block character.
	draw_rect(Rect2(player_pos.x - 17, player_pos.y - 24, 34, 34), Color("#ff9f68"))
	draw_rect(Rect2(player_pos.x - 11, player_pos.y - 16, 7, 7), Color("#263238"))
	draw_rect(Rect2(player_pos.x + 5, player_pos.y - 16, 7, 7), Color("#263238"))
	draw_rect(Rect2(player_pos.x - 11, player_pos.y + 10, 9, 20), Color("#4263eb"))
	draw_rect(Rect2(player_pos.x + 2, player_pos.y + 10, 9, 20), Color("#4263eb"))
	# HUD.
	draw_rect(Rect2(14, 12, 440, 82), Color("#ffffffdd"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 39), "BLOCKY QUEST", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#25324a"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 62), "World %d/%d: %s" % [level_index + 1, LEVEL_COUNT, WORLD_NAMES[level_index]], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#25324a"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 83), "WASD/arrows or tap to move • Space to collect", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#25324a"))
	draw_rect(Rect2(720, 14, 226, 75), Color("#ffffffdd"))
	draw_string(ThemeDB.fallback_font, Vector2(735, 40), "Total stars: %d" % total_stars, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#25324a"))
	draw_string(ThemeDB.fallback_font, Vector2(735, 64), "This world: %d/%d" % [level_stars, STARS_PER_LEVEL], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#25324a"))
	draw_string(ThemeDB.fallback_font, Vector2(735, 82), "Worlds explored: %d/%d" % [completed_levels, LEVEL_COUNT], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#25324a"))
	if message_time > 0:
		draw_rect(Rect2(185, 105, 590, 36), Color("#ffffffdd"))
		draw_string(ThemeDB.fallback_font, Vector2(200, 129), message, HORIZONTAL_ALIGNMENT_LEFT, 560, 15, Color("#25324a"))
	draw_string(ThemeDB.fallback_font, Vector2(20, 525), "Your adventure saves automatically on this device.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#25324a"))

func _save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"total_stars": total_stars,
			"level_index": level_index,
			"level_stars": level_stars,
			"completed_levels": completed_levels,
			"language": language
		}))

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data is Dictionary:
			total_stars = int(data.get("total_stars", data.get("stars", 0)))
			level_index = clampi(int(data.get("level_index", 0)), 0, LEVEL_COUNT - 1)
			level_stars = clampi(int(data.get("level_stars", 0)), 0, STARS_PER_LEVEL)
			completed_levels = clampi(int(data.get("completed_levels", 0)), 0, LEVEL_COUNT)
			language = str(data.get("language", "auto"))
