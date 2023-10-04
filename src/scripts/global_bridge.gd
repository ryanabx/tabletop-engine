class_name GlobalBridge
extends RefCounted

static var global: RefCounted = (load("res://src/scripts/Global.cs") as Script).GetSingleton()
static var tabletop_game: Script = (load("res://src/scripts/modding/TabletopGame.cs")) as Script