extends Control

@onready var label = $PanelContainer/Label

func set_label(lbl: String) -> void:
	label.text = lbl
