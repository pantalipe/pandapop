extends Node2D

# OverlayMain — controlador do modo "desktop companion".
# Fatia vertical mínima: janela transparente/always-on-top/borderless,
# panda flutuando dentro de uma área, clique gera bamboo.
# Reaproveita 100% do GameManager (bamboo, bps, upgrades, save/load)
# sem nenhuma alteração na lógica de currency.

@onready var panda_area: Area2D = $PandaArea
@onready var panda_sprite: Sprite2D = $PandaArea/PandaSprite
@onready var bamboo_label: Label = $BambooLabel

const WINDOW_SIZE := Vector2i(220, 220)
const FLOAT_MARGIN := 45.0      # o quanto o panda se afasta do centro ao flutuar
const FLOAT_SPEED := 0.6
const DRAG_THRESHOLD := 6.0     # px de movimento do mouse até virar "arrastar janela"
const SCREEN_MARGIN := 24       # distância da borda da tela no posicionamento padrão

var _center: Vector2
var _float_seed: float

var _tracking_press: bool = false
var _drag_started: bool = false
var _press_mouse_screen_pos: Vector2i = Vector2i.ZERO
var _press_window_pos: Vector2i = Vector2i.ZERO

func _ready() -> void:
	var window := get_window()
	window.size = WINDOW_SIZE
	window.borderless = true
	window.always_on_top = true
	window.transparent = true
	window.set_transparent_background(true)

	_center = Vector2(WINDOW_SIZE) * 0.5
	panda_area.position = _center
	_float_seed = randf() * 1000.0

	_restore_window_position(window)

	GameManager.bamboo_changed.connect(_on_bamboo_changed)
	_on_bamboo_changed(GameManager.bamboo)

	panda_area.input_pickable = true
	panda_area.input_event.connect(_on_panda_input_event)

func _restore_window_position(window: Window) -> void:
	var saved = GameManager.get_saved_window_position()
	if saved != null:
		window.position = saved
		return
	# Primeira execução: ancora no canto inferior direito da tela primária.
	var screen_id := DisplayServer.window_get_current_screen()
	var screen_rect := DisplayServer.screen_get_usable_rect(screen_id)
	window.position = Vector2i(
		screen_rect.position.x + screen_rect.size.x - WINDOW_SIZE.x - SCREEN_MARGIN,
		screen_rect.position.y + screen_rect.size.y - WINDOW_SIZE.y - SCREEN_MARGIN * 2
	)

func _process(_delta: float) -> void:
	if _tracking_press:
		_update_drag_or_click()

	if _drag_started:
		return  # durante o arrastar, a posição do panda não flutua (evita "briga" visual)
	var t := Time.get_ticks_msec() / 1000.0 + _float_seed
	var offset := Vector2(
		sin(t * FLOAT_SPEED) * FLOAT_MARGIN,
		sin(t * FLOAT_SPEED * 1.3 + 1.0) * FLOAT_MARGIN * 0.6
	)
	panda_area.position = _center + offset

# --- Clique restrito à sprite via Area2D.input_event ---
# Área2D só recebe input quando o cursor está sobre o CollisionShape2D,
# então isso já resolve "não capturar clique fora do panda" sem hacks
# de per-pixel hit-test no nível do SO.

func _on_panda_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_tracking_press = true
		_drag_started = false
		_press_mouse_screen_pos = DisplayServer.mouse_get_position()
		_press_window_pos = get_window().position

# --- Arrastar a janela / soltar clique ---
# IMPORTANTE: usa DisplayServer.mouse_get_position() (coordenadas absolutas
# do SO), NÃO event.global_position (coordenadas locais da viewport/janela).
# Coordenadas locais mudam quando a PRÓPRIA janela se move — usar isso pra
# calcular o quanto mover a janela cria um loop de realimentação: a janela
# se move -> a posição local do mouse muda mesmo sem o mouse se mexer ->
# gera mais delta -> a janela tenta se mover de novo. Na prática isso
# aparecia como a janela "tremendo" e ficando pra trás do cursor.
# Poll em _process (em vez de _input) também evita depender de eventos de
# motion chegarem enquanto o cursor está fora da área do panda.

func _update_drag_or_click() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var current_screen := DisplayServer.mouse_get_position()
		var moved: Vector2i = current_screen - _press_mouse_screen_pos
		if not _drag_started and Vector2(moved).length() > DRAG_THRESHOLD:
			_drag_started = true
		if _drag_started:
			get_window().position = _press_window_pos + moved
	else:
		# Botão foi solto
		if _drag_started:
			GameManager.save_window_position(get_window().position)
		else:
			GameManager.click()
			_spawn_click_feedback()
		_tracking_press = false
		_drag_started = false

# --- UI mínima: contador de bamboo + feedback de clique ---

func _on_bamboo_changed(value: float) -> void:
	bamboo_label.text = "🎋 " + _format(value)

func _format(value: float) -> String:
	if value >= 1_000_000:
		return "%.2f M" % (value / 1_000_000)
	elif value >= 1_000:
		return "%.2f K" % (value / 1_000)
	else:
		return "%d" % int(value)

func _spawn_click_feedback() -> void:
	var lbl := Label.new()
	lbl.text = "+" + _format(GameManager.bamboo_per_click) + " 🎋"
	lbl.z_index = 100
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.3))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	add_child(lbl)
	# Clampado pra nunca nascer/animar fora dos limites da janela (220x220) —
	# uma janela de SO recorta o conteúdo nas bordas, diferente da viewport
	# do editor. Sem isso, se o panda estivesse flutuando perto do topo, o
	# texto nascia (ou terminava a animação) fora da área visível.
	var start_y: float = clamp(panda_area.position.y - 34.0, 34.0, WINDOW_SIZE.y - 40.0)
	lbl.position = Vector2(panda_area.position.x - 16.0, start_y)
	var tween := create_tween()
	tween.tween_property(lbl, "position", lbl.position + Vector2(0, -20), 0.55)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 0.55)
	tween.tween_callback(lbl.queue_free)
