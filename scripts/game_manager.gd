extends Node

# GameManager — singleton (autoload)
# Handles PP coins, upgrades, save/load

signal bamboo_changed(value: float)
signal bps_changed(value: float)  # bamboo per second
signal click_landed(amount: float, is_crit: bool, combo_multiplier: float)  # feedback de clique
signal offline_earnings_applied(amount: float, seconds_away: float)  # ganho ao reabrir

var bamboo: float = 0.0
var total_earned: float = 0.0
var bamboo_per_click: float = 1.0
var bamboo_per_second: float = 0.0

const CRIT_CHANCE := 0.1          # 10% de chance de crit
const CRIT_MULTIPLIER := 3.0
const COMBO_WINDOW := 0.6         # segundos entre cliques pra manter o combo
const COMBO_STEP := 0.05          # +5% por clique consecutivo no combo
const COMBO_MAX_BONUS := 1.0      # até +100% (2x) no topo do combo

var _combo_count: int = 0
var _last_click_time: float = -999.0


const SAVE_PATH = "user://save.dat"
const _NO_WINDOW_POS := Vector2i(-999999, -999999)
const AUTOSAVE_INTERVAL := 30.0        # segundos entre autosaves de segurança
const OFFLINE_CAP_HOURS := 12.0        # ganho offline conta no máximo essas horas
const OFFLINE_MIN_SECONDS := 30.0      # abaixo disso, não vale a pena nem avisar

# Posição da janela do modo overlay (desktop companion). null-like via sentinel,
# porque Godot Dictionary/store_var não serializa null de forma limpa.
var _saved_window_pos: Vector2i = _NO_WINDOW_POS

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

	var autosave_timer := Timer.new()
	autosave_timer.wait_time = AUTOSAVE_INTERVAL
	autosave_timer.autostart = true
	autosave_timer.timeout.connect(save_data)
	add_child(autosave_timer)

	# Salva ao fechar a janela (Alt+F4, taskbar, etc.) — sem isso, bambu
	# acumulado passivamente desde o último autosave/compra seria perdido.
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(_on_close_requested)

func _on_close_requested() -> void:
	save_data()
	get_tree().quit()

func _process(delta: float) -> void:
	if bamboo_per_second > 0:
		add_bamboo(bamboo_per_second * delta)

func click() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_click_time <= COMBO_WINDOW:
		_combo_count += 1
	else:
		_combo_count = 0
	_last_click_time = now

	var combo_multiplier: float = 1.0 + min(_combo_count * COMBO_STEP, COMBO_MAX_BONUS)
	var is_crit := randf() < CRIT_CHANCE
	var crit_multiplier := CRIT_MULTIPLIER if is_crit else 1.0

	var amount: float = bamboo_per_click * combo_multiplier * crit_multiplier
	add_bamboo(amount)
	emit_signal("click_landed", amount, is_crit, combo_multiplier)

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
	var base_bpc: float = 1.0
	for u in upgrades:
		bamboo_per_second += u.get("bps", 0.0) * u["count"]
		base_bpc += u.get("bpc", 0.0) * u["count"]
	# Synergy: 1% do BPS total vira bônus de clique
	bamboo_per_click = base_bpc + (bamboo_per_second * 0.01)
	emit_signal("bps_changed", bamboo_per_second)

func save_data() -> void:
	var upgrade_counts: Dictionary = {}
	for u in upgrades:
		upgrade_counts[u["id"]] = u["count"]
	var data = {
		"bamboo": bamboo,
		"total": total_earned,
		"upgrade_counts": upgrade_counts,
		"window_x": _saved_window_pos.x,
		"window_y": _saved_window_pos.y,
		"last_save_time": Time.get_unix_time_from_system(),
	}
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
			var upgrade_counts: Dictionary = data.get("upgrade_counts", {})
			for u in upgrades:
				u["count"] = upgrade_counts.get(u["id"], 0)
			_recalculate()
			var wx: int = data.get("window_x", _NO_WINDOW_POS.x)
			var wy: int = data.get("window_y", _NO_WINDOW_POS.y)
			_saved_window_pos = Vector2i(wx, wy)
			_apply_offline_earnings(data.get("last_save_time", 0.0))

## Concede bambu pelo tempo que o companion ficou fechado, proporcional ao
## bps atual, com teto de OFFLINE_CAP_HOURS (evita número absurdo se ficar
## semanas fechado, e incentiva abrir com regularidade em vez de acumular
## indefinidamente).
func _apply_offline_earnings(last_save_time: float) -> void:
	if last_save_time <= 0.0 or bamboo_per_second <= 0.0:
		return
	var now := Time.get_unix_time_from_system()
	var elapsed: float = max(0.0, now - last_save_time)
	var counted: float = min(elapsed, OFFLINE_CAP_HOURS * 3600.0)
	if counted < OFFLINE_MIN_SECONDS:
		return
	var earned: float = bamboo_per_second * counted
	add_bamboo(earned)
	# Autoloads têm _ready() chamado antes da cena principal — emitir na hora
	# significaria que ninguém ainda está ouvindo. call_deferred adia a
	# emissão pro fim do frame de setup inicial, depois que a cena principal
	# já teve chance de se conectar.
	call_deferred("emit_signal", "offline_earnings_applied", earned, counted)

## Retorna a posição salva da janela overlay, ou null se nunca foi definida
## (primeira execução / ainda não existe save no formato novo).
func get_saved_window_position():
	if _saved_window_pos == _NO_WINDOW_POS:
		return null
	return _saved_window_pos

## Chamado pelo overlay ao soltar o arrastar da janela.
func save_window_position(pos: Vector2i) -> void:
	_saved_window_pos = pos
	save_data()
