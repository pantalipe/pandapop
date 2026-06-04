extends Node

# GameManager — singleton (autoload)
# Handles PP coins, upgrades, save/load

signal coins_changed(value: float)
signal cps_changed(value: float)  # coins per second

var coins: float = 0.0
var total_earned: float = 0.0
var coins_per_click: float = 1.0
var coins_per_second: float = 0.0

const SAVE_PATH = "user://save.dat"

# Upgrades: {name, description, base_cost, cps_bonus, cpc_bonus, count}
var upgrades: Array = [
	{"id": "panda",     "name": "Baby Panda",    "desc": "A panda mining PP for you.",       "base_cost": 15.0,    "cps": 0.1,  "cpc": 0.0, "count": 0},
	{"id": "bamboo",    "name": "Bamboo Farm",   "desc": "Bamboo converted into PP.",        "base_cost": 100.0,   "cps": 0.5,  "cpc": 0.0, "count": 0},
	{"id": "miner",     "name": "PP Miner",      "desc": "Dedicated blockchain miner.",      "base_cost": 500.0,   "cps": 2.0,  "cpc": 0.0, "count": 0},
	{"id": "node",      "name": "Full Node",     "desc": "Runs a full PandaPoints node.",    "base_cost": 2000.0,  "cps": 8.0,  "cpc": 0.0, "count": 0},
	{"id": "dapp",      "name": "Mini DApp",     "desc": "A tiny DApp generating yield.",    "base_cost": 8000.0,  "cps": 25.0, "cpc": 0.0, "count": 0},
	{"id": "exchange",  "name": "PP Exchange",   "desc": "Trade PP 24/7 automatically.",     "base_cost": 25000.0, "cps": 80.0, "cpc": 0.0, "count": 0},
]

func _ready() -> void:
	load_data()

func _process(delta: float) -> void:
	if coins_per_second > 0:
		add_coins(coins_per_second * delta)

func click() -> void:
	add_coins(coins_per_click)

func add_coins(amount: float) -> void:
	coins += amount
	total_earned += amount
	emit_signal("coins_changed", coins)

func get_upgrade_cost(index: int) -> float:
	var u = upgrades[index]
	return floor(u["base_cost"] * pow(1.15, u["count"]))

func buy_upgrade(index: int) -> bool:
	var cost = get_upgrade_cost(index)
	if coins >= cost:
		coins -= cost
		upgrades[index]["count"] += 1
		_recalculate()
		emit_signal("coins_changed", coins)
		save_data()
		return true
	return false

func _recalculate() -> void:
	coins_per_second = 0.0
	coins_per_click = 1.0
	for u in upgrades:
		coins_per_second += u["cps"] * u["count"]
	emit_signal("cps_changed", coins_per_second)

func save_data() -> void:
	var counts = []
	for u in upgrades:
		counts.append(u["count"])
	var data = {"coins": coins, "total": total_earned, "counts": counts}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		if data:
			coins = data.get("coins", 0.0)
			total_earned = data.get("total", 0.0)
			var counts = data.get("counts", [])
			for i in range(min(counts.size(), upgrades.size())):
				upgrades[i]["count"] = counts[i]
			_recalculate()
