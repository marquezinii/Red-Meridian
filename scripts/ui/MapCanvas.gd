extends Control

signal country_selected(country_id: String)

var countries: Array = []
var selected_country_id := ""
var player_country_id := ""
var hovered_country_id := ""
var global_tension := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = ""


func set_countries(value: Array) -> void:
	countries = value
	queue_redraw()


func set_selected_country(country_id: String) -> void:
	selected_country_id = country_id
	queue_redraw()


func set_player_country(country_id: String) -> void:
	player_country_id = country_id
	queue_redraw()


func set_global_tension(value: float) -> void:
	global_tension = value
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var country_id := _country_at(event.position)
		if country_id != hovered_country_id:
			hovered_country_id = country_id
			tooltip_text = _tooltip_for(country_id)
			queue_redraw()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var country_id := _country_at(event.position)
		if country_id != "":
			country_selected.emit(country_id)
			accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color.html("#07111f"), true)
	_draw_ocean_grid()
	_draw_region_bands()
	_draw_routes()
	_draw_countries()
	_draw_overlay()


func _draw_ocean_grid() -> void:
	var grid_color := Color(0.34, 0.48, 0.68, 0.15)
	for i in range(1, 8):
		var x := size.x * float(i) / 8.0
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
	for j in range(1, 5):
		var y := size.y * float(j) / 5.0
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)


func _draw_region_bands() -> void:
	var americas := PackedVector2Array([
		Vector2(size.x * 0.05, size.y * 0.20),
		Vector2(size.x * 0.31, size.y * 0.14),
		Vector2(size.x * 0.42, size.y * 0.84),
		Vector2(size.x * 0.24, size.y * 0.92),
		Vector2(size.x * 0.12, size.y * 0.58)
	])
	var eur_africa := PackedVector2Array([
		Vector2(size.x * 0.44, size.y * 0.22),
		Vector2(size.x * 0.62, size.y * 0.26),
		Vector2(size.x * 0.60, size.y * 0.86),
		Vector2(size.x * 0.48, size.y * 0.88),
		Vector2(size.x * 0.42, size.y * 0.50)
	])
	var asia := PackedVector2Array([
		Vector2(size.x * 0.62, size.y * 0.22),
		Vector2(size.x * 0.90, size.y * 0.27),
		Vector2(size.x * 0.85, size.y * 0.68),
		Vector2(size.x * 0.65, size.y * 0.72),
		Vector2(size.x * 0.58, size.y * 0.45)
	])

	draw_colored_polygon(americas, Color(0.16, 0.36, 0.29, 0.23))
	draw_colored_polygon(eur_africa, Color(0.36, 0.30, 0.18, 0.24))
	draw_colored_polygon(asia, Color(0.39, 0.20, 0.22, 0.22))


func _draw_routes() -> void:
	var route_color := Color(0.95, 0.78, 0.35, 0.26)
	var route_pairs := [
		["USA", "DEU"],
		["USA", "JPN"],
		["BRA", "ZAF"],
		["DEU", "IND"],
		["CHN", "RUS"],
		["CHN", "JPN"],
		["IND", "ZAF"]
	]

	for pair in route_pairs:
		var a := _country_position(String(pair[0]))
		var b := _country_position(String(pair[1]))
		if a != Vector2.INF and b != Vector2.INF:
			draw_line(a, b, route_color, 2.0, true)


func _draw_countries() -> void:
	var font := get_theme_default_font()
	for country in countries:
		var id := String(country.get("id", ""))
		var pos := _position_for(country)
		var radius := _marker_radius(country)
		var base_color := _country_color(country)
		var is_selected := id == selected_country_id
		var is_player := id == player_country_id
		var is_hovered := id == hovered_country_id

		draw_circle(pos + Vector2(0, 3), radius + 5.0, Color(0, 0, 0, 0.34))
		draw_circle(pos, radius + 5.0, Color(0.02, 0.04, 0.08, 0.86))
		draw_circle(pos, radius, base_color)

		var stats: Dictionary = country.get("stats", {})
		var readiness := float(stats.get("readiness", 0.0))
		var readiness_angle := TAU * clampf(readiness / 100.0, 0.0, 1.0)
		draw_arc(pos, radius + 8.0, -PI * 0.5, -PI * 0.5 + readiness_angle, 42, Color.html("#79D0FF"), 3.0, true)

		if is_selected:
			draw_arc(pos, radius + 13.0, 0.0, TAU, 64, Color.html("#F4D35E"), 3.0, true)
		elif is_hovered:
			draw_arc(pos, radius + 11.0, 0.0, TAU, 64, Color(1, 1, 1, 0.65), 2.0, true)

		if is_player:
			draw_arc(pos, radius + 18.0, 0.0, TAU, 64, Color.html("#80CFA9"), 2.5, true)

		var label := String(country.get("short_name", id))
		draw_string(font, pos + Vector2(radius + 10.0, 5.0), label, HORIZONTAL_ALIGNMENT_LEFT, 90.0, 14, Color.html("#E8EEF8"))


func _draw_overlay() -> void:
	var font := get_theme_default_font()
	var tension_text := "Global tension %.0f%%" % clampf(global_tension, 0.0, 100.0)
	draw_string(font, Vector2(18, 28), tension_text, HORIZONTAL_ALIGNMENT_LEFT, 280.0, 16, Color.html("#E8EEF8"))
	draw_string(font, Vector2(18, size.y - 22), "Abstract strategic map - click a country", HORIZONTAL_ALIGNMENT_LEFT, 420.0, 13, Color(0.86, 0.91, 0.98, 0.66))


func _country_at(point: Vector2) -> String:
	for country in countries:
		var pos := _position_for(country)
		var radius := _marker_radius(country) + 10.0
		if point.distance_to(pos) <= radius:
			return String(country.get("id", ""))
	return ""


func _tooltip_for(country_id: String) -> String:
	if country_id == "":
		return ""
	for country in countries:
		if String(country.get("id", "")) == country_id:
			var stats: Dictionary = country.get("stats", {})
			return "%s\nGDP: %.1fT\nStability: %.0f%%\nReadiness: %.0f%%" % [
				String(country.get("name", country_id)),
				float(stats.get("gdp", 0.0)) / 1000.0,
				float(stats.get("stability", 0.0)),
				float(stats.get("readiness", 0.0))
			]
	return ""


func _country_position(country_id: String) -> Vector2:
	for country in countries:
		if String(country.get("id", "")) == country_id:
			return _position_for(country)
	return Vector2.INF


func _position_for(country: Dictionary) -> Vector2:
	var map_data: Dictionary = country.get("map", {})
	return Vector2(
		float(map_data.get("x", 0.5)) * maxf(size.x, 1.0),
		float(map_data.get("y", 0.5)) * maxf(size.y, 1.0)
	)


func _marker_radius(country: Dictionary) -> float:
	var stats: Dictionary = country.get("stats", {})
	var military := float(stats.get("military", 40.0))
	return clampf(13.0 + military * 0.13, 17.0, 30.0)


func _country_color(country: Dictionary) -> Color:
	var color_value := String(country.get("color", "#AAB7C4"))
	if Color.html_is_valid(color_value):
		return Color.html(color_value)
	return Color.html("#AAB7C4")
