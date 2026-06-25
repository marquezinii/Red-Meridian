extends SceneTree

var main_scene


func _initialize() -> void:
	var packed_scene := load("res://scenes/main/Main.tscn")
	if packed_scene == null:
		push_error("Failed to load main scene.")
		quit(1)
		return

	main_scene = packed_scene.instantiate()
	root.add_child(main_scene)
	await process_frame
	await process_frame

	main_scene._show_settings_screen()
	await process_frame

	main_scene._show_settings_screen(2)
	var preset_select := _make_graphics_preset_select()
	main_scene._on_graphics_preset_selected(3, preset_select)
	if main_scene.settings_active_tab != 2:
		_fail("Graphics preset change did not preserve the Graphics tab.")
		return
	main_scene._on_graphics_bool_changed(false, "water_reflections", preset_select)
	if main_scene.settings_graphics_preset != "custom":
		_fail("Manual graphics changes did not switch the preset to Custom.")
		return

	main_scene._show_settings_screen(1)
	await process_frame
	var blank_option := _find_blank_selected_option(main_scene)
	if blank_option != "":
		_fail("Settings option has an empty selected label: %s" % blank_option)
		return
	var blank_stepper := _find_blank_stepper_label(main_scene)
	if blank_stepper != "":
		_fail("Settings stepper has an empty selected label: %s" % blank_stepper)
		return
	main_scene.settings_window_mode = "borderless"
	main_scene.settings_resolution = Vector2i(1920, 1080)
	main_scene._apply_all_settings()
	if main_scene.current_screen != "settings":
		_fail("Apply opened a message screen instead of staying in settings.")
		return
	if main_scene.settings_resolution != Vector2i(1920, 1080):
		_fail("Borderless apply overwrote the selected resolution setting.")
		return

	main_scene._show_settings_screen(3)
	main_scene.settings_master_volume = 100.0
	main_scene.settings_music_volume = 90.0
	main_scene.settings_effects_volume = 85.0
	main_scene.settings_interface_volume = 80.0
	main_scene._on_master_volume_changed(60.0)
	if main_scene.settings_music_volume > 60.0 or main_scene.settings_effects_volume > 60.0 or main_scene.settings_interface_volume > 60.0:
		_fail("Master volume did not clamp sub-volume settings.")
		return
	var music_slider: HSlider = main_scene.audio_sub_sliders.get("music")
	if music_slider == null or music_slider.max_value != 100.0 or not is_equal_approx(music_slider.value, 60.0):
		_fail("Music slider did not stay on a 0-100 scale while matching the master cap.")
		return
	main_scene._on_music_volume_changed(80.0)
	if not is_equal_approx(main_scene.settings_music_volume, 60.0) or not is_equal_approx(music_slider.value, 60.0):
		_fail("Music volume was allowed above the master volume cap.")
		return

	main_scene._apply_all_settings()
	main_scene._show_about_screen()
	main_scene._start_single_player()
	if main_scene.current_screen != "game":
		_fail("Single Player did not open the game screen.")
		return
	quit()


func _make_graphics_preset_select() -> OptionButton:
	var option := OptionButton.new()
	var values := ["low", "medium", "high", "ultra", "custom"]
	for i in range(values.size()):
		option.add_item(values[i])
		option.set_item_metadata(i, values[i])
	return option


func _find_blank_selected_option(node: Node) -> String:
	if node is OptionButton:
		var option := node as OptionButton
		var selected_index: int = option.selected
		if selected_index < 0 or selected_index >= option.get_item_count():
			return option.name
		if option.get_item_text(selected_index).strip_edges().is_empty():
			return option.name
	for child in node.get_children():
		var result := _find_blank_selected_option(child)
		if result != "":
			return result
	return ""


func _find_blank_stepper_label(node: Node) -> String:
	if node is PanelContainer and node.get_child_count() == 1:
		var child := node.get_child(0)
		if child is Label:
			var label := child as Label
			if label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and label.text.strip_edges().is_empty():
				return node.name
	for child in node.get_children():
		var result := _find_blank_stepper_label(child)
		if result != "":
			return result
	return ""


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
