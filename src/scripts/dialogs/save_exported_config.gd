extends FileDialog

var bytes: PackedByteArray

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalManager.export_config_created.connect(export_config_created)
	file_selected.connect(fpath_selected)

func export_config_created(_bytes: PackedByteArray) -> void:
	bytes = _bytes
	print("Waiting for file selected...")
	popup()
	

func fpath_selected(path: String) -> void:
	if path.rfind(Globals.CONFIG_EXTENSION) != len(path) - len(Globals.CONFIG_EXTENSION):
		print("Adding file extension")
		path = path + Globals.CONFIG_EXTENSION
	print("File selected! ",path)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()
	print("Config created at ", path)