class_name GameConfig
extends Resource

# Base settings
@export var name: String
@export var game_version: Array
@export var api_version: int
@export var board: Dictionary
@export var camera: Array
@export var player: Dictionary
@export var templates: Dictionary
@export var objects: Array
@export var images: Dictionary
@export var actions: Array

static func build_config_from_directory(dir: String) -> Resource:
	var game: Dictionary = Utils.load_json_from_file(str(dir, "/conf.json"))
	# Load game dictionary
	if game == {}:
		print("Something went wrong creating this resource")
		return null
	
	if not config_validated(game):
		print("This config is not complete. Refer to the blank config for every base variable required.")
		return null
	
	var g_conf: GameConfig = GameConfig.new()
	g_conf.name = game.name
	g_conf.game_version = game.game_version
	g_conf.api_version = Globals.CURRENT_API_VERSION
	g_conf.board = game.board
	g_conf.camera = game.camera
	g_conf.player = game.player
	g_conf.templates = game.templates
	g_conf.objects = game.objects
	g_conf.images = Utils.load_images_from_directory(str(dir,"/images"))
	g_conf.actions = game.actions
	return g_conf

# Validates that the config has all the variables necessary
static func config_validated(game: Dictionary) -> bool:
	for x in ["name", "game_version", "board", "camera", "player", "objects", "templates", "actions"]:
		if not x in game:
			return false
	return true
