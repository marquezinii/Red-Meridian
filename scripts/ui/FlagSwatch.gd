extends Control

var flag_id := ""


func _ready() -> void:
	custom_minimum_size = Vector2(86, 48)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color.html("#101823"), true)

	match flag_id:
		"BRA":
			_draw_brazil(rect)
		"USA":
			_draw_usa(rect)
		"CHN":
			_draw_china(rect)
		"RUS":
			_draw_soviet_union(rect)
		"JPN":
			_draw_japan(rect)
		"DEU":
			_draw_germany(rect)
		_:
			draw_rect(rect, Color.html("#263C58"), true)

	draw_rect(rect, Color(0.82, 0.90, 0.98, 0.62), false, 1.0)


func _draw_brazil(rect: Rect2) -> void:
	draw_rect(rect, Color.html("#1F8A4C"), true)
	var center := rect.get_center()
	var diamond := PackedVector2Array([
		Vector2(center.x, rect.position.y + rect.size.y * 0.12),
		Vector2(rect.position.x + rect.size.x * 0.88, center.y),
		Vector2(center.x, rect.position.y + rect.size.y * 0.88),
		Vector2(rect.position.x + rect.size.x * 0.12, center.y)
	])
	draw_colored_polygon(diamond, Color.html("#F2C94C"))
	draw_circle(center, minf(rect.size.x, rect.size.y) * 0.18, Color.html("#1A3F8F"))


func _draw_usa(rect: Rect2) -> void:
	var stripe_h := rect.size.y / 13.0
	for i in range(13):
		var color := Color.html("#B22234") if i % 2 == 0 else Color.html("#F7F7F7")
		draw_rect(Rect2(rect.position + Vector2(0, stripe_h * i), Vector2(rect.size.x, stripe_h + 1)), color, true)
	var canton := Rect2(rect.position, Vector2(rect.size.x * 0.42, stripe_h * 7))
	draw_rect(canton, Color.html("#243A73"), true)
	for row in range(4):
		for col in range(4):
			draw_circle(canton.position + Vector2(8 + col * 8, 7 + row * 8), 1.2, Color.html("#F7F7F7"))


func _draw_china(rect: Rect2) -> void:
	draw_rect(rect, Color.html("#DE2910"), true)
	_draw_star(rect.position + Vector2(rect.size.x * 0.22, rect.size.y * 0.30), 8, Color.html("#FFDE00"))
	for point in [Vector2(0.38, 0.18), Vector2(0.45, 0.32), Vector2(0.45, 0.48), Vector2(0.36, 0.60)]:
		_draw_star(rect.position + Vector2(rect.size.x * point.x, rect.size.y * point.y), 3.6, Color.html("#FFDE00"))


func _draw_soviet_union(rect: Rect2) -> void:
	draw_rect(rect, Color.html("#CC1E1E"), true)
	_draw_star(rect.position + Vector2(rect.size.x * 0.22, rect.size.y * 0.28), 8, Color.html("#F6D44A"))
	draw_line(rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.58), rect.position + Vector2(rect.size.x * 0.38, rect.size.y * 0.38), Color.html("#F6D44A"), 3.0)


func _draw_japan(rect: Rect2) -> void:
	draw_rect(rect, Color.html("#F5F5F5"), true)
	draw_circle(rect.get_center(), minf(rect.size.x, rect.size.y) * 0.24, Color.html("#BC002D"))


func _draw_germany(rect: Rect2) -> void:
	var stripe_h := rect.size.y / 3.0
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, stripe_h)), Color.html("#050505"), true)
	draw_rect(Rect2(rect.position + Vector2(0, stripe_h), Vector2(rect.size.x, stripe_h)), Color.html("#DD0000"), true)
	draw_rect(Rect2(rect.position + Vector2(0, stripe_h * 2), Vector2(rect.size.x, stripe_h)), Color.html("#FFCE00"), true)


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		var angle := -PI / 2.0 + (PI * 2.0 * float(i) / 10.0)
		var r := radius if i % 2 == 0 else radius * 0.42
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color)
