extends Button

@export var back_scene: String

@export var fade_rect: ColorRect

func _on_pressed() -> void:
    fade_rect.scene_transition.emit(back_scene)
