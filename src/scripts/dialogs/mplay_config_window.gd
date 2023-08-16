extends Window


func _ready() -> void:
	%CreateServer.pressed.connect(_create_server_button)
	%CreateClient.pressed.connect(_create_client_button)

func _create_server_button():
	pass

func _create_client_button():
	pass