tool
extends ConfirmationDialog

# ******************************************************************************

func _ready() -> void:
	get_ok().text = 'Send Feedback'

func open():
	$'%TextEdit'.text = ''
	popup_centered(Vector2(600, 500))

func get_feedback():
	var text = ''

	text += $'%TextEdit'.text

	return text