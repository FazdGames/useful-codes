extends YSort

var weakplatform = preload("res://Objects/WeakPlatform.tscn")
var movingplatform = preload("res://Objects/MovingPlatform.tscn")
var iceplatform = preload("res://Objects/IcePlatform.tscn")
var fireplatform = preload("res://Objects/FirePlatform.tscn")
var healplatform = preload("res://Objects/HealPlatform.tscn")
var berry = preload("res://Objects/Berry.tscn")
var water = preload("res://Objects/Water.tscn")
var teleport = preload("res://Objects/Teleport.tscn")  

var platforms = []
var MINIMUM_DISTANCE_BETWEEN_PLATFORMS = 30
var last_spawn_height = 0
var last_score_trigger = 0

var water_spawned = false
var teleport_spawned = false

func _ready():
	last_spawn_height = get_node("Player").position.y

func is_position_valid(new_position: Vector2) -> bool:
	for platform_position in platforms:
		if abs(platform_position.y - new_position.y) > MINIMUM_DISTANCE_BETWEEN_PLATFORMS:
			continue
		if new_position.distance_to(platform_position) < MINIMUM_DISTANCE_BETWEEN_PLATFORMS:
			return false
	return true

func cleanup_platform_positions():
	var filtered = []
	for pos in platforms:
		if pos.y <= last_spawn_height + 150:
			filtered.append(pos)
	platforms = filtered

func spawn_berry(platform_position: Vector2):
	var berry_instance = berry.instance()
	berry_instance.position = platform_position + Vector2(0, -50)
	add_child(berry_instance)

func spawn_platform_at(pos: Vector2):
	pos.y = min(pos.y, last_spawn_height - MINIMUM_DISTANCE_BETWEEN_PLATFORMS)
	var attempt = 0
	while attempt < 10:
		if is_position_valid(pos):
			var chance = randf()
			var instance
			if chance < 0.03:
				instance = healplatform.instance()
			elif chance < 0.12:
				instance = iceplatform.instance()
			elif chance < 0.15:
				instance = fireplatform.instance()
			elif chance < 0.27:
				instance = movingplatform.instance()
			elif HUD.score >= 150 and chance < 0.31 and not water_spawned:
				instance = water.instance()
				water_spawned = true
			else:
				instance = weakplatform.instance()

			$SpawnSystem/Spawner.position = pos
			instance.position = pos
			platforms.append(pos)
			last_spawn_height = pos.y
			add_child(instance)

			if (HUD.score - last_score_trigger) >= 20:
				last_score_trigger = HUD.score
				spawn_berry(pos)
			return instance
		else:
			pos += Vector2(rand_range(-20.0, 20.0), rand_range(-20.0, 20.0))
			attempt += 1
	return null

func _process(delta):
	if HUD.score >= 300 and not teleport_spawned:
		var player_position = get_node("Player").position
		var safe_pos = player_position + Vector2(rand_range(-50, 50), rand_range(-50, 50))  
		var teleport_instance = teleport.instance()
		teleport_instance.position = safe_pos
		add_child(teleport_instance)
		teleport_spawned = true

func _on_SpawnTimerPlatform_timeout():
	if HUD.score >= 300 and teleport_spawned:
		return

	water_spawned = false
	teleport_spawned = false  
	last_spawn_height = min(last_spawn_height, get_node("Player").position.y + MINIMUM_DISTANCE_BETWEEN_PLATFORMS)
	cleanup_platform_positions()

	var player_pos = get_node("Player").position
	var area = $SpawnSystem/SpawnArea
	var base_pos = player_pos + Vector2(randf() * 50 - 50, -MINIMUM_DISTANCE_BETWEEN_PLATFORMS)

	if HUD.score < 300:
		spawn_platform_at(base_pos)

		if randf() < 0.5:
			var side_direction = -1 if randf() < 0.5 else 1
			var horizontal_offset = MINIMUM_DISTANCE_BETWEEN_PLATFORMS * 2 * side_direction
			var vertical_offset = rand_range(-20.0, 20.0)
			var side_pos = base_pos + Vector2(horizontal_offset, vertical_offset)
			side_pos.x = clamp(side_pos.x, area.rect_position.x, area.rect_position.x + area.rect_size.x)
			spawn_platform_at(side_pos)

	var score_interval = lerp(1.6, 0.5, clamp(HUD.score / 300.0, 0, 1))
	$SpawnSystem/SpawnTimerPlatform.wait_time = score_interval
	MINIMUM_DISTANCE_BETWEEN_PLATFORMS = 30 + int(HUD.score / 10) * 3

	$SpawnSystem/SpawnTimerPlatform.start()
