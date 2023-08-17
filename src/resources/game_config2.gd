class_name GameConfig2
extends RefCounted

# Base settings
var name: String
var game_version: Array
var board: Dictionary
var templates: Dictionary
var objects: Array
var actions: Array
var player: Dictionary
var images: Dictionary

static func export_config_from_file(fname: String) -> PackedByteArray:
	var game: Dictionary = Utils.load_json_from_file(str(fname))
	var gc: GameConfig2 = GameConfig2.new()
	gc.fill_json(game, fname)
	return gc.to_bytes()

func fill_json(game: Dictionary, fname: String) -> void:
	if game == {}:
		print("Something went wrong creating this resource")
		return
	
	if not GameConfig2.config_validated(game):
		print("This config is not complete. Refer to the blank config for every base variable required.")
		return
	
	var directory: String = fname.rsplit("/",true,1)[0]
	var image_directory: String = str(directory, "/",game.images)
	
	name = game.name
	game_version = game.game_version
	board = game.board
	templates = game.templates
	objects = game.objects
	actions = game.actions
	player = game.player
	images = Utils.load_images_from_directory(image_directory)

func to_bytes() -> PackedByteArray:
	var _dict: Dictionary = {
		"name": name,
		"game_version": game_version,
		"board": board,
		"templates": templates,
		"objects": objects,
		"actions": actions,
		"player": player,
		"images": {}
	}
	for key in images.keys():
		_dict.images[key] = self.images[key].get_image().save_webp_to_buffer()
	var _bytes: PackedByteArray = var_to_bytes(_dict).compress(FileAccess.COMPRESSION_GZIP)
	return _bytes

func fill_bytes(_bytes: PackedByteArray) -> bool:
	print(_bytes.size(), " bytes loaded")
	var _dict: Dictionary = bytes_to_var(_bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
	name = _dict.name
	game_version = _dict.game_version
	board = _dict.board
	templates = _dict.templates
	objects = _dict.objects
	actions = _dict.actions
	player = _dict.player
	for key in _dict.images.keys():
		var img: Image = Image.new()
		img.load_webp_from_buffer(_dict.images[key])
		images[key] = ImageTexture.create_from_image(img)
	return true
	


# Validates that the config has all the variables necessary
static func config_validated(game: Dictionary) -> bool:
	for x in ["name", "game_version", "board", "templates", "objects", "player", "actions"]:
		if not x in game:
			return false
	return true
	
