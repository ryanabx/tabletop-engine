extends FileDialog

var file_load_callback = JavaScriptBridge.create_callback(f_decided_web)

func _ready() -> void:
	SignalManager.create_load_config_dialog.connect(_on_create_load_config)
	file_selected.connect(filepath_selected)
	filters = ["*.obgf"]
	if Utils.is_web_platform():
		var window = JavaScriptBridge.get_interface("window")
		window.getFile(file_load_callback)

func _on_create_load_config() -> void:
	title = "Import a config"
	if not Utils.is_web_platform():
		popup()
	else:
		var window = JavaScriptBridge.get_interface("window")
		window.input.click()

func filepath_selected(fname: String) -> void:
	print(fname)
	if FileAccess.file_exists(fname):
		file_decided(FileAccess.get_file_as_bytes(fname))
	

func f_decided_web(args) -> void:
	print(args)
	print("File decided")
	var buf: PackedByteArray = []

	for x in range(args[0].length):
		buf.append(args[0][x])
	
	file_decided(buf)

func file_decided(buf: PackedByteArray) -> void:
	var conf: GameConfig2 = GameConfig2.new()
	if not conf.fill_bytes(buf): # Invalid config, save it back
		return
	
	Utils.create_dir(Globals.CONFIG_REPO)

	var conf_path: String = str(Globals.CONFIG_REPO, "/",conf.name,Globals.CONFIG_EXTENSION)

	Utils.delete_file(conf_path)
	
	var local_copy: FileAccess = FileAccess.open(conf_path, FileAccess.WRITE)

	if local_copy == null:
		print(FileAccess.get_open_error(), ": ", conf_path)
		return

	local_copy.store_buffer(buf)
	local_copy.close()
	SignalManager.config_added.emit()

