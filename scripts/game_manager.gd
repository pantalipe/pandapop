extends Node

# GameManager — singleton (autoload)
# Handles PP coins, upgrades, save/load

signal bamboo_changed(value: float)
signal bps_changed(value: float)  # bamboo per second

var bamboo: float = 0.0
var total_earned: float = 0.0
var bamboo_per_click: float = 1.0
var bamboo_per_second: float = 0.0

const SAVE_PATH = "user://save.dat"

# Upgrades: {name, description, base_cost, cps_bonus, cpc_bonus, count}
var upgrades: Array = [
	{"id": "panda",    "name": "Baby Panda",      "desc": "A little panda collecting bamboo for you.", "base_cost": 15.0,    "bps": 0.1,  "count": 0},
	{"id": "farm",     "name": "Bamboo Farm",     "desc": "A whole farm growing bamboo.",              "base_cost": 100.0,   "bps": 0.5,  "count": 0},
	{"id": "forest",   "name": "Bamboo Forest",   "desc": "An entire forest of bamboo.",               "base_cost": 500.0,   "bps": 2.0,  "count": 0},
	{"id": "village",  "name": "Panda Village",   "desc": "A village full of busy pandas.",            "base_cost": 2000.0,  "bps": 8.0,  "count": 0},
	{"id": "factory",  "name": "Bamboo Factory",  "desc": "Industrial bamboo production.",             "base_cost": 8000.0,  "bps": 25.0, "count": 0},
	{"id": "temple",   "name": "Panda Temple",    "desc": "Ancient pandas blessing your harvest.",     "base_cost": 25000.0, "bps": 80.0, "count": 0},
]

func _ready() -> void:
	load_data()

func _process(delta: float) -> void:
	if bamboo_per_second > 0:
		add_bamboo(bamboo_per_second * delta)

func click() -> void:
	add_bamboo(bamboo_per_click)

func add_bamboo(amount: float) -> void:
	bamboo += amount
	total_earned += amount
	emit_signal("bamboo_changed", bamboo)

func get_upgrade_cost(index: int) -> float:
	var u = upgrades[index]
	return floor(u["base_cost"] * pow(1.15, u["count"]))

func buy_upgrade(index: int) -> bool:
	var cost = get_upgrade_cost(index)
	if bamboo >= cost:
		bamboo -= cost
		upgrades[index]["count"] += 1
		_recalculate()
		emit_signal("bamboo_changed", bamboo)
		save_data()
		return true
	return false

func _recalculate() -> void:
	bamboo_per_second = 0.0
	bamboo_per_click = 1.0
	for u in upgrades:
		bamboo_per_second += u["bps"] * u["count"]
	emit_signal("bps_changed", bamboo_per_second)

func save_data() -> void:
	var counts = []
	for u in upgrades:
		counts.append(u["count"])
	var data = {"bamboo": bamboo, "total": total_earned, "counts": counts}
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
			bamboo = data.get("bamboo", 0.0)
			total_earned = data.get("total", 0.0)
			var counts = data.get("counts", [])
			for i in range(min(counts.size(), upgrades.size())):
				upgrades[i]["count"] = counts[i]
			_recalculate()
