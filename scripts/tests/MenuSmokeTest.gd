extends SceneTree

var main_scene
var frame := 0


func _initialize() -> void:
	var packed_scene := load("res://scenes/main/Main.tscn")
	if packed_scene == null:
		push_error("Failed to load main scene.")
		quit(1)
		return

	main_scene = packed_scene.instantiate()
	root.add_child(main_scene)


func _process(_delta: float) -> bool:
	frame += 1
	match frame:
		2:
			main_scene._show_settings_screen()
		4:
			main_scene._apply_all_settings()
		6:
			main_scene._show_about_screen()
		8:
			main_scene._start_single_player()
		10:
			if main_scene.current_screen != "game":
				push_error("Single Player did not open the game screen.")
				quit(1)
				return false
			quit()
	return true
