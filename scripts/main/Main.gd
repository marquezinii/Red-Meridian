extends Control

const MapCanvasScript = preload("res://scripts/ui/MapCanvas.gd")
const COUNTRY_DATA_PATH := "res://data/countries.json"
const EVENTS_DATA_PATH := "res://data/events.json"
const LOCALIZATION_DATA_PATH := "res://data/localization.json"
const MENU_BACKGROUND_PATH := "res://assets/backgrounds/main_menu_background.png"
const TITLE_FONT_PATH := "res://assets/fonts/Orbitron-Variable.ttf"
const BODY_FONT_PATH := "res://assets/fonts/Inter-Variable.ttf"

var countries: Array = []
var events: Array = []
var localization: Dictionary = {}
var current_screen := "menu"
var current_language := "en"
var title_font: Font
var body_font: Font
var selected_country_id := ""
var player_country_id := ""
var active_focuses: Dictionary = {}
var event_cooldowns: Dictionary = {}
var log_lines: Array[String] = []

var current_year := 2027
var current_month := 1
var current_day := 1
var elapsed_days := 0
var paused := true
var speed := 1
var sim_accumulator := 0.0
var global_tension := 18.0

var settings_window_mode := "borderless"
var settings_resolution := Vector2i(1920, 1080)
var settings_monitor := 0
var settings_vsync := true
var settings_frame_rate_cap := 144
var settings_ui_scale := 100
var settings_cursor_confined := true
var settings_pause_on_focus_loss := true
var settings_tutorial_hints := true
var settings_confirm_major_actions := true
var settings_autosave_interval := 10
var settings_measurement_system := "metric"
var settings_graphics_preset := "high"
var graphics_bool_settings := {
	"strategic_lighting": true,
	"map_effects": true,
	"unit_shadows": true,
	"post_processing": true,
	"water_reflections": false,
	"terrain_relief": true,
	"animated_markers": true,
	"bloom": false,
	"camera_tilt_effects": true,
	"political_map_shading": true
}
var graphics_choice_settings := {
	"map_texture_quality": "high",
	"anti_aliasing": "fxaa",
	"effects_density": "high",
	"shadow_quality": "high",
	"camera_quality": "standard"
}
var settings_audio_device := "Default"
var settings_master_volume := 100.0
var settings_music_volume := 70.0
var settings_effects_volume := 75.0
var settings_interface_volume := 80.0
var settings_mute_when_unfocused := false
var settings_menu_music := true
var settings_ui_feedback_sounds := true
var settings_dynamic_range := "wide"
var settings_active_tab := 0
var audio_sub_sliders: Dictionary = {}
var audio_sub_labels: Dictionary = {}

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
	_load_fonts()
	_load_localization()
	_load_countries()
	_load_events()
	_initialize_runtime_settings()
	if countries.is_empty():
		push_error("No countries were loaded from %s" % COUNTRY_DATA_PATH)
		return

	selected_country_id = String(countries[0].get("id", ""))
	player_country_id = selected_country_id
	_show_main_menu()
	set_process(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and settings_pause_on_focus_loss and current_screen == "game":
		paused = true
		_refresh_top_bar()


func _process(delta: float) -> void:
	if current_screen != "game":
		return
	if paused:
		return

	sim_accumulator += delta * float(speed)
	while sim_accumulator >= 0.65:
		sim_accumulator -= 0.65
		_advance_day()


func _load_countries() -> void:
	countries = _load_json_array(COUNTRY_DATA_PATH)


func _load_events() -> void:
	events = _load_json_array(EVENTS_DATA_PATH)


func _load_fonts() -> void:
	title_font = _load_dynamic_font(TITLE_FONT_PATH)
	body_font = _load_dynamic_font(BODY_FONT_PATH)


func _load_dynamic_font(path: String) -> Font:
	var font := FontFile.new()
	var error := font.load_dynamic_font(path)
	if error != OK:
		push_warning("Failed to load font: %s" % path)
		return null
	return font


func _initialize_runtime_settings() -> void:
	settings_monitor = DisplayServer.window_get_current_screen()
	settings_resolution = _current_screen_size()
	_apply_graphics_preset("high")
	_apply_audio_settings()


func _load_localization() -> void:
	var file := FileAccess.open(LOCALIZATION_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open %s" % LOCALIZATION_DATA_PATH)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		localization = parsed
	else:
		push_error("Invalid localization dictionary: %s" % LOCALIZATION_DATA_PATH)


func _load_json_array(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open %s" % path)
		return []

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_ARRAY:
		return parsed

	push_error("Invalid JSON array: %s" % path)
	return []


func _text(key: String, replacements: Dictionary = {}) -> String:
	var language_table: Dictionary = localization.get(current_language, {})
	var fallback_table: Dictionary = localization.get("en", {})
	var value := String(language_table.get(key, fallback_table.get(key, key)))
	for replacement_key in replacements.keys():
		value = value.replace("{%s}" % String(replacement_key), String(replacements[replacement_key]))
	return value


func _reset_scene() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _show_main_menu() -> void:
	current_screen = "menu"
	paused = true
	_reset_scene()

	var root := _build_menu_shell()
	var center := HBoxContainer.new()
	center.add_theme_constant_override("separation", 18)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)

	var menu_panel := _make_translucent_panel(360, 0)
	center.add_child(menu_panel)

	var menu_box := VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 10)
	menu_panel.add_child(menu_box)

	menu_box.add_child(_menu_title("RED MERIDIAN", _text("menu.subtitle")))
	menu_box.add_child(_menu_button(_text("menu.single_player"), _start_single_player))
	menu_box.add_child(_menu_button(_text("menu.multiplayer"), _show_multiplayer_notice))
	menu_box.add_child(_menu_button(_text("menu.settings"), _show_settings_screen))
	menu_box.add_child(_menu_button(_text("menu.about"), _show_about_screen))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 28)
	menu_box.add_child(spacer)
	menu_box.add_child(_menu_button(_text("menu.quit"), _quit_game))

	var updates_panel := _make_translucent_panel(430, 0)
	center.add_child(updates_panel)

	var updates_box := VBoxContainer.new()
	updates_box.add_theme_constant_override("separation", 10)
	updates_panel.add_child(updates_box)
	updates_box.add_child(_section_title(_text("menu.latest_updates")))
	updates_box.add_child(_muted_label("- %s" % _text("menu.update_1")))
	updates_box.add_child(_muted_label("- %s" % _text("menu.update_2")))
	updates_box.add_child(_muted_label("- %s" % _text("menu.update_3")))

	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(fill)

	root.add_child(_footer_label())


func _build_menu_shell() -> VBoxContainer:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_add_menu_background()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 78)
	root.add_child(top_spacer)

	return root


func _add_menu_background() -> void:
	var image := Image.new()
	var image_error := image.load(MENU_BACKGROUND_PATH)
	if image_error == OK:
		var texture := ImageTexture.create_from_image(image)
		var background := TextureRect.new()
		background.texture = texture
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		background.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(background)
	else:
		var fallback := ColorRect.new()
		fallback.color = Color.html("#06101E")
		fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(fallback)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.30)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)


func _menu_title(title_text: String, subtitle_text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color.html("#F2F6FF"))
	title.add_theme_color_override("font_outline_color", Color.html("#111927"))
	title.add_theme_constant_override("outline_size", 4)
	if title_font:
		title.add_theme_font_override("font", title_font)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.86, 0.91, 0.98, 0.72))
	if body_font:
		subtitle.add_theme_font_override("font", body_font)
	box.add_child(subtitle)

	return box


func _menu_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 42)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	if body_font:
		button.add_theme_font_override("font", body_font)
	button.add_theme_stylebox_override("normal", _style_box(Color(0.11, 0.14, 0.13, 0.88), Color(0.50, 0.57, 0.52, 0.70)))
	button.add_theme_stylebox_override("hover", _style_box(Color(0.18, 0.22, 0.20, 0.92), Color.html("#80CFA9")))
	button.add_theme_stylebox_override("pressed", _style_box(Color(0.08, 0.12, 0.13, 0.98), Color.html("#F4D35E")))
	button.add_theme_color_override("font_color", Color.html("#E8EEF8"))
	button.add_theme_color_override("font_hover_color", Color.html("#FFFFFF"))
	button.add_theme_color_override("font_pressed_color", Color.html("#F4D35E"))
	button.pressed.connect(callback)
	return button


func _footer_label() -> Label:
	var footer := Label.new()
	footer.text = "%s | Godot 4 | %s" % [_text("menu.version"), ProjectSettings.get_setting("application/config/name", "Red Meridian")]
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_theme_font_size_override("font_size", 13)
	footer.add_theme_color_override("font_color", Color(0.86, 0.91, 0.98, 0.62))
	if body_font:
		footer.add_theme_font_override("font", body_font)
	return footer


func _make_translucent_panel(width: int, height: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, height)
	panel.add_theme_stylebox_override("panel", _style_box(Color(0.03, 0.05, 0.07, 0.84), Color(0.38, 0.46, 0.52, 0.74)))
	return panel


func _start_single_player() -> void:
	current_screen = "game"
	_reset_scene()
	_build_layout()
	if log_lines.is_empty():
		_log(_text("log.ready"))
	_refresh_all()


func _show_multiplayer_notice() -> void:
	_show_message_screen(_text("menu.multiplayer"), _text("menu.multiplayer_status"))


func _show_message_screen(title_text: String, body_text: String) -> void:
	current_screen = "message"
	paused = true
	_reset_scene()
	var root := _build_menu_shell()
	var panel := _make_translucent_panel(620, 0)
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_section_title(title_text))
	box.add_child(_muted_label(body_text))
	box.add_child(_menu_button(_text("common.back"), _show_main_menu))
	root.add_child(_footer_label())


func _show_about_screen() -> void:
	current_screen = "about"
	paused = true
	_reset_scene()
	var root := _build_menu_shell()
	var panel := _make_translucent_panel(720, 0)
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_section_title(_text("about.title")))
	box.add_child(_muted_label(_text("about.body")))
	box.add_child(_section_title(_text("about.scope_title")))
	box.add_child(_muted_label(_text("about.scope_body")))
	box.add_child(_section_title(_text("menu.latest_updates")))
	box.add_child(_muted_label("- %s" % _text("menu.update_1")))
	box.add_child(_muted_label("- %s" % _text("menu.update_2")))
	box.add_child(_muted_label("- %s" % _text("menu.update_3")))
	box.add_child(_menu_button(_text("common.back"), _show_main_menu))
	root.add_child(_footer_label())


func _show_settings_screen(active_tab: int = -1) -> void:
	current_screen = "settings"
	paused = true
	if active_tab >= 0:
		settings_active_tab = active_tab
	_reset_scene()
	var root := _build_menu_shell()
	var panel := _make_translucent_panel(930, 0)
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_section_title(_text("settings.title")))

	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(0, 470)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tabs)

	tabs.add_child(_settings_general_tab())
	tabs.add_child(_settings_display_tab())
	tabs.add_child(_settings_graphics_tab())
	tabs.add_child(_settings_audio_tab())
	tabs.current_tab = clampi(settings_active_tab, 0, tabs.get_tab_count() - 1)
	tabs.tab_changed.connect(func(tab: int) -> void:
		settings_active_tab = tab
	)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)

	var apply_button := _menu_button(_text("common.apply"), _apply_all_settings)
	actions.add_child(apply_button)

	var back_button := _menu_button(_text("common.back"), _show_main_menu)
	actions.add_child(back_button)

	root.add_child(_footer_label())


func _settings_general_tab() -> Control:
	var box := _settings_tab(_text("settings.general"))
	box.add_child(_settings_label(_text("settings.language")))

	var language_select := _settings_option_button()
	language_select.add_item(_text("settings.language_en"))
	language_select.set_item_metadata(0, "en")
	language_select.add_item(_text("settings.language_pt"))
	language_select.set_item_metadata(1, "pt_BR")
	language_select.selected = 1 if current_language == "pt_BR" else 0
	language_select.item_selected.connect(_on_language_selected.bind(language_select))
	box.add_child(language_select)

	box.add_child(_settings_label(_text("settings.autosave_interval")))
	var autosave_select := _settings_option_button()
	var autosave_options := [
		[0, _text("settings.autosave_off")],
		[5, _text("settings.autosave_5")],
		[10, _text("settings.autosave_10")],
		[15, _text("settings.autosave_15")],
		[30, _text("settings.autosave_30")]
	]
	for i in range(autosave_options.size()):
		autosave_select.add_item(String(autosave_options[i][1]))
		autosave_select.set_item_metadata(i, int(autosave_options[i][0]))
	_select_option_by_metadata(autosave_select, settings_autosave_interval)
	autosave_select.item_selected.connect(_on_autosave_selected.bind(autosave_select))
	box.add_child(autosave_select)

	box.add_child(_settings_label(_text("settings.measurement_system")))
	var measurement_select := _settings_option_button()
	measurement_select.add_item(_text("settings.metric"))
	measurement_select.set_item_metadata(0, "metric")
	measurement_select.add_item(_text("settings.imperial"))
	measurement_select.set_item_metadata(1, "imperial")
	_select_option_by_metadata(measurement_select, settings_measurement_system)
	measurement_select.item_selected.connect(_on_measurement_selected.bind(measurement_select))
	box.add_child(measurement_select)

	box.add_child(_settings_checkbox(_text("settings.tutorial_hints"), settings_tutorial_hints, _on_tutorial_hints_toggled))
	box.add_child(_settings_checkbox(_text("settings.pause_on_focus_loss"), settings_pause_on_focus_loss, _on_pause_on_focus_loss_toggled))
	box.add_child(_settings_checkbox(_text("settings.confirm_major_actions"), settings_confirm_major_actions, _on_confirm_major_actions_toggled))

	return box


func _settings_display_tab() -> Control:
	var box := _settings_tab(_text("settings.display"))

	box.add_child(_settings_label(_text("settings.monitor")))
	var monitor_select := _settings_option_button()
	for screen in range(maxi(DisplayServer.get_screen_count(), 1)):
		var screen_size := DisplayServer.screen_get_size(screen)
		monitor_select.add_item(_text("settings.monitor_label", {
			"number": screen + 1,
			"width": screen_size.x,
			"height": screen_size.y
		}))
		monitor_select.set_item_metadata(screen, screen)
	_select_option_by_metadata(monitor_select, settings_monitor)
	monitor_select.item_selected.connect(_on_monitor_selected.bind(monitor_select))
	box.add_child(monitor_select)

	box.add_child(_settings_label(_text("settings.window_mode")))
	var mode_select := _settings_option_button()
	var modes := [
		["windowed", _text("settings.windowed")],
		["borderless", _text("settings.borderless")],
		["exclusive_fullscreen", _text("settings.exclusive_fullscreen")]
	]
	for i in range(modes.size()):
		mode_select.add_item(String(modes[i][1]))
		mode_select.set_item_metadata(i, String(modes[i][0]))
		if String(modes[i][0]) == settings_window_mode:
			mode_select.selected = i
	mode_select.item_selected.connect(_on_window_mode_selected.bind(mode_select))
	box.add_child(mode_select)

	box.add_child(_settings_label(_text("settings.resolution")))
	var resolution_select := _settings_option_button()
	var resolutions := _available_resolutions()
	for i in range(resolutions.size()):
		var resolution: Vector2i = resolutions[i]
		var label := "%d x %d" % [resolution.x, resolution.y]
		if resolution == _screen_size_for(settings_monitor):
			label = _text("settings.native_resolution", {"width": resolution.x, "height": resolution.y})
		resolution_select.add_item(label)
		resolution_select.set_item_metadata(i, resolution)
		if resolution == settings_resolution:
			resolution_select.selected = i
	resolution_select.item_selected.connect(_on_resolution_selected.bind(resolution_select))
	box.add_child(resolution_select)

	box.add_child(_settings_label(_text("settings.frame_rate_cap")))
	var fps_select := _settings_option_button()
	var fps_options := [0, 30, 60, 120, 144, 165, 240]
	for i in range(fps_options.size()):
		var fps := int(fps_options[i])
		fps_select.add_item(_text("settings.frame_rate_unlimited") if fps == 0 else "%d FPS" % fps)
		fps_select.set_item_metadata(i, fps)
	_select_option_by_metadata(fps_select, settings_frame_rate_cap)
	fps_select.item_selected.connect(_on_frame_rate_selected.bind(fps_select))
	box.add_child(fps_select)

	box.add_child(_settings_label(_text("settings.ui_scale")))
	var scale_select := _settings_option_button()
	var scales := [80, 90, 100, 110, 125, 150]
	for i in range(scales.size()):
		var scale := int(scales[i])
		scale_select.add_item("%d%%" % scale)
		scale_select.set_item_metadata(i, scale)
	_select_option_by_metadata(scale_select, settings_ui_scale)
	scale_select.item_selected.connect(_on_ui_scale_selected.bind(scale_select))
	box.add_child(scale_select)

	box.add_child(_settings_checkbox(_text("settings.vsync"), settings_vsync, _on_vsync_toggled))
	box.add_child(_settings_checkbox(_text("settings.cursor_confined"), settings_cursor_confined, _on_cursor_confined_toggled))

	return box


func _settings_graphics_tab() -> Control:
	var box := _settings_tab(_text("settings.graphics"))

	box.add_child(_settings_label(_text("settings.graphics_preset")))
	var preset_select := _settings_option_button()
	var presets := [
		["low", _text("settings.low")],
		["medium", _text("settings.medium")],
		["high", _text("settings.high")],
		["ultra", _text("settings.ultra")],
		["custom", _text("settings.custom")]
	]
	for i in range(presets.size()):
		preset_select.add_item(String(presets[i][1]))
		preset_select.set_item_metadata(i, String(presets[i][0]))
		if String(presets[i][0]) == settings_graphics_preset:
			preset_select.selected = i
	preset_select.item_selected.connect(_on_graphics_preset_selected.bind(preset_select))
	box.add_child(preset_select)

	box.add_child(_graphics_choice("map_texture_quality", _text("settings.map_texture_quality"), [
		["low", _text("settings.low")],
		["medium", _text("settings.medium")],
		["high", _text("settings.high")],
		["ultra", _text("settings.ultra")]
	], preset_select))
	box.add_child(_graphics_choice("anti_aliasing", _text("settings.anti_aliasing"), [
		["off", _text("settings.off")],
		["fxaa", "FXAA"],
		["taa", "TAA"]
	], preset_select))
	box.add_child(_graphics_choice("effects_density", _text("settings.effects_density"), [
		["low", _text("settings.low")],
		["medium", _text("settings.medium")],
		["high", _text("settings.high")],
		["ultra", _text("settings.ultra")]
	], preset_select))
	box.add_child(_graphics_choice("shadow_quality", _text("settings.shadow_quality"), [
		["off", _text("settings.off")],
		["low", _text("settings.low")],
		["medium", _text("settings.medium")],
		["high", _text("settings.high")]
	], preset_select))
	box.add_child(_graphics_choice("camera_quality", _text("settings.camera_quality"), [
		["flat", _text("settings.camera_flat")],
		["standard", _text("settings.camera_standard")],
		["cinematic", _text("settings.camera_cinematic")]
	], preset_select))

	box.add_child(_graphics_check("strategic_lighting", _text("settings.strategic_lighting"), preset_select))
	box.add_child(_graphics_check("map_effects", _text("settings.map_effects"), preset_select))
	box.add_child(_graphics_check("unit_shadows", _text("settings.unit_shadows"), preset_select))
	box.add_child(_graphics_check("post_processing", _text("settings.post_processing"), preset_select))
	box.add_child(_graphics_check("water_reflections", _text("settings.water_reflections"), preset_select))
	box.add_child(_graphics_check("terrain_relief", _text("settings.terrain_relief"), preset_select))
	box.add_child(_graphics_check("animated_markers", _text("settings.animated_markers"), preset_select))
	box.add_child(_graphics_check("bloom", _text("settings.bloom"), preset_select))
	box.add_child(_graphics_check("camera_tilt_effects", _text("settings.camera_tilt_effects"), preset_select))
	box.add_child(_graphics_check("political_map_shading", _text("settings.political_map_shading"), preset_select))

	return box


func _settings_audio_tab() -> Control:
	var box := _settings_tab(_text("settings.audio"))
	audio_sub_sliders.clear()
	audio_sub_labels.clear()

	box.add_child(_settings_label(_text("settings.output_device")))
	var device_select := _settings_option_button()
	var devices := AudioServer.get_output_device_list()
	if devices.is_empty():
		devices = PackedStringArray(["Default"])
	for i in range(devices.size()):
		var device := String(devices[i])
		device_select.add_item(device)
		device_select.set_item_metadata(i, device)
		if device == settings_audio_device:
			device_select.selected = i
	device_select.item_selected.connect(_on_audio_device_selected.bind(device_select))
	box.add_child(device_select)

	box.add_child(_volume_slider("master", _text("settings.master_volume"), settings_master_volume, _on_master_volume_changed, 100.0))
	box.add_child(_volume_slider("music", _text("settings.music_volume"), settings_music_volume, _on_music_volume_changed, settings_master_volume))
	box.add_child(_volume_slider("effects", _text("settings.effects_volume"), settings_effects_volume, _on_effects_volume_changed, settings_master_volume))
	box.add_child(_volume_slider("interface", _text("settings.interface_volume"), settings_interface_volume, _on_interface_volume_changed, settings_master_volume))

	box.add_child(_settings_label(_text("settings.dynamic_range")))
	var dynamic_range_select := _settings_option_button()
	var ranges := [
		["night", _text("settings.dynamic_range_night")],
		["headphones", _text("settings.dynamic_range_headphones")],
		["wide", _text("settings.dynamic_range_wide")]
	]
	for i in range(ranges.size()):
		dynamic_range_select.add_item(String(ranges[i][1]))
		dynamic_range_select.set_item_metadata(i, String(ranges[i][0]))
	_select_option_by_metadata(dynamic_range_select, settings_dynamic_range)
	dynamic_range_select.item_selected.connect(_on_dynamic_range_selected.bind(dynamic_range_select))
	box.add_child(dynamic_range_select)

	box.add_child(_settings_checkbox(_text("settings.mute_when_unfocused"), settings_mute_when_unfocused, _on_mute_when_unfocused_toggled))
	box.add_child(_settings_checkbox(_text("settings.menu_music"), settings_menu_music, _on_menu_music_toggled))
	box.add_child(_settings_checkbox(_text("settings.ui_feedback_sounds"), settings_ui_feedback_sounds, _on_ui_feedback_sounds_toggled))

	return box


func _settings_tab(tab_name: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = tab_name
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return box


func _settings_label(text: String) -> Label:
	var label := _muted_label(text)
	label.add_theme_color_override("font_color", Color(0.86, 0.91, 0.98, 0.82))
	return label


func _settings_option_button() -> OptionButton:
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(0, 36)
	option.add_theme_font_size_override("font_size", 14)
	if body_font:
		option.add_theme_font_override("font", body_font)
	option.add_theme_stylebox_override("normal", _style_box(Color(0.06, 0.09, 0.12, 0.90), Color(0.31, 0.39, 0.48, 0.80)))
	option.add_theme_stylebox_override("hover", _style_box(Color(0.10, 0.14, 0.18, 0.94), Color.html("#80CFA9")))
	option.add_theme_stylebox_override("pressed", _style_box(Color(0.07, 0.11, 0.14, 0.98), Color.html("#F4D35E")))
	return option


func _settings_checkbox(text: String, value: bool, callback: Callable = Callable()) -> CheckBox:
	var check := CheckBox.new()
	check.text = text
	check.button_pressed = value
	check.add_theme_font_size_override("font_size", 14)
	if body_font:
		check.add_theme_font_override("font", body_font)
	check.add_theme_color_override("font_color", Color.html("#DCE6F4"))
	if callback.is_valid():
		check.toggled.connect(callback)
	return check


func _select_option_by_metadata(option: OptionButton, value: Variant) -> void:
	for i in range(option.get_item_count()):
		if option.get_item_metadata(i) == value:
			option.selected = i
			return


func _graphics_choice(setting_id: String, label_text: String, choices: Array, preset_select: OptionButton) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.add_child(_settings_label(label_text))

	var option := _settings_option_button()
	for i in range(choices.size()):
		option.add_item(String(choices[i][1]))
		option.set_item_metadata(i, String(choices[i][0]))
	_select_option_by_metadata(option, String(graphics_choice_settings.get(setting_id, "")))
	option.item_selected.connect(_on_graphics_choice_selected.bind(setting_id, option, preset_select))
	box.add_child(option)
	return box


func _graphics_check(setting_id: String, text: String, preset_select: OptionButton) -> CheckBox:
	var check := _settings_checkbox(text, bool(graphics_bool_settings.get(setting_id, false)))
	check.toggled.connect(_on_graphics_bool_changed.bind(setting_id, preset_select))
	return check


func _volume_slider(setting_id: String, label_text: String, value: float, callback: Callable, max_value: float) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var label := _settings_label("%s: %.0f%%" % [label_text, value])
	box.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = max_value
	slider.step = 1
	slider.value = clampf(value, 0.0, max_value)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	slider.value_changed.connect(func(new_value: float) -> void:
		label.text = "%s: %.0f%%" % [label_text, new_value]
	)
	box.add_child(slider)
	if setting_id != "master":
		audio_sub_sliders[setting_id] = slider
		audio_sub_labels[setting_id] = {
			"label": label,
			"text": label_text
		}
	return box


func _on_language_selected(index: int, select: OptionButton) -> void:
	current_language = String(select.get_item_metadata(index))
	_show_settings_screen(0)


func _on_autosave_selected(index: int, select: OptionButton) -> void:
	settings_autosave_interval = int(select.get_item_metadata(index))


func _on_measurement_selected(index: int, select: OptionButton) -> void:
	settings_measurement_system = String(select.get_item_metadata(index))


func _on_tutorial_hints_toggled(value: bool) -> void:
	settings_tutorial_hints = value


func _on_pause_on_focus_loss_toggled(value: bool) -> void:
	settings_pause_on_focus_loss = value


func _on_confirm_major_actions_toggled(value: bool) -> void:
	settings_confirm_major_actions = value


func _on_monitor_selected(index: int, select: OptionButton) -> void:
	settings_monitor = int(select.get_item_metadata(index))
	settings_resolution = _screen_size_for(settings_monitor)
	_show_settings_screen(1)


func _on_window_mode_selected(index: int, select: OptionButton) -> void:
	settings_window_mode = String(select.get_item_metadata(index))
	if settings_window_mode != "windowed":
		settings_resolution = _screen_size_for(settings_monitor)
	_show_settings_screen(1)


func _on_resolution_selected(index: int, select: OptionButton) -> void:
	settings_resolution = select.get_item_metadata(index)


func _on_frame_rate_selected(index: int, select: OptionButton) -> void:
	settings_frame_rate_cap = int(select.get_item_metadata(index))


func _on_ui_scale_selected(index: int, select: OptionButton) -> void:
	settings_ui_scale = int(select.get_item_metadata(index))


func _on_vsync_toggled(value: bool) -> void:
	settings_vsync = value


func _on_cursor_confined_toggled(value: bool) -> void:
	settings_cursor_confined = value


func _on_graphics_preset_selected(index: int, select: OptionButton) -> void:
	settings_graphics_preset = String(select.get_item_metadata(index))
	_apply_graphics_preset(settings_graphics_preset)
	_show_settings_screen(2)


func _on_graphics_bool_changed(value: bool, setting_id: String, preset_select: OptionButton) -> void:
	graphics_bool_settings[setting_id] = value
	_mark_graphics_custom(preset_select)


func _on_graphics_choice_selected(index: int, setting_id: String, select: OptionButton, preset_select: OptionButton) -> void:
	graphics_choice_settings[setting_id] = String(select.get_item_metadata(index))
	_mark_graphics_custom(preset_select)


func _on_audio_device_selected(index: int, select: OptionButton) -> void:
	settings_audio_device = String(select.get_item_metadata(index))


func _on_master_volume_changed(value: float) -> void:
	settings_master_volume = value
	_clamp_audio_to_master()
	_refresh_audio_slider_limits()
	_apply_audio_settings()


func _on_music_volume_changed(value: float) -> void:
	settings_music_volume = minf(value, settings_master_volume)
	_apply_audio_settings()


func _on_effects_volume_changed(value: float) -> void:
	settings_effects_volume = minf(value, settings_master_volume)
	_apply_audio_settings()


func _on_interface_volume_changed(value: float) -> void:
	settings_interface_volume = minf(value, settings_master_volume)
	_apply_audio_settings()


func _on_dynamic_range_selected(index: int, select: OptionButton) -> void:
	settings_dynamic_range = String(select.get_item_metadata(index))


func _on_mute_when_unfocused_toggled(value: bool) -> void:
	settings_mute_when_unfocused = value


func _on_menu_music_toggled(value: bool) -> void:
	settings_menu_music = value


func _on_ui_feedback_sounds_toggled(value: bool) -> void:
	settings_ui_feedback_sounds = value


func _apply_all_settings() -> void:
	_apply_display_settings()
	_apply_audio_settings()
	_show_message_screen(_text("settings.title"), _text("settings.applied"))


func _apply_display_settings() -> void:
	settings_monitor = clampi(settings_monitor, 0, maxi(DisplayServer.get_screen_count() - 1, 0))
	DisplayServer.window_set_current_screen(settings_monitor)
	match settings_window_mode:
		"windowed":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(settings_resolution)
		"borderless":
			settings_resolution = _screen_size_for(settings_monitor)
			DisplayServer.window_set_size(settings_resolution)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"exclusive_fullscreen":
			settings_resolution = _screen_size_for(settings_monitor)
			DisplayServer.window_set_size(settings_resolution)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings_vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = settings_frame_rate_cap
	get_window().content_scale_factor = float(settings_ui_scale) / 100.0
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED if settings_cursor_confined and settings_window_mode != "windowed" else Input.MOUSE_MODE_VISIBLE


func _apply_audio_settings() -> void:
	_clamp_audio_to_master()
	if settings_audio_device != "":
		AudioServer.output_device = settings_audio_device
	_set_bus_volume("Master", settings_master_volume)
	_set_child_bus_volume("Music", settings_music_volume)
	_set_child_bus_volume("Effects", settings_effects_volume)
	_set_child_bus_volume("Interface", settings_interface_volume)


func _set_child_bus_volume(bus_name: String, absolute_value: float) -> void:
	if settings_master_volume <= 0.0:
		_set_bus_volume(bus_name, 0.0)
		return
	var relative_value := clampf((absolute_value / settings_master_volume) * 100.0, 0.0, 100.0)
	_set_bus_volume(bus_name, relative_value)


func _set_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, bus_name)
	var linear_value := clampf(value / 100.0, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_value) if linear_value > 0.0 else -80.0)


func _current_screen_size() -> Vector2i:
	return _screen_size_for(DisplayServer.window_get_current_screen())


func _screen_size_for(screen: int) -> Vector2i:
	var screen_count := maxi(DisplayServer.get_screen_count(), 1)
	var safe_screen := clampi(screen, 0, screen_count - 1)
	var size := DisplayServer.screen_get_size(safe_screen)
	if size.x <= 0 or size.y <= 0:
		return Vector2i(1920, 1080)
	return size


func _available_resolutions() -> Array[Vector2i]:
	var native := _screen_size_for(settings_monitor)
	var resolutions: Array[Vector2i] = [
		Vector2i(1280, 720),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
		Vector2i(3200, 1800),
		Vector2i(3840, 2160)
	]
	if not resolutions.has(native):
		resolutions.append(native)
	return resolutions


func _apply_graphics_preset(preset: String) -> void:
	if preset == "custom":
		return

	var bool_presets := {
		"low": {
			"strategic_lighting": false,
			"map_effects": false,
			"unit_shadows": false,
			"post_processing": false,
			"water_reflections": false,
			"terrain_relief": false,
			"animated_markers": false,
			"bloom": false,
			"camera_tilt_effects": false,
			"political_map_shading": true
		},
		"medium": {
			"strategic_lighting": true,
			"map_effects": true,
			"unit_shadows": false,
			"post_processing": true,
			"water_reflections": false,
			"terrain_relief": true,
			"animated_markers": true,
			"bloom": false,
			"camera_tilt_effects": false,
			"political_map_shading": true
		},
		"high": {
			"strategic_lighting": true,
			"map_effects": true,
			"unit_shadows": true,
			"post_processing": true,
			"water_reflections": false,
			"terrain_relief": true,
			"animated_markers": true,
			"bloom": false,
			"camera_tilt_effects": true,
			"political_map_shading": true
		},
		"ultra": {
			"strategic_lighting": true,
			"map_effects": true,
			"unit_shadows": true,
			"post_processing": true,
			"water_reflections": true,
			"terrain_relief": true,
			"animated_markers": true,
			"bloom": true,
			"camera_tilt_effects": true,
			"political_map_shading": true
		}
	}
	var choice_presets := {
		"low": {
			"map_texture_quality": "low",
			"anti_aliasing": "off",
			"effects_density": "low",
			"shadow_quality": "off",
			"camera_quality": "flat"
		},
		"medium": {
			"map_texture_quality": "medium",
			"anti_aliasing": "fxaa",
			"effects_density": "medium",
			"shadow_quality": "low",
			"camera_quality": "standard"
		},
		"high": {
			"map_texture_quality": "high",
			"anti_aliasing": "fxaa",
			"effects_density": "high",
			"shadow_quality": "high",
			"camera_quality": "standard"
		},
		"ultra": {
			"map_texture_quality": "ultra",
			"anti_aliasing": "taa",
			"effects_density": "ultra",
			"shadow_quality": "high",
			"camera_quality": "cinematic"
		}
	}

	for key in bool_presets[preset].keys():
		graphics_bool_settings[key] = bool(bool_presets[preset][key])
	for key in choice_presets[preset].keys():
		graphics_choice_settings[key] = String(choice_presets[preset][key])


func _mark_graphics_custom(preset_select: OptionButton) -> void:
	settings_graphics_preset = "custom"
	_select_option_by_metadata(preset_select, "custom")


func _clamp_audio_to_master() -> void:
	settings_music_volume = minf(settings_music_volume, settings_master_volume)
	settings_effects_volume = minf(settings_effects_volume, settings_master_volume)
	settings_interface_volume = minf(settings_interface_volume, settings_master_volume)


func _refresh_audio_slider_limits() -> void:
	var values := {
		"music": settings_music_volume,
		"effects": settings_effects_volume,
		"interface": settings_interface_volume
	}
	for key in audio_sub_sliders.keys():
		var slider: HSlider = audio_sub_sliders[key]
		slider.max_value = settings_master_volume
		slider.value = clampf(float(values.get(key, 0.0)), 0.0, settings_master_volume)
		var label_data: Dictionary = audio_sub_labels.get(key, {})
		var label: Label = label_data.get("label")
		if label:
			label.text = "%s: %.0f%%" % [String(label_data.get("text", "")), slider.value]


func _quit_game() -> void:
	get_tree().quit()


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
	if title_font:
		title.add_theme_font_override("font", title_font)
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = _text("game.subtitle")
	subtitle.add_theme_color_override("font_color", Color(0.86, 0.91, 0.98, 0.62))
	if body_font:
		subtitle.add_theme_font_override("font", body_font)
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
	day_button.text = _text("game.one_day")
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
	status_label.text = _text("game.paused") if paused else _text("game.running", {"speed": speed})
	pause_button.text = _text("game.resume") if paused else _text("game.pause")
	tension_bar.value = global_tension


func _refresh_map() -> void:
	map_canvas.set_countries(countries)
	map_canvas.set_selected_country(selected_country_id)
	map_canvas.set_player_country(player_country_id)
	map_canvas.set_global_tension(global_tension)
	map_canvas.set_labels(
		_text("game.global_tension", {"value": "%.0f%%"}),
		_text("game.map_hint"),
		_text("game.stability"),
		_text("game.readiness")
	)


func _refresh_country_panel() -> void:
	_clear_children(country_panel)
	var country := _selected_country()
	if country.is_empty():
		return

	country_panel.add_child(_section_title(String(country.get("name", "Country"))))
	country_panel.add_child(_muted_label("%s | %s | Capital: %s" % [
		String(country.get("region", "")),
		String(country.get("bloc", "")),
		String(country.get("capital", ""))
	]))
	country_panel.add_child(_muted_label("%s: %s" % [_text("game.leader"), String(country.get("leader", _text("game.pending")))]))
	country_panel.add_child(_muted_label("%s: %s" % [
		_text("game.player_country"),
		_text("game.yes") if String(country.get("id", "")) == player_country_id else _text("game.no")
	]))

	var stats: Dictionary = country.get("stats", {})
	country_panel.add_child(_stat_row("GDP", "$%.2fT" % (float(stats.get("gdp", 0.0)) / 1000.0)))
	country_panel.add_child(_progress_row(_text("game.stability"), float(stats.get("stability", 0.0)), Color.html("#79D0FF")))
	country_panel.add_child(_progress_row(_text("game.military_power"), float(stats.get("military", 0.0)), Color.html("#D95F5F")))
	country_panel.add_child(_progress_row(_text("game.readiness"), float(stats.get("readiness", 0.0)), Color.html("#F4D35E")))
	country_panel.add_child(_progress_row(_text("game.diplomacy"), float(stats.get("diplomacy", 0.0)), Color.html("#80CFA9")))
	country_panel.add_child(_progress_row(_text("game.local_tension"), float(stats.get("tension", 0.0)), Color.html("#D18CE0")))

	country_panel.add_child(_section_title(_text("game.government_actions")))
	country_panel.add_child(_decision_button(_text("game.set_player"), "set_player"))
	country_panel.add_child(_decision_button(_text("game.economic_package"), "economy"))
	country_panel.add_child(_decision_button(_text("game.defense_investment"), "defense"))
	country_panel.add_child(_decision_button(_text("game.diplomatic_pressure"), "pressure"))
	country_panel.add_child(_decision_button(_text("game.deescalate"), "deescalate"))


func _refresh_focus_panel() -> void:
	_clear_children(focus_panel)
	var country := _selected_country()
	if country.is_empty():
		return

	focus_panel.add_child(_section_title(_text("game.national_focus")))
	focus_panel.add_child(_muted_label(_text("game.focus_help")))

	var country_id := String(country.get("id", ""))
	if active_focuses.has(country_id):
		var active: Dictionary = active_focuses[country_id]
		var focus: Dictionary = active.get("focus", {})
		focus_panel.add_child(_status_card(
			_text("game.active_focus"),
			"%s\n%s" % [
				String(focus.get("title", "")),
				_text("game.days_remaining", {"days": int(active.get("remaining", 0))})
			]
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
		_log(_text("log.selected_country", {"country": String(country.get("name", country_id))}))
	_refresh_all()


func _toggle_pause() -> void:
	paused = not paused
	_refresh_top_bar()


func _set_speed(value: int) -> void:
	speed = value
	paused = false
	_log(_text("log.speed", {"speed": speed}))
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
	_process_strategic_events()


func _process_strategic_events() -> void:
	if events.is_empty() or elapsed_days % 14 != 0:
		return

	var eligible: Array = []
	for event in events:
		var event_id := String(event.get("id", ""))
		var min_tension := float(event.get("min_global_tension", 0.0))
		var max_tension := float(event.get("max_global_tension", 100.0))
		var cooldown_days := int(event.get("cooldown_days", 42))
		var last_triggered := int(event_cooldowns.get(event_id, -99999))
		var off_cooldown := elapsed_days - last_triggered >= cooldown_days
		if global_tension >= min_tension and global_tension <= max_tension and off_cooldown:
			eligible.append(event)

	if eligible.is_empty():
		return

	var index := int((elapsed_days / 14) + countries.size()) % eligible.size()
	var selected_event: Dictionary = eligible[index]
	_apply_strategic_event(selected_event)


func _apply_strategic_event(event: Dictionary) -> void:
	var event_id := String(event.get("id", ""))
	event_cooldowns[event_id] = elapsed_days

	var effects: Dictionary = event.get("effects", {})
	if effects.has("global_tension"):
		global_tension = clampf(global_tension + float(effects.get("global_tension", 0.0)), 0.0, 100.0)

	var country_effects: Dictionary = event.get("country_effects", {})
	for country_id in country_effects.keys():
		var country := _country_by_id(String(country_id))
		if country.is_empty():
			continue
		var stats: Dictionary = country.get("stats", {})
		var stat_effects: Dictionary = country_effects[country_id]
		for stat_key in stat_effects.keys():
			if stats.has(stat_key):
				stats[stat_key] = float(stats.get(stat_key, 0.0)) + float(stat_effects[stat_key])
		_clamp_stats(stats)
		country["stats"] = stats

	_log(_text("log.event", {
		"title": String(event.get("title", "Untitled event")),
		"description": String(event.get("description", ""))
	}))


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
		_log(_text("log.focus_completed", {
			"focus": String(focus.get("title", "")),
			"country": country_id
		}))


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
		_log(_text("log.focus_active"))
		return

	active_focuses[country_id] = {
		"focus": focus,
		"remaining": int(focus.get("duration_days", 30))
	}
	_log(_text("log.focus_started", {
		"focus": String(focus.get("title", "")),
		"country": country_id
	}))
	_refresh_all()


func _run_decision(decision_id: String) -> void:
	var country := _selected_country()
	if country.is_empty():
		return

	var stats: Dictionary = country.get("stats", {})
	var country_name := String(country.get("name", "Country"))

	match decision_id:
		"set_player":
			player_country_id = String(country.get("id", ""))
			_log(_text("log.player_country", {"country": country_name}))
		"economy":
			stats["gdp"] = float(stats.get("gdp", 0.0)) + 25.0
			stats["stability"] = float(stats.get("stability", 0.0)) + 1.0
			_log(_text("log.economy", {"country": country_name}))
		"defense":
			stats["military"] = float(stats.get("military", 0.0)) + 1.5
			stats["readiness"] = float(stats.get("readiness", 0.0)) + 2.0
			stats["stability"] = float(stats.get("stability", 0.0)) - 0.5
			global_tension = clampf(global_tension + 0.6, 0.0, 100.0)
			_log(_text("log.defense", {"country": country_name}))
		"pressure":
			stats["diplomacy"] = float(stats.get("diplomacy", 0.0)) + 1.0
			stats["tension"] = float(stats.get("tension", 0.0)) + 2.0
			global_tension = clampf(global_tension + 0.8, 0.0, 100.0)
			_log(_text("log.pressure", {"country": country_name}))
		"deescalate":
			stats["diplomacy"] = float(stats.get("diplomacy", 0.0)) + 1.5
			stats["tension"] = float(stats.get("tension", 0.0)) - 2.5
			global_tension = clampf(global_tension - 0.5, 0.0, 100.0)
			_log(_text("log.deescalate", {"country": country_name}))

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
	if body_font:
		label.add_theme_font_override("font", body_font)
	return label


func _muted_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.86, 0.91, 0.98, 0.66))
	if body_font:
		label.add_theme_font_override("font", body_font)
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
	if body_font:
		right.add_theme_font_override("font", body_font)
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
	if body_font:
		value_label.add_theme_font_override("font", body_font)
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
	button.add_theme_font_size_override("font_size", 14)
	if body_font:
		button.add_theme_font_override("font", body_font)
	button.pressed.connect(_run_decision.bind(decision_id))
	return button


func _focus_card(country_id: String, focus: Dictionary) -> Control:
	var panel := _make_panel()
	panel.add_theme_stylebox_override("panel", _style_box(Color.html("#101C2E"), Color.html("#263C58")))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)

	box.add_child(_section_title(String(focus.get("title", _text("game.focus")))))
	box.add_child(_muted_label(String(focus.get("description", ""))))
	box.add_child(_muted_label(_text("game.duration_days", {"days": int(focus.get("duration_days", 30))})))
	box.add_child(_muted_label(_text("game.effects", {"effects": _format_effects(focus.get("effects", {}))})))

	var button := Button.new()
	button.text = _text("game.start_focus")
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
