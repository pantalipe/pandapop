extends Window

# StatusWindow — janela de status/menu do companion (separada da janela
# principal, real janela de SO graças a embedded_subwindows=false).
# Mostra bambu/produção/saciedade e concentra ações que antes brigavam
# por espaço de clique com o panda flutuante (ex.: alimentar).

@onready var bamboo_label: Label = $Margin/VBox/BambooLabel
@onready var bps_label: Label = $Margin/VBox/BpsLabel
@onready var satiety_label: Label = $Margin/VBox/SatietyLabel
@onready var satiety_fill: ColorRect = $Margin/VBox/SatietyTrack/SatietyFill
@onready var feed_button: Button = $Margin/VBox/FeedButton
@onready var feed_feedback: Label = $Margin/VBox/FeedFeedback

const SATIETY_BAR_WIDTH := 232.0
const COLOR_FED := Color(0.4, 0.85, 0.3, 0.9)
const COLOR_CONTENT := Color(0.9, 0.75, 0.2, 0.9)
const COLOR_HUNGRY := Color(0.85, 0.35, 0.3, 0.9)

func _ready() -> void:
	# rendering/viewport/transparent_background=true é uma configuração
	# GLOBAL do projeto (necessária pra janela overlay transparente) —
	# toda Viewport/Window nova herda esse default, inclusive esta. Sem
	# essa linha, o conteúdo desta janela renderiza com fundo transparente
	# mas sem o resto da infraestrutura de janela transparente (sem
	# window.transparent=true nela), o que resultava na janela inteira
	# ficando invisível em vez de aparecer com fundo normal.
	transparent_bg = false

	# Fechar (X da janela) só esconde — não é a saída do app, é só o menu.
	close_requested.connect(hide)

	GameManager.bamboo_changed.connect(_refresh)
	GameManager.bps_changed.connect(_refresh)
	GameManager.satiety_changed.connect(_refresh)
	GameManager.fed.connect(_on_fed)
	feed_button.pressed.connect(_on_feed_pressed)
	_refresh()

func _refresh(_unused = null) -> void:
	bamboo_label.text = "🎋 Bambu: " + _format(GameManager.bamboo)
	bps_label.text = "Produção: " + _format(GameManager.bamboo_per_second) + "/s"
	satiety_label.text = "Saciedade: " + str(int(GameManager.satiety)) + "%"
	satiety_fill.size.x = SATIETY_BAR_WIDTH * (GameManager.satiety / 100.0)
	if GameManager.satiety >= GameManager.SATIETY_TIER_FED:
		satiety_fill.color = COLOR_FED
	elif GameManager.satiety >= GameManager.SATIETY_TIER_CONTENT:
		satiety_fill.color = COLOR_CONTENT
	else:
		satiety_fill.color = COLOR_HUNGRY
	feed_button.text = "Alimentar (" + _format(GameManager.get_feed_cost()) + " 🎋)"

func _format(value: float) -> String:
	if value >= 1_000_000:
		return "%.2f M" % (value / 1_000_000)
	elif value >= 1_000:
		return "%.2f K" % (value / 1_000)
	else:
		return "%d" % int(value)

func _on_feed_pressed() -> void:
	if not GameManager.feed():
		feed_feedback.text = "Bambu insuficiente."
		feed_feedback.add_theme_color_override("font_color", COLOR_HUNGRY)

func _on_fed(_cost: float) -> void:
	feed_feedback.text = "Alimentado! 🎋"
	feed_feedback.add_theme_color_override("font_color", COLOR_FED)
