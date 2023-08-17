extends FileDialog

var file_load_callback = JavaScriptBridge.create_callback(f_decided_web)

func _ready() -> void:
	SignalManager.create_load_config_dialog.connect(_on_create_load_config)
	file_selected.connect(_on_file_decided)
	filters = ["*.obgf"]
	if OS.get_name() == "Web":
		var window = JavaScriptBridge.get_interface("window")
		window.getFile(file_load_callback)

func _on_create_load_config() -> void:
	title = "Load a config of your choice!"
	if OS.get_name() != "Web":
		popup()
	else:
		var window = JavaScriptBridge.get_interface("window")
		window.input.click()

func _on_file_decided(fname: String) -> void:
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
	if conf.fill_bytes(buf):
		load_conf(conf)

func load_conf(conf: GameConfig2) -> void:
	SignalManager.load_game_config.emit(conf)
	dialog_text = ""

