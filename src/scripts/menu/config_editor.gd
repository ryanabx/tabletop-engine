extends Control




# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float):
    pass


func _on_back_button_pressed():
    SignalManager.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")
