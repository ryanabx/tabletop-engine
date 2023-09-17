extends Control

@onready var version := %Version
@onready var quit_button := %Quit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    version.text = str("Version: ",ProjectSettings.get_setting("application/config/version"))
    if Utils.is_mobile_platform():
        quit_button.hide()
    for i: Node in get_tree().get_nodes_in_group("hi"):
        pass
    Globals.load_this_game = PackedByteArray([])

func _process(_delta: float) -> void:
    %ButtonFlow.vertical = get_viewport_rect().size.y > get_viewport_rect().size.x


func _on_new_game_pressed() -> void:
    SignalManager.scene_transition.emit("res://src/scenes/menu/new_game.tscn")


func _on_quit_pressed() -> void:
    get_tree().quit()


func _on_settings_pressed() -> void:
    SignalManager.scene_transition.emit("res://src/scenes/menu/settings.tscn")


func _on_configurations_pressed():
    SignalManager.scene_transition.emit("res://src/scenes/menu/config_editor.tscn")
