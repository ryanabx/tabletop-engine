extends Node

func get_bounds() -> Rect2:
	return get_viewport().get_visible_rect()

func get_tabletop() -> Tabletop:
	return get_node("/root/Tabletop") as Tabletop
