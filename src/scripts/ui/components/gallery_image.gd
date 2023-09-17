class_name GalleryImage
extends BoxContainer

var texture: Texture2D
var text: String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    $Texture.texture = texture
    $Text.text = text

func _set_type(image: Texture2D, _text: String) -> void:
    texture = image
    text = _text


func _on_erase_pressed() -> void:
    queue_free()


func _on_text_text_changed(new_text: String) -> void:
    text = new_text
