extends Control

@onready var reset_config_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/RemoveConfig
@onready var load_config_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/LoadConfig

func _ready() -> void:
	Globals.current_game = null
	MultiplayerManager.disband()

func _process(_delta: float) -> void:
	reset_config_button.disabled = (Globals.current_game == null)
	load_config_button.text = Globals.current_game.name if Globals.current_game != null else "Default Config"

func _on_back_button_pressed() -> void:
	SignalManager.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")

func load_sample_config() -> void:
	if FileAccess.file_exists("res://configs/default.obgf"):
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes("res://configs/default.obgf")
		var conf: GameConfig2 = GameConfig2.new()
		if conf.fill_bytes(bytes):
			Globals.current_game = conf
	else:
		print("Could not find default config")

func _on_load_config_pressed():
	SignalManager.create_load_config_dialog.emit()


func _on_remove_config_pressed():
	Globals.current_game = null


func _on_ready_pressed():
	if Globals.current_game == null:
		load_sample_config()
	SignalManager.scene_transition.emit("res://src/scenes/game_elements/board_manager.tscn")
