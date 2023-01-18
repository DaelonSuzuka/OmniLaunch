tool
extends EditorPlugin

# ******************************************************************************

var pids := []
var settings_dialog = null

# ******************************************************************************

var default_window = {
	'name': 'main',
	'main': true,
	'args': '',
	'number': 1,
	'width': 0,
	'height': 0,
}

var default_profile = {
	'layout': '',
	'windows': [
		{
			'name': 'main',
			'main': true,
			'args': '',
			'number': 1,
			'width': 0,
			'height': 0,
		},
		{
			'name': 'other',
			'main': false,
			'args': '',
			'number': 1,
			'width': 0,
			'height': 0,
		}
	]
}

var default_settings = {
	'current_profile': 'default',
	'profiles': {
		'default': default_profile.duplicate(true),
	}
}

# ******************************************************************************

var settings = null
var current_profile = ''
var editor_toolbar = null
var layout_templates = null
var profiles = null

func _enter_tree():
	settings_dialog = load('res://addons/omnilaunch/OmnilaunchSettings.tscn').instance()
	settings_dialog.plugin = self
	
	layout_templates = load('res://addons/omnilaunch/LayoutTemplates.tscn').instance()
	var base = get_editor_interface().get_base_control()
	base.add_child(layout_templates)

	add_child(settings_dialog)
	settings_dialog.connect('confirmed', self, 'settings_confirmed')

	editor_toolbar = load('res://addons/omnilaunch/EditorToolbar.tscn').instance()

	profiles = editor_toolbar.get_node('%Profiles')
	profiles.connect('item_selected', self, 'profile_selected')

	var settings_btn = editor_toolbar.get_node('%Settings')
	settings_btn.connect('pressed', self, 'settings_pressed')

	var stop_btn = editor_toolbar.get_node('%Stop')
	stop_btn.connect('pressed', self, 'stop_pressed')

	var run_btn = editor_toolbar.get_node('%Run')
	run_btn.connect('pressed', self, 'run_pressed')
	
	load_settings()
	
	reload_profile_list()

	add_control_to_container(CONTAINER_TOOLBAR, editor_toolbar)

func _exit_tree():
	if editor_toolbar:
		remove_control_from_container(CONTAINER_TOOLBAR, editor_toolbar)
		editor_toolbar.free()
		editor_toolbar = null
	kill_pids()

# ******************************************************************************

func reload_profile_list():
	profiles.clear()
	var idx = 0
	var i = 0
	for p in settings.profiles:
		if p == settings.current_profile:
			idx = i
		i += 1
		profiles.add_item(p)
	profiles.select(idx)

func profile_selected(index):
	settings.current_profile = profiles.get_item_text(index)
	save_settings()

func settings_pressed():
	settings_dialog.set_data(settings)
	settings_dialog.popup_centered(Vector2(800, 600))

func run_pressed():
	var profile_name = profiles.get_item_text(profiles.selected)
	var profile = settings.profiles[profile_name]
	launch(profile)

func stop_pressed():
	get_editor_interface().stop_playing_scene()
	kill_pids()

func settings_confirmed():
	settings = settings_dialog.get_data()
	save_settings()
	reload_profile_list()

# ******************************************************************************

func load_settings():
	settings = load_json('res://omnilaunch_settings.json', default_settings)

func save_settings():
	save_json('res://omnilaunch_settings.json', settings)

# ******************************************************************************

func launch(profile):
	var total_windows = 0
	var main_window = {}
	var windows = []
	for w in profile.windows:
		if w.main:
			main_window = w.duplicate(true)
			total_windows += 1
			continue
		
		for i in w.number:
			windows.append(w.duplicate(true))
			total_windows += 1

	var window_positions = []

	var template = null
	if total_windows <= 2:
		template = layout_templates.get_node('TwoH')
	elif total_windows <= 4:
		template = layout_templates.get_node('Four')
	elif total_windows <= 6:
		template = layout_templates.get_node('Six')
	else:
		template = layout_templates.get_node('Nine')

	for slot in template.get_children():
		window_positions.append(slot.rect_position + (slot.rect_size / 2))

	var c = 0

	var x = ProjectSettings.get_setting('display/window/size/test_width')
	var y = ProjectSettings.get_setting('display/window/size/test_height')
	var default_window_size = Vector2(x, y)

	if main_window:
		var args = ''
		var pos = window_positions[c]
		var window_size = default_window_size
		if main_window.width and main_window.height:
			window_size.width = main_window.width
			window_size.height = main_window.height
			args += '--resolution %s,%s ' % [main_window.width, main_window.height]

		pos -= window_size / 2
		if pos.y <= 0:
			pos.y = 0
		c += 1
		args += '--position %s,%s ' % [pos.x, pos.y]
		args += main_window.args

		var main_run_args = ProjectSettings.get_setting('editor/main_run_args')
		if main_run_args != args:
			ProjectSettings.set_setting('editor/main_run_args', args)

		get_editor_interface().play_main_scene()

		if main_run_args != main_window.args:
			ProjectSettings.set_setting('editor/main_run_args', main_run_args)
	
	kill_pids()
	for w in windows:
		var args = []
		var pos = window_positions[c]
		var window_size = default_window_size
		if w.width and w.height:
			window_size.width = w.width
			window_size.height = w.height
			args.append_array(['--resolution', '%s,%s' % [w.width, w.height]])
		pos -= window_size / 2
		if pos.y <= 0:
			pos.y = 0
		c += 1
		args.append_array(['--position', '%s,%s' % [pos.x, pos.y]])
		for arg in w.args.split(' '):
			args.append(arg)
		pids.append(OS.execute(OS.get_executable_path(), args, false))

# ******************************************************************************

func kill_pids():
	for pid in pids:
		OS.kill(pid)
	pids.clear()

# func _unhandled_input(event):
# 	if event is InputEventKey:
# 		if event.pressed and event.scancode == KEY_F4:
# 			_server_pressed()

# ******************************************************************************

func save_json(file_name: String, data) -> void:
	var f = File.new()
	f.open(file_name, File.WRITE)
	f.store_string(JSON.print(data, "\t"))
	f.close()

func load_json(file_name: String, default=null):
	var result = default
	var f = File.new()
	if f.file_exists(file_name):
		f.open(file_name, File.READ)
		var text = f.get_as_text()
		f.close()
		var json = JSON.parse(text)
		if !json.error:
			result = json.result
	return result
