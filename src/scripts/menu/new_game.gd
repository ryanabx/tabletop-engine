extends Control

@onready var ready_button: Button = $MainMargin/PanelMargins/Content/ContentList/StartGame
@onready var current_config_label: Button = $MainMargin/PanelMargins/Content/ContentList/BoardConfig/HBoxContainer2/CurrentConfigLabel
@onready var reset_config_button: Button = $MainMargin/PanelMargins/Content/ContentList/BoardConfig/HBoxContainer2/ResetConfig
@onready var load_from_file_button: Button = $MainMargin/PanelMargins/Content/ContentList/BoardConfig/HBoxContainer/LoadFromFile
@onready var sample_config: Button = $MainMargin/PanelMargins/Content/ContentList/BoardConfig/HBoxContainer/SampleConfig

func _ready() -> void:
	Globals.current_game = null
	MultiplayerManager.disband()

func _process(_delta: float) -> void:
	ready_button.disabled = (Globals.current_game == null)
	current_config_label.disabled = (Globals.current_game == null)
	reset_config_button.disabled = (Globals.current_game == null)
	load_from_file_button.disabled = (Globals.current_game != null)
	sample_config.disabled = (Globals.current_game != null)
	current_config_label.text = Globals.current_game.name if Globals.current_game != null else "None"

func _on_back_button_pressed() -> void:
	SignalManager.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")

func _on_start_game_pressed() -> void:
	SignalManager.scene_transition.emit("res://src/scenes/game_elements/board_manager.tscn")


func _on_sample_config_pressed() -> void:
	if FileAccess.file_exists("res://configs/default.obgf"):
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes("res://configs/default.obgf")
		var conf: GameConfig2 = GameConfig2.new()
		if conf.fill_bytes(bytes):
			Globals.current_game = conf
	else:
		print("Could not find default config")


func _on_reset_config_pressed() -> void:
	Globals.current_game = null


func _on_load_from_file_pressed() -> void:
	SignalManager.create_load_config_dialog.emit()
