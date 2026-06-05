extends Node2D

# Main — clicker game controller

@onready var coin_label: Label = $UI/TopBar/VBox/CoinLabel
@onready var cps_label: Label = $UI/TopBar/VBox/CpsLabel
@onready var click_button: TextureButton = $UI/ClickButton
@onready var upgrade_list: VBoxContainer = $UI/UpgradePanel/ScrollContainer/UpgradeList
@onready var background: Sprite2D = $Background

const UPGRADE_ICONS = [
	"res://assets/sprites/upgrade_panda.png",
	"res://assets/sprites/upgrade_farm.png",
	"res://assets/sprites/upgrade_forest.png",
	"res://assets/sprites/upgrade_village.png",
	"res://assets/sprites/upgrade_factory.png",
	"res://assets/sprites/upgrade_temple.png",
]

func _ready() -> void:
	GameManager.bamboo_changed.connect(_on_bamboo_changed)
	GameManager.bps_changed.connect(_on_bps_changed)
	click_button.pressed.connect(_on_click)
	_setup_click_button()
	_setup_topbar()
	_build_upgrade_list()
	_on_bamboo_changed(GameManager.bamboo)
	_on_bps_changed(GameManager.bamboo_per_second)

func _setup_topbar() -> void:
	var topbar = $UI/TopBar
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.75)
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	topbar.add_theme_stylebox_override("panel", style)
	# Força cor branca nos labels
	coin_label.add_theme_color_override("font_color", Color.WHITE)
	cps_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))

func _setup_click_button() -> void:
	var tex = load("res://assets/sprites/panda_main.png")
	if tex:
		click_button.texture_normal = tex

func _on_click() -> void:
	GameManager.click()

func _on_bamboo_changed(value: float) -> void:
	coin_label.text = "🎋 " + _format(value) + " bamboo"
	_refresh_upgrade_buttons()

func _on_bps_changed(value: float) -> void:
	if value > 0:
		cps_label.text = _format(value) + " bamboo/s"
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
	# Painel escuro atrás da lista
	var panel = upgrade_list.get_parent().get_parent()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.85)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel.add_theme_stylebox_override("panel", panel_style)

	for i in range(GameManager.upgrades.size()):
		var u = GameManager.upgrades[i]

		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 72)

		# Icon
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(56, 56)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var icon_path = UPGRADE_ICONS[i] if i < UPGRADE_ICONS.size() else UPGRADE_ICONS[-1]
		var tex = load(icon_path)
		if tex:
			icon.texture = tex
		hbox.add_child(icon)

		# Button com fundo visível
		var btn = Button.new()
		btn.name = "Upgrade_" + str(i)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = _upgrade_text(i)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_buy_upgrade.bind(i))

		# Estilo normal
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.15, 0.35, 0.15, 0.95)
		style_normal.corner_radius_top_right = 8
		style_normal.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_normal)

		# Estilo desabilitado
		var style_disabled = StyleBoxFlat.new()
		style_disabled.bg_color = Color(0.1, 0.1, 0.1, 0.8)
		style_disabled.corner_radius_top_right = 8
		style_disabled.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("disabled", style_disabled)

		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.7, 1.0))

		hbox.add_child(btn)
		upgrade_list.add_child(hbox)

func _on_buy_upgrade(index: int) -> void:
	GameManager.buy_upgrade(index)
	_refresh_upgrade_buttons()

func _refresh_upgrade_buttons() -> void:
	for i in range(GameManager.upgrades.size()):
		var hbox = upgrade_list.get_child(i)
		if hbox:
			var btn = hbox.get_node_or_null("Upgrade_" + str(i))
			if btn:
				btn.text = _upgrade_text(i)
				btn.disabled = GameManager.bamboo < GameManager.get_upgrade_cost(i)

func _upgrade_text(i: int) -> String:
	var u = GameManager.upgrades[i]
	var cost = GameManager.get_upgrade_cost(i)
	return u["name"] + " [" + str(u["count"]) + "]\n" + _format(cost) + " bamboo — " + u["desc"]
