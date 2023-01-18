tool
extends Control

# ******************************************************************************

onready var _name = $"%Name"
onready var main = $"%Main"
onready var args = $"%Args"
onready var number = $"%Number"
onready var size_x = $"%SizeX"
onready var size_y = $"%SizeY"

onready var close_button = $"%CloseButton"

# ******************************************************************************

func _ready():
	close_button.connect('pressed', self, 'queue_free')

func set_data(data):
	_name.text = data.get('name', '')
	main.pressed = data.get('main', false)
	args.text = data.get('args', '')
	number.value = data.get('number', 1)
	size_x.value = data.get('width', 0)
	size_y.value = data.get('height', 0)

func get_data():
	var data = {
		name = _name.text,
		main = main.pressed,
		args = args.text,
		number = number.value,
		width = size_x.value,
		height = size_y.value,
	}

	return data
