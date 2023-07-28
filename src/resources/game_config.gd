class_name GameConfig
extends Resource

# Base settings
@export var name: String
@export var game_version: int
@export var api_version: int

@export var background_image: int

@export var board_settings: BoardSettingsResource
@export var player_settings: PlayerSettings

@export var board_objects: Array[BoardObjectResource]
@export var textures: Array

class BoardSettingsResource extends Resource:
	@export var bounds: Rect2
	@export var camera: Transform2D

class PlayerSettings extends Resource:
	@export var players: PlayerNum

# player_settings > players

class PlayerNum extends Resource:
	@export var minimum: int
	@export var maximum: int

# board_objects

class BoardObjectResource extends Resource:
	@export var transform: Transform2D

class CollectionResource extends BoardObjectResource:
	@export var behavior: String
	@export var permanent: bool
	@export var force_state: bool
	@export var view_perms: Array
	@export var inside: Array[BoardObjectResource]

class PieceResource extends BoardObjectResource:
	@export var image_up: int
	@export var image_down: int
	@export var face_up: bool

static func build_config_from_directory(dir: String) -> GameConfig:
	var game: Dictionary = Utils.load_json_from_file(str(dir, "/conf.json"))
	# Load game dictionary
	if game == {}:
		print("Something went wrong creating this resource")
		return null
	var bs: Dictionary = game.board_settings
	var ps: Dictionary = game.player_settings
	# Create config
	var g_conf: GameConfig = GameConfig.new()
	g_conf.name = game.name
	g_conf.game_version = game.game_version
	g_conf.api_version = Globals.CURRENT_API_VERSION
	# Load image dictionary
	var images: Dictionary = Utils.load_images_from_directory(str(dir, "/images"))
	g_conf.textures = images.arr
	g_conf.background_image = images.ref[game.background_image]
	# Load scale variable
	var scale: Vector2 = Vector2(bs.scale.x, bs.scale.y)
	# Board Settings
	g_conf.board_settings = BoardSettingsResource.new()
	g_conf.board_settings.bounds = Rect2(
		Vector2(bs.bounds.position.x, bs.bounds.position.y) * scale,
		Vector2(bs.bounds.scale.x, bs.bounds.scale.y) * scale
	)
	if "y" in bs.camera.scale:
		g_conf.board_settings.camera = Transform2D(
			deg_to_rad(bs.camera.rotation_degrees),
			Vector2(bs.camera.scale.y, bs.camera.scale.y) * scale,
			0.0,
			Vector2(bs.camera.position.x, bs.camera.position.y) * scale
		)
	else:
		g_conf.board_settings.camera = Transform2D(
			deg_to_rad(bs.camera.rotation_degrees),
			Vector2(bs.camera.scale.x, bs.camera.scale.x) * scale,
			0.0,
			Vector2(bs.camera.position.x, bs.camera.position.y) * scale
		)
	# Player settings
	g_conf.player_settings = PlayerSettings.new()
	g_conf.player_settings.players = PlayerNum.new()
	g_conf.player_settings.players.minimum = ps.players.min
	g_conf.player_settings.players.maximum = ps.players.max
	# Board objects
	g_conf.board_objects = []

	for obj in game.board_objects:
		g_conf.board_objects = g_conf.board_objects + build_object(obj, [], images, scale)

	return g_conf

static func build_object(obj: Dictionary, vars: Array[ConfVar],images: Dictionary, scale: Vector2) -> Array[BoardObjectResource]:
	match obj.type:
		# Functional Types
		"foreach": return build_foreach(obj, vars, images, scale)
		"repeat": return build_repeat(obj, vars, images, scale)
		# Object Types
		"piece": return [build_piece(obj, vars, images, scale)]
		"collection": return [build_collection(obj, vars, images, scale)]
		_: return []

static func build_foreach(obj: Dictionary, vars: Array[ConfVar], images: Dictionary, scale: Vector2) -> Array[BoardObjectResource]:
	var items: Array[BoardObjectResource] = []

	var v: ConfVar = ConfVar.new(obj.repl, obj.vals)

	var vars2 = vars.duplicate(false)
	vars2.append(v)


	for i in range(v.vals.size()):
		v.index = i
		for d in obj.do:
			items = items + build_object(d, vars2, images, scale)
	return items


static func build_repeat(obj: Dictionary, vars: Array[ConfVar], images: Dictionary, scale: Vector2) -> Array[BoardObjectResource]:
	var items: Array[BoardObjectResource] = []
	for x in range(obj.amount):
		for d in obj.do:
			items = items + build_object(d, vars, images, scale)
	return items

static func build_collection(obj: Dictionary, vars: Array[ConfVar],images: Dictionary, scale: Vector2) -> CollectionResource:
	var coll: CollectionResource = CollectionResource.new()
	coll.behavior = obj.options.behavior
	coll.permanent = obj.options.permanent
	coll.force_state = obj.options.force_state
	coll.view_perms = obj.players.viewing as Array[bool]
	coll.transform = Transform2D(
		deg_to_rad(obj.transform.rotation_degrees),
		Vector2(obj.transform.scale.x, obj.transform.scale.y) * scale,
		0.0,
		Vector2(obj.transform.position.x, obj.transform.position.y) * scale
	)
	coll.inside = []
	for _obj in obj.inside:
		coll.inside = coll.inside + build_object(_obj, vars, images, scale)
	return coll

static func build_piece(obj: Dictionary, vars: Array[ConfVar],images: Dictionary, scale: Vector2) -> PieceResource:
	var piece: PieceResource = PieceResource.new()
	piece.face_up = obj.face_up
	piece.transform = Transform2D(
		deg_to_rad(obj.transform.rotation_degrees),
		Vector2(obj.transform.scale.x, obj.transform.scale.y) * scale,
		0.0,
		Vector2(obj.transform.position.x, obj.transform.position.y) * scale
	)
	var up_img: String = obj.images.face_up
	var down_img: String = obj.images.face_down
	for cv in vars:
		up_img = up_img.replacen(cv.repl, cv.vals[cv.index])
		down_img = down_img.replacen(cv.repl, cv.vals[cv.index])
	piece.image_up = images.ref[up_img]
	piece.image_down = images.ref[down_img]
	return piece

class ConfVar:
	var repl: String
	var vals: Array
	var index: int = 0

	func _init(_rep: String, _vals: Array) -> void:
		repl = _rep
		vals = _vals
