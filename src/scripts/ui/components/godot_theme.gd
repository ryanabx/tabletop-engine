class_name GodotVSCodeTheme
extends Node

var string_property: String = "Hello, world!"

var number_property: int = 80

func hello_world() -> int:
    print("Hello, Godot!")
    return 1

func _process(delta: float) -> void:
    print("Time since last frame: %d" % delta)