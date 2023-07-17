class_name RightClickMenuButton
extends Button

func _init(lbl: String, functionality: Callable):
	text = lbl
	self.pressed.connect(functionality)
