class_name GameConfig
extends Resource

# Base settings
@export var name: String
@export var game_version: Array
@export var board: Dictionary
@export var templates: Dictionary
@export var objects: Array
@export var actions: Array
@export var player: Dictionary
@export var images: Dictionary

static func build_config_from_file(fname: String) -> Resource:
	var game: Dictionary = Utils.load_json_from_file(str(fname))
	
	# Load game dictionary
	if game == {}:
		print("Something went wrong creating this resource")
		return null
	
	if not config_validated(game):
		print("This config is not complete. Refer to the blank config for every base variable required.")
		return null
	
	var directory: String = fname.rsplit("/",true,1)[0]
	var image_directory: String = str(directory, "/",game.images)
	print(image_directory)
	
	var g_conf: GameConfig = GameConfig.new()
	g_conf.name = game.name
	g_conf.game_version = game.game_version
	g_conf.board = game.board
	g_conf.templates = game.templates
	g_conf.objects = game.objects
	g_conf.actions = game.actions
	g_conf.player = game.player
	g_conf.images = Utils.load_images_from_directory(image_directory)
	return g_conf

# Validates that the config has all the variables necessary
static func config_validated(game: Dictionary) -> bool:
	for x in ["name", "game_version", "board", "templates", "objects", "player", "actions"]:
		if not x in game:
			return false
	return true

# Unpacks the data for sending over rpc
func unpack_data() -> Dictionary:
	var gc_d: Dictionary = {}
	gc_d.name = self.name
	gc_d.game_version = self.game_version
	gc_d.board = self.board
	gc_d.templates = self.templates
	gc_d.objects = self.objects
	gc_d.actions = self.actions
	gc_d.player = self.player
	gc_d.images = {}
	for key in self.images.keys():
		gc_d.images[key] = self.images[key].get_image().save_webp_to_buffer()
	return gc_d

static func repack(gc_d: Dictionary) -> GameConfig:
	var gc: GameConfig = GameConfig.new()
	gc.name = gc_d.name
	gc.game_version = gc_d.game_version
	gc.board = gc_d.board
	gc.templates = gc_d.templates
	gc.objects = gc_d.objects
	gc.actions = gc_d.actions
	gc.player = gc_d.player
	gc.images = {}
	for key in gc_d.images.keys():
		var img: Image = Image.new()
		img.load_webp_from_buffer(gc_d.images[key])
		gc.images[key] = ImageTexture.create_from_image(img)
	return gc
