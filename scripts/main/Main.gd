extends Control

const MapCanvasScript = preload("res://scripts/ui/MapCanvas.gd")
const COUNTRY_DATA_PATH := "res://data/countries.json"

var countries: Array = []
var selected_country_id := ""
var active_focuses: Dictionary = {}
var log_lines: Array[String] = []

var current_year := 2027
var current_month := 1
var current_day := 1
var elapsed_days := 0
var paused := true
var speed := 1
var sim_accumulator := 0.0
var global_tension := 18.0

var date_label: Label
var status_label: Label
var pause_button: Button
var tension_bar: ProgressBar
var map_canvas
var country_panel: VBoxContainer
var focus_panel: VBoxContainer
var log_label: RichTextLabel


func _ready() -> void:
	DisplayServer.window_set_title("Red Meridian")
	_load_countries()
	if countries.is_empty():
		push_error("Nenhum pais foi carregado de %s" % COUNTRY_DATA_PATH)
		return

	selected_country_id = String(countries[0].get("id", ""))
	_build_layout()
	_log("Red Meridian iniciado. Prototipo local pronto para testes.")
	_refresh_all()
	set_process(true)


func _process(delta: float) -> void:
	if paused:
		return

	sim_accumulator += delta * float(speed)
	while sim_accumulator >= 0.65:
		sim_accumulator -= 0.65
		_advance_day()


func _load_countries() -> void:
	var file := FileAccess.open(COUNTRY_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Falha ao abrir %s" % COUNTRY_DATA_PATH)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_ARRAY:
		countries = parsed
	else:
		push_error("Arquivo de paises invalido: %s" % COUNTRY_DATA_PATH)


func _build_layout() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color.html("#050A13")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	root.add_child(_build_top_bar())

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var left_panel := _make_panel()
	left_panel.custom_minimum_size = Vector2(320, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(left_panel)

	var left_scroll := ScrollContainer.new()
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(left_scroll)

	country_panel = VBoxContainer.new()
	country_panel.add_theme_constant_override("separation", 10)
	left_scroll.add_child(country_panel)

	var center := VBoxContainer.new()
	center.add_theme_constant_override("separation", 10)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(center)

	var map_panel := _make_panel()
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(map_panel)

	map_canvas = MapCanvasScript.new()
	map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_canvas.country_selected.connect(_select_country)
	map_panel.add_child(map_canvas)

	var log_panel := _make_panel()
	log_panel.custom_minimum_size = Vector2(0, 150)
	center.add_child(log_panel)

	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = false
	log_label.fit_content = false
	log_label.scroll_following = true
	log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_panel.add_child(log_label)

	var right_panel := _make_panel()
	right_panel.custom_minimum_size = Vector2(370, 0)
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right_panel)

	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(right_scroll)

	focus_panel = VBoxContainer.new()
	focus_panel.add_theme_constant_override("separation", 10)
	right_scroll.add_child(focus_panel)


func _build_top_bar() -> Control:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(0, 70)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	panel.add_child(bar)

	var title_box := VBoxContainer.new()
	title_box.custom_minimum_size = Vector2(270, 0)
	bar.add_child(title_box)

	var title := Label.new()
	title.text = "RED MERIDIAN"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color.html("#E8EEF8"))
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Simulador geopolitico e militar 2D"
	subtitle.add_theme_color_override("font_color", Color(0.86, 0.91, 0.98, 0.62))
	title_box.add_child(subtitle)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	date_label = Label.new()
	date_label.custom_minimum_size = Vector2(160, 0)
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_label.add_theme_font_size_override("font_size", 18)
	date_label.add_theme_color_override("font_color", Color.html("#E8EEF8"))
	bar.add_child(date_label)

	status_label = Label.new()
	status_label.custom_minimum_size = Vector2(110, 0)
	status_label.add_theme_color_override("font_color", Color.html("#B8C5D6"))
	bar.add_child(status_label)

	tension_bar = ProgressBar.new()
	tension_bar.custom_minimum_size = Vector2(170, 22)
	tension_bar.min_value = 0
	tension_bar.max_value = 100
	tension_bar.show_percentage = true
	bar.add_child(tension_bar)

	pause_button = Button.new()
	pause_button.custom_minimum_size = Vector2(110, 34)
	pause_button.pressed.connect(_toggle_pause)
	bar.add_child(pause_button)

	var day_button := Button.new()
	day_button.text = "+1 dia"
	day_button.custom_minimum_size = Vector2(80, 34)
	day_button.pressed.connect(_advance_day)
	bar.add_child(day_button)

	for speed_value in [1, 3, 7]:
		var speed_button := Button.new()
		speed_button.text = "%sx" % speed_value
		speed_button.custom_minimum_size = Vector2(54, 34)
		speed_button.pressed.connect(_set_speed.bind(speed_value))
		bar.add_child(speed_button)

	return panel


func _refresh_all() -> void:
	_refresh_top_bar()
	_refresh_map()
	_refresh_country_panel()
	_refresh_focus_panel()
	_refresh_log()


func _refresh_top_bar() -> void:
	date_label.text = "%02d/%02d/%04d" % [current_day, current_month, current_year]
	status_label.text = "Pausado" if paused else "Rodando %sx" % speed
	pause_button.text = "Continuar" if paused else "Pausar"
	tension_bar.value = global_tension


func _refresh_map() -> void:
	map_canvas.set_countries(countries)
	map_canvas.set_selected_country(selected_country_id)
	map_canvas.set_global_tension(global_tension)


func _refresh_country_panel() -> void:
	_clear_children(country_panel)
	var country := _selected_country()
	if country.is_empty():
		return

	country_panel.add_child(_section_title(String(country.get("name", "Pais"))))
	country_panel.add_child(_muted_label("%s | %s | Capital: %s" % [
		String(country.get("region", "")),
		String(country.get("bloc", "")),
		String(country.get("capital", ""))
	]))
	country_panel.add_child(_muted_label("Lider: %s" % String(country.get("leader", "Pendente"))))

	var stats: Dictionary = country.get("stats", {})
	country_panel.add_child(_stat_row("GDP", "$%.2fT" % (float(stats.get("gdp", 0.0)) / 1000.0)))
	country_panel.add_child(_progress_row("Estabilidade", float(stats.get("stability", 0.0)), Color("#79D0FF")))
	country_panel.add_child(_progress_row("Poder militar", float(stats.get("military", 0.0)), Color("#D95F5F")))
	country_panel.add_child(_progress_row("Prontidao", float(stats.get("readiness", 0.0)), Color("#F4D35E")))
	country_panel.add_child(_progress_row("Diplomacia", float(stats.get("diplomacy", 0.0)), Color("#80CFA9")))
	country_panel.add_child(_progress_row("Tensao local", float(stats.get("tension", 0.0)), Color("#D18CE0")))

	country_panel.add_child(_section_title("Acoes de governo"))
	country_panel.add_child(_decision_button("Pacote economico", "economy"))
	country_panel.add_child(_decision_button("Investir em defesa", "defense"))
	country_panel.add_child(_decision_button("Pressao diplomatica", "pressure"))
	country_panel.add_child(_decision_button("Desescalar tensoes", "deescalate"))


func _refresh_focus_panel() -> void:
	_clear_children(focus_panel)
	var country := _selected_country()
	if country.is_empty():
		return

	focus_panel.add_child(_section_title("Arvore de foco"))
	focus_panel.add_child(_muted_label("Primeira versao: cada pais tem focos nacionais com duracao e efeitos. Depois vamos transformar isso em uma arvore visual completa."))

	var country_id := String(country.get("id", ""))
	if active_focuses.has(country_id):
		var active: Dictionary = active_focuses[country_id]
		var focus: Dictionary = active.get("focus", {})
		focus_panel.add_child(_status_card(
			"Foco ativo",
			"%s\nRestam %d dias" % [String(focus.get("title", "")), int(active.get("remaining", 0))]
		))

	var focuses: Array = country.get("focuses", [])
	for focus in focuses:
		focus_panel.add_child(_focus_card(country_id, focus))


func _refresh_log() -> void:
	var text := ""
	for i in range(log_lines.size()):
		if i > 0:
			text += "\n"
		text += log_lines[i]
	log_label.text = text


func _select_country(country_id: String) -> void:
	selected_country_id = country_id
	var country := _selected_country()
	if not country.is_empty():
		_log("Pais selecionado: %s" % String(country.get("name", country_id)))
	_refresh_all()


func _toggle_pause() -> void:
	paused = not paused
	_refresh_top_bar()


func _set_speed(value: int) -> void:
	speed = value
	paused = false
	_log("Velocidade ajustada para %sx." % speed)
	_refresh_all()


func _advance_day() -> void:
	elapsed_days += 1
	current_day += 1
	if current_day > _days_in_month(current_month, current_year):
		current_day = 1
		current_month += 1
		if current_month > 12:
			current_month = 1
			current_year += 1

	_process_focuses()
	if elapsed_days % 7 == 0:
		_weekly_tick()

	_refresh_all()


func _weekly_tick() -> void:
	for country in countries:
		var stats: Dictionary = country.get("stats", {})
		var stability := float(stats.get("stability", 50.0))
		var tension := float(stats.get("tension", 20.0))
		var gdp := float(stats.get("gdp", 1000.0))
		var readiness := float(stats.get("readiness", 40.0))

		stats["gdp"] = maxf(50.0, gdp * (1.0 + (stability - 50.0) / 100000.0))
		stats["readiness"] = clampf(readiness + (float(stats.get("military", 40.0)) - readiness) * 0.02, 0.0, 100.0)
		stats["tension"] = clampf(tension + (global_tension - tension) * 0.01, 0.0, 100.0)
		country["stats"] = stats

	global_tension = clampf(global_tension + 0.1, 0.0, 100.0)


func _process_focuses() -> void:
	var completed: Array[String] = []
	for country_id in active_focuses.keys():
		var active: Dictionary = active_focuses[country_id]
		active["remaining"] = int(active.get("remaining", 0)) - 1
		active_focuses[country_id] = active
		if int(active.get("remaining", 0)) <= 0:
			completed.append(String(country_id))

	for country_id in completed:
		var active: Dictionary = active_focuses[country_id]
		var focus: Dictionary = active.get("focus", {})
		_apply_focus_effects(country_id, focus)
		active_focuses.erase(country_id)
		_log("Foco concluido: %s (%s)." % [String(focus.get("title", "")), country_id])


func _apply_focus_effects(country_id: String, focus: Dictionary) -> void:
	var country := _country_by_id(country_id)
	if country.is_empty():
		return

	var stats: Dictionary = country.get("stats", {})
	var effects: Dictionary = focus.get("effects", {})
	for key in effects.keys():
		var amount := float(effects[key])
		if key == "global_tension":
			global_tension = clampf(global_tension + amount, 0.0, 100.0)
		elif stats.has(key):
			stats[key] = float(stats.get(key, 0.0)) + amount

	_clamp_stats(stats)
	country["stats"] = stats


func _start_focus(country_id: String, focus: Dictionary) -> void:
	if active_focuses.has(country_id):
		_log("Este pais ja tem um foco ativo.")
		return

	active_focuses[country_id] = {
		"focus": focus,
		"remaining": int(focus.get("duration_days", 30))
	}
	_log("Foco iniciado: %s (%s)." % [String(focus.get("title", "")), country_id])
	_refresh_all()


func _run_decision(decision_id: String) -> void:
	var country := _selected_country()
	if country.is_empty():
		return

	var stats: Dictionary = country.get("stats", {})
	var country_name := String(country.get("name", "Pais"))

	match decision_id:
		"economy":
			stats["gdp"] = float(stats.get("gdp", 0.0)) + 25.0
			stats["stability"] = float(stats.get("stability", 0.0)) + 1.0
			_log("%s aprovou um pacote economico." % country_name)
		"defense":
			stats["military"] = float(stats.get("military", 0.0)) + 1.5
			stats["readiness"] = float(stats.get("readiness", 0.0)) + 2.0
			stats["stability"] = float(stats.get("stability", 0.0)) - 0.5
			global_tension = clampf(global_tension + 0.6, 0.0, 100.0)
			_log("%s elevou investimentos de defesa." % country_name)
		"pressure":
			stats["diplomacy"] = float(stats.get("diplomacy", 0.0)) + 1.0
			stats["tension"] = float(stats.get("tension", 0.0)) + 2.0
			global_tension = clampf(global_tension + 0.8, 0.0, 100.0)
			_log("%s iniciou pressao diplomatica." % country_name)
		"deescalate":
			stats["diplomacy"] = float(stats.get("diplomacy", 0.0)) + 1.5
			stats["tension"] = float(stats.get("tension", 0.0)) - 2.5
			global_tension = clampf(global_tension - 0.5, 0.0, 100.0)
			_log("%s buscou reduzir tensoes." % country_name)

	_clamp_stats(stats)
	country["stats"] = stats
	_refresh_all()


func _clamp_stats(stats: Dictionary) -> void:
	for key in ["stability", "military", "readiness", "diplomacy", "tension"]:
		if stats.has(key):
			stats[key] = clampf(float(stats[key]), 0.0, 100.0)
	if stats.has("gdp"):
		stats["gdp"] = maxf(float(stats["gdp"]), 50.0)


func _selected_country() -> Dictionary:
	return _country_by_id(selected_country_id)


func _country_by_id(country_id: String) -> Dictionary:
	for country in countries:
		if String(country.get("id", "")) == country_id:
			return country
	return {}


func _days_in_month(month: int, year: int) -> int:
	if month == 2:
		var leap := (year % 4 == 0 and year % 100 != 0) or year % 400 == 0
		return 29 if leap else 28
	if month in [4, 6, 9, 11]:
		return 30
	return 31


func _clear_children(node: Node) -> void:
	while node.get_child_count() > 0:
		var child := node.get_child(0)
		node.remove_child(child)
		child.queue_free()


func _log(message: String) -> void:
	var stamp := "%02d/%02d/%04d" % [current_day, current_month, current_year]
	log_lines.append("[%s] %s" % [stamp, message])
	while log_lines.size() > 8:
		log_lines.remove_at(0)


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style_box(Color.html("#0B1524"), Color.html("#1F3148")))
	return panel


func _style_box(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", Color.html("#E8EEF8"))
	return label


func _muted_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.86, 0.91, 0.98, 0.66))
	return label


func _stat_row(name: String, value: String) -> Control:
	var row := HBoxContainer.new()
	var left := _muted_label(name)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var right := Label.new()
	right.text = value
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_theme_color_override("font_color", Color.html("#E8EEF8"))
	row.add_child(right)
	return row


func _progress_row(name: String, value: float, color: Color) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)

	var row := HBoxContainer.new()
	var label := _muted_label(name)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value_label := Label.new()
	value_label.text = "%.0f%%" % value
	value_label.add_theme_color_override("font_color", Color.html("#E8EEF8"))
	row.add_child(value_label)
	box.add_child(row)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 12)
	bar.add_theme_stylebox_override("fill", _style_box(color, color))
	box.add_child(bar)

	return box


func _decision_button(text: String, decision_id: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 36)
	button.pressed.connect(_run_decision.bind(decision_id))
	return button


func _focus_card(country_id: String, focus: Dictionary) -> Control:
	var panel := _make_panel()
	panel.add_theme_stylebox_override("panel", _style_box(Color.html("#101C2E"), Color.html("#263C58")))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)

	box.add_child(_section_title(String(focus.get("title", "Foco"))))
	box.add_child(_muted_label(String(focus.get("description", ""))))
	box.add_child(_muted_label("Duracao: %d dias" % int(focus.get("duration_days", 30))))
	box.add_child(_muted_label("Efeitos: %s" % _format_effects(focus.get("effects", {}))))

	var button := Button.new()
	button.text = "Iniciar foco"
	button.disabled = active_focuses.has(country_id)
	button.pressed.connect(_start_focus.bind(country_id, focus))
	box.add_child(button)

	return panel


func _status_card(title: String, text: String) -> Control:
	var panel := _make_panel()
	panel.add_theme_stylebox_override("panel", _style_box(Color.html("#172536"), Color.html("#F4D35E")))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(_section_title(title))
	box.add_child(_muted_label(text))
	return panel


func _format_effects(effects: Dictionary) -> String:
	var parts: Array[String] = []
	for key in effects.keys():
		var amount := float(effects[key])
		var sign := "+" if amount >= 0 else ""
		parts.append("%s%s %s" % [sign, _format_number(amount), String(key)])
	var text := ""
	for i in range(parts.size()):
		if i > 0:
			text += ", "
		text += parts[i]
	return text


func _format_number(value: float) -> String:
	if absf(value - roundf(value)) < 0.01:
		return "%d" % int(roundf(value))
	return "%.1f" % value
