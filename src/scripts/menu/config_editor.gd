extends Control


@onready var config_selector: ConfigSelector = %ConfigSelector
@onready var config_code: CodeEdit = %ConfigCode

var images: Dictionary = {}
var files: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float):
    %ImportConfig.disabled = Globals.load_this_game


func _on_back_button_pressed():
    SignalManager.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")

func clear_config() -> void:
    config_code.text = ""
    images = {}

func refresh_from_loaded(tbt: TabletopGame) -> void:
    if tbt == null:
        clear_config()
        return
    config_code.text = tbt.get_script().source_code
    images = tbt.get_images()


func _on_import_configuration_pressed() -> void:
    import_config_to_editor()

func import_config_to_editor() -> void:
    current_config = config_selector.get_selected_config()
    refresh_from_loaded(current_config)
