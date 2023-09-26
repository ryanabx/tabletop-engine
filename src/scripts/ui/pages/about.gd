extends Control

func _on_back_button_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/ui/pages/main_menu.tscn")
