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
	print("File selected! ",path)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()
	print("Config created at ", path)