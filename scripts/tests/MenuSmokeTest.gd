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
			main_scene._show_settings_screen(2)
			var preset_select := _make_graphics_preset_select()
			main_scene._on_graphics_preset_selected(3, preset_select)
			if main_scene.settings_active_tab != 2:
				push_error("Graphics preset change did not preserve the Graphics tab.")
				quit(1)
				return false
			main_scene._on_graphics_bool_changed(false, "water_reflections", preset_select)
			if main_scene.settings_graphics_preset != "custom":
				push_error("Manual graphics changes did not switch the preset to Custom.")
				quit(1)
				return false
		6:
			main_scene._show_settings_screen(3)
			main_scene.settings_master_volume = 100.0
			main_scene.settings_music_volume = 90.0
			main_scene.settings_effects_volume = 85.0
			main_scene.settings_interface_volume = 80.0
			main_scene._on_master_volume_changed(60.0)
			if main_scene.settings_music_volume > 60.0 or main_scene.settings_effects_volume > 60.0 or main_scene.settings_interface_volume > 60.0:
				push_error("Master volume did not clamp sub-volume settings.")
				quit(1)
				return false
			var music_slider: HSlider = main_scene.audio_sub_sliders.get("music")
			if music_slider == null or music_slider.max_value != 100.0 or not is_equal_approx(music_slider.value, 60.0):
				push_error("Music slider did not stay on a 0-100 scale while matching the master cap.")
				quit(1)
				return false
			main_scene._on_music_volume_changed(80.0)
			if not is_equal_approx(main_scene.settings_music_volume, 60.0) or not is_equal_approx(music_slider.value, 60.0):
				push_error("Music volume was allowed above the master volume cap.")
				quit(1)
				return false
		8:
			main_scene._apply_all_settings()
		10:
			main_scene._show_about_screen()
		12:
			main_scene._start_single_player()
		14:
			if main_scene.current_screen != "game":
				push_error("Single Player did not open the game screen.")
				quit(1)
				return false
			quit()
	return true


func _make_graphics_preset_select() -> OptionButton:
	var option := OptionButton.new()
	var values := ["low", "medium", "high", "ultra", "custom"]
	for i in range(values.size()):
		option.add_item(values[i])
		option.set_item_metadata(i, values[i])
	return option
