extends HBoxContainer

signal joinGame(ip)

@onready var usernameLineEdit = $/root/World/Menu/HostJoinMenu/LineEdit

func _process(delta):
	if (str(usernameLineEdit.text).length() >= 3 and str(usernameLineEdit.text).length() <= 20):
		$Button.disabled = false
	else:
		$Button.disabled = true

func _on_button_pressed():
	joinGame.emit($IP.text)
