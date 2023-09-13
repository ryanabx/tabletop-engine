extends FileDialog


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalManager.create_export_config_dialog.connect(popup)
	file_selected.connect(filepath_selected)


func filepath_selected(fpath: String) -> void:
	var bytes: PackedByteArray = TabletopGame.export_from_file(fpath)
	if bytes.is_empty():
		print("Problem creating %s config" % Globals.CONFIG_EXTENSION)
		return
	SignalManager.export_config_created.emit(bytes)
	

