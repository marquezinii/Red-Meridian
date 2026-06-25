extends Control

var initials := ""
var accent_color := Color.html("#80CFA9")


func _ready() -> void:
	custom_minimum_size = Vector2(118, 138)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color.html("#071019"), true)
	draw_rect(rect, accent_color.darkened(0.42), false, 2.0)

	for i in range(6):
		var alpha := 0.08 - float(i) * 0.01
		draw_rect(Rect2(Vector2(i * size.x / 6.0, 0), Vector2(size.x / 7.0, size.y)), Color(accent_color.r, accent_color.g, accent_color.b, alpha), true)

	var center_x := size.x * 0.5
	var head_center := Vector2(center_x, size.y * 0.38)
	draw_circle(head_center + Vector2(0, 2), size.x * 0.18, Color(0.02, 0.04, 0.06, 0.95))
	draw_circle(head_center, size.x * 0.17, accent_color.lightened(0.14))
	draw_arc(head_center, size.x * 0.19, PI * 1.08, PI * 1.92, 22, Color.html("#DCE6F4"), 2.0)

	var shoulders := PackedVector2Array([
		Vector2(size.x * 0.18, size.y * 0.88),
		Vector2(size.x * 0.30, size.y * 0.64),
		Vector2(size.x * 0.70, size.y * 0.64),
		Vector2(size.x * 0.82, size.y * 0.88)
	])
	draw_colored_polygon(shoulders, accent_color.darkened(0.28))
	draw_line(Vector2(size.x * 0.24, size.y * 0.87), Vector2(size.x * 0.76, size.y * 0.87), Color(0.88, 0.94, 1.0, 0.45), 1.4)

	if not initials.is_empty():
		var font := get_theme_default_font()
		var font_size := 21
		var text_size := font.get_string_size(initials, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, Vector2((size.x - text_size.x) * 0.5, size.y * 0.95), initials, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.html("#E8EEF8"))
