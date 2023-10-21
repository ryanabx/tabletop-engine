extends Node

func play_sound(sound: String) -> void:
    if get_node(sound) != null:
        (get_node(sound) as AudioStreamPlayer).play()
