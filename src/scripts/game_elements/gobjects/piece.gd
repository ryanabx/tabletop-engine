class_name Piece
extends Gobject

var image_up: String = ""
var image_down: String = ""
var collection: String = ""
var face_up: bool = false

@onready var sprite: Sprite2D = $Image