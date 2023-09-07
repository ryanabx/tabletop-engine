extends PopupPanel

@onready var url_edit: LineEdit = $Control/MarginContainer/VBoxContainer/HBoxContainer/URLEdit
@onready var download_button: Button = $Control/MarginContainer/VBoxContainer/Download

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	about_to_popup.connect(_about_to_popup)
	SignalManager.download_config_popup.connect(popup)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	download_button.disabled = (url_edit.text == "")

func _about_to_popup() -> void:
	url_edit.text = ""

func _on_cancel_pressed() -> void:
	hide()


func _on_download_pressed() -> void:
	if await Utils.FileManager.download_file_from_url(url_edit.text):
		SignalManager.config_added.emit()
		hide()


func _on_paste_link_pressed() -> void:
	url_edit.text = DisplayServer.clipboard_get()
