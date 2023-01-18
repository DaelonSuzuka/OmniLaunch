tool
extends ConfirmationDialog

# ******************************************************************************

onready var profiles = $"%Profiles"
onready var new_profile = $"%NewProfile"
onready var new_window = $"%NewWindow"
onready var window_box = $"%WindowBox"

var Window = preload('Window.tscn')
var _data = {}
var current_profile = ''

var plugin = null

# ******************************************************************************

func _ready():
	new_profile.connect('pressed', self, 'new_profile')
	new_window.connect('pressed', self, 'new_window')

	profiles.connect('profile_selected', self, 'profile_selected')
	profiles.connect('profile_renamed', self, 'profile_renamed')
	profiles.connect('profile_created', self, 'profile_created')
	profiles.connect('profile_deleted', self, 'profile_deleted')

func new_profile():
	var profile_name = 'New Profile'
	var i = 1
	if profile_name in _data.profiles:
		while 'New Profile ' + str(i) in _data.profiles:
			i += 1
		profile_name = 'New Profile ' + str(i)

	_data.profiles[profile_name] = plugin.default_profile.duplicate(true)

	profiles.create_profile(profile_name)

func new_window(data=null):
	var new_w = Window.instance()
	window_box.add_child(new_w)

	new_w.main.connect('toggled', self, 'reset_mains', [new_w])
	if data:
		new_w.set_data(data)
	return new_w

func reset_mains(state, new_main):
	if state == false:
		return

	for w in window_box.get_children():
		if w != new_main:
			w.main.pressed = false

func profile_selected(profile_name):
	save_window_data()

	_data.current_profile = profile_name
	
	set_window_data(profile_name)

func profile_renamed(old_name, new_name):
	var new_profiles = {}

	for key in _data.profiles:
		if key == old_name:
			new_profiles[new_name] = _data.profiles[old_name].duplicate(true)
		else:
			new_profiles[key] = _data.profiles[key].duplicate(true)

	_data.profiles = new_profiles.duplicate(true)
	if _data.current_profile == old_name:
		_data.current_profile = new_name

func profile_created(profile_name):
	pass

func profile_deleted(profile_name):
	_data.profiles.erase(profile_name)

	if _data.current_profile == profile_name:
		for key in _data.profiles:
			_data.current_profile = key
			break

# ******************************************************************************

func clear_current_windows():
	for old_w in window_box.get_children():
		window_box.remove_child(old_w)
		old_w.queue_free()

func create_windows(windows):
	for w in windows:
		new_window(w)

func set_window_data(profile_name):
	clear_current_windows()
	var windows = _data.profiles[profile_name].windows.duplicate(true)

	create_windows(windows)

func save_window_data():
	var profile_name = _data.current_profile

	if window_box.get_child_count():
		_data.profiles[profile_name].windows.clear()
		for w in window_box.get_children():
			_data.profiles[profile_name].windows.append(w.get_data())

# ******************************************************************************

func set_data(data):
	_data = data.duplicate(true)
	profiles.set_data(_data)

func get_data():
	var data = _data.duplicate(true)
	data.profiles[data.current_profile].windows.clear()
	for w in window_box.get_children():
		data.profiles[data.current_profile].windows.append(w.get_data())
	return data
