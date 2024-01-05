extends Node

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        if touch.pressed:
            play_sound("click_down")
        else:
            play_sound("click_up")

func play_sound(sound: String) -> void:
    if get_node(sound) != null:
        (get_node(sound) as AudioStreamPlayer).play()
