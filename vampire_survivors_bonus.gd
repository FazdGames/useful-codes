extends CanvasLayer  

var fire_magic = 5
var speed_fireball = 4
var radius_fireball = 1.025
var regen_overdrive = 0.7
var amount_heal = 1
var max_health : int = 10
var health = max_health
var max_overdrive : int = 5
var overdrive = 0
var speed = 100
var blink_distance = 50
var experience = 0
var max_experience = 8
var enemies = 0
var amount_exp = 1
var lvl = 1
var heat = 0
var boss_death = 0
var critical_chance = 0.02

var overdrive_active = false
var overdrive_damage_time = 0.0
var current_options = []

var is_anim_playing = false
var all_stats = ["fire_magic", "speed_fireball", "regen_overdrive", "max_health", "max_overdrive", "blink_distance"]
var advanced_stats = ["critical_chance", "amount_heal"]  # новый список для стат, доступных после 3 уровня


var stat_options = [
	["fire_magic", "speed_fireball"],
	["regen_overdrive", "max_health"],
	["max_overdrive", "blink_distance"]
]

var stat_translations = {
	"fire_magic": "огненный урон",
	"speed_fireball": "скорость огня",
	"regen_overdrive": "уменьшение перегрева",
	"max_health": "здоровье",
	"max_overdrive": "предел прегрева",
	"blink_distance": "дальность скачка",
	"critical_chance": "шанс крита",
	"amount_heal": "количество исцеления"
}

func _process(delta):
	if overdrive_active:
		overdrive_damage_time -= delta
		if overdrive_damage_time > 0:
			# Наносим урон
			lose_health(max_health * 0.04 * delta)  # Наносим 4% от максимального уровня здоровья за секунду
		else:
			overdrive -= regen_overdrive * delta
			if overdrive <= 0:
				overdrive_active = false

func rules_overdrive():
	if overdrive >= max_overdrive:
		overdrive_active = true
		overdrive_damage_time = max_health * 0.2
	elif overdrive <= 0:
		overdrive = 0
		overdrive_active = false

func _ready():
	$StatsBanner/OverdriveRegen.text = String(regen_overdrive)
	$StatsBanner/FireMagic.text = String(fire_magic)
	$StatsBanner/FireSpeed.text = String(speed_fireball)
	$StatsBanner/Overdrive.text = String(max_overdrive)
	$StatsBanner/Health.text = String(max_health)
	$StatsBanner/BlinkDistance.text = String(blink_distance)
	$HeatBar/Heat.value = heat

func gain_exp(amount_exp = 1, enemy_lvl = 0):
	if enemy_lvl > 0:
		amount_exp += enemy_lvl
	experience += amount_exp
	while experience >= max_experience:
		lvl = lvl + 1
		$Sounds/LvlSound.play()
		$AnimatedEffects.play("lvlup")
		experience -= max_experience
		max_experience += 2
		if lvl == 3:  # когда игрок достигает 3 уровня
			all_stats += advanced_stats  # добавляем продвинутые статы в список всех стат
		show_level_up_options()

func show_level_up_options():
	current_options.clear()
	for _i in range(3):
		var available_stats = all_stats.duplicate()  # Создаем копию списка всех статистик
		var option = []
		for _j in range(3):
			var index = randi() % available_stats.size()
			option.append(available_stats[index])
			available_stats.remove(index)  # Удаляем выбранную статистику, чтобы она не повторялась внутри одного усиления
		current_options.append(option)
	for i in range(3):
		$BoostOptions.get_node("BoostButton" + str(i)).visible = true
		var boost_amount1 = get_boost_amount(current_options[i][0])
		var boost_amount2 = get_boost_amount(current_options[i][1])
		var boost_amount3 = get_boost_amount(current_options[i][2])
		$BoostOptions.get_node("BoostLabel" + str(i)).text = stat_translations[current_options[i][0]] + " + " + str(boost_amount1) + "\n" + stat_translations[current_options[i][1]] + " + " + str(boost_amount2) + "\n" + stat_translations[current_options[i][2]] + " + " + str(boost_amount3)

func apply_stat_boost(stat):
	var boost_amount = get_boost_amount(stat)  # получаем увеличение из функции get_boost_amount
	if stat == "fire_magic":
		fire_magic += boost_amount
	elif stat == "speed_fireball":
		speed_fireball += boost_amount
	elif stat == "regen_overdrive":
		regen_overdrive += boost_amount  # убираем умножение на 0.1
	elif stat == "max_health":
		max_health += boost_amount
	elif stat == "max_overdrive":
		max_overdrive += boost_amount
	elif stat == "blink_distance":
		blink_distance += boost_amount
	elif stat == "critical_chance":  # новая статистика
		critical_chance += boost_amount  # увеличиваем шанс крита на boost_amount за каждый уровень
	elif stat == "amount_heal":  # новая статистика
		amount_heal += boost_amount  # увеличиваем количество исцеления на boost_amount за каждый уровень
	for i in range(3):
		$BoostOptions.get_node("BoostButton" + str(i)).visible = false
		$BoostOptions.get_node("BoostLabel" + str(i)).text = ""  # Добавьте эту строку

func get_boost_amount(stat):
	var boost_amount = lvl  # увеличение усиления с ростом уровня
	if stat == "regen_overdrive":
		boost_amount = 0.1  # увеличение regen_overdrive всегда 0.1, независимо от уровня
	elif stat == "critical_chance":
		boost_amount = min(0.1, boost_amount * 1)  # увеличение шанса крита не более чем на 10% за каждый уровень
	elif stat == "amount_heal":
		boost_amount = min(1, boost_amount)  # увеличение количества исцеления не более чем на 1 за каждый уровень
	return boost_amount
	
func _on_BoostButton0_pressed():
	apply_stat_boost(current_options[0][0])
	apply_stat_boost(current_options[0][1])
	apply_stat_boost(current_options[0][2])

func _on_BoostButton1_pressed():
	apply_stat_boost(current_options[1][0])
	apply_stat_boost(current_options[1][1])
	apply_stat_boost(current_options[1][2])

func _on_BoostButton2_pressed():
	apply_stat_boost(current_options[2][0])
	apply_stat_boost(current_options[2][1])
	apply_stat_boost(current_options[2][2])

func _on_Restart_pressed():
	get_tree().change_scene("res://Levels/FirstLevel.tscn")
	max_health = 10
	health = 10
	max_overdrive = 5
	experience = 0
	enemies = 0 
	lvl = 1
	regen_overdrive = 0.7
	fire_magic = 5
	blink_distance = 50
	speed_fireball = 4
	amount_heal = 1
	amount_exp = 1
	heat = 0
	boss_death = 0
	overdrive_active = false  # Добавьте эту строку
	critical_chance = 0.02
	$Menu/Restart.visible = false
	$Sounds/WinMusic.playing = false
	_ready()

func _on_AnimatedEffects_animation_finished():
	$AnimatedEffects.stop()

func lose_health(damage = 1):
	health -= damage
	$Sounds/HitSound.play()
	if health <= 0:
		health = 0
		_on_Restart_pressed()
	_ready()

func _on_MenuTimer_timeout():
	$Menu/Restart.visible = false

func _on_Menu_pressed():
	$Menu/Restart.visible = true
	$Timers/MenuTimer.start()

func boss_death():
	boss_death += 1
	if boss_death >= 1:
		$Sounds/WinMusic.playing = true
		$Timers/WinTimer.start()
		_ready()

func _on_WinTimer_timeout():
	_on_Restart_pressed()
