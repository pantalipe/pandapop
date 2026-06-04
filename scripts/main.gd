extends Node2D

# Main — clicker game controller

@onready var coin_label: Label = $UI/TopBar/CoinLabel
@onready var cps_label: Label = $UI/TopBar/CpsLabel
@onready var click_button: Button = $UI/ClickArea/ClickButton
@onready var upgrade_list: VBoxContainer = $UI/UpgradePanel/ScrollContainer/UpgradeList

func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.cps_changed.connect(_on_cps_changed)
	click_button.pressed.connect(_on_click)
	_build_upgrade_list()
	_on_coins_changed(GameManager.coins)
	_on_cps_changed(GameManager.coins_per_second)

func _on_click() -> void:
	GameManager.click()

func _on_coins_changed(value: float) -> void:
	coin_label.text = "PP " + _format(value)
	_refresh_upgrade_buttons()

func _on_cps_changed(value: float) -> void:
	if value > 0:
		cps_label.text = _format(value) + " PP/s"
	else:
		cps_label.text = ""

func _format(value: float) -> String:
	if value >= 1_000_000:
		return "%.2f M" % (value / 1_000_000)
	elif value >= 1_000:
		return "%.2f K" % (value / 1_000)
	else:
		return "%d" % int(value)

func _build_upgrade_list() -> void:
	for i in range(GameManager.upgrades.size()):
		var u = GameManager.upgrades[i]
		var btn = Button.new()
		btn.name = "Upgrade_" + str(i)
		btn.custom_minimum_size = Vector2(0, 70)
		btn.text = _upgrade_text(i)
		btn.pressed.connect(_on_buy_upgrade.bind(i))
		upgrade_list.add_child(btn)

func _on_buy_upgrade(index: int) -> void:
	GameManager.buy_upgrade(index)
	_refresh_upgrade_buttons()

func _refresh_upgrade_buttons() -> void:
	for i in range(GameManager.upgrades.size()):
		var btn = upgrade_list.get_node_or_null("Upgrade_" + str(i))
		if btn:
			btn.text = _upgrade_text(i)
			btn.disabled = GameManager.coins < GameManager.get_upgrade_cost(i)

func _upgrade_text(i: int) -> String:
	var u = GameManager.upgrades[i]
	var cost = GameManager.get_upgrade_cost(i)
	return u["name"] + " [" + str(u["count"]) + "]\n" + _format(cost) + " PP — " + u["desc"]
