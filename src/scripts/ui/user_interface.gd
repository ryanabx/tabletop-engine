class_name UserInterface
extends Control

@onready var _game_label = $PanelContainer/MarginContainer/HBoxContainer/GameLabel

func set_game_name(_game: String):
	_game_label.text = "Game: " + _game
