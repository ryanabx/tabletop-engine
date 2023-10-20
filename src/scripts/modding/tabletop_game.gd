# Copyright Ryanabx 2023. Reference for the Tabletop Engine API. Extend this class when making a tabletop
class_name TabletopGame
extends RefCounted

var board: Board
var include_images: Dictionary
var name: String = ""

# MUST IMPLEMENT

## Called by all players when the board spawns in. Use this to set board settings.
## NOTE: MUST be implemented by the configuration creator.
func initialize() -> void:
    assert(false, "Not implemented")
    pass

## Called when the board wants the game to start. Should be used to create all the initial game objects.
## NOTE: MUST be implemented by the configuration creator.
func game_start() -> void:
    assert(false, "Not implemented")
    pass

# OPTIONAL

## Returns the list of user actions.
## This method may be optionally overridden. By default returns an empty [Array]
func get_actions() -> Array[String]:
    var res: Array[String] = []
    return res

## Runs a specified action based off the action string, retrieved from get_actions()
## should return true if the action was successful, false otherwise.
## This method may be optionally overridden. By default returns [false]
func run_action(_action: String) -> bool:
    return false

## Determines whether a selectable object can be stacked to another selectable object.
## This method may be optionally overridden. By default returns [true]
func can_stack(_from: Selectable, _to: Selectable) -> bool:
    return true

## Determines whether a piece can be taken off a collection.
## This method may be optionally overridden. By default returns [true]
func can_take_piece_off(_collection: Collection) -> bool:
    return true

## Determines whether the selectable object [param _highlighted] can be highlighted,
## optionally given [param _selected] object.
## This method may be optionally overridden. By default returns [true]
func can_highlight(_highlighted: Selectable, _selected: Selectable) -> bool:
    return true

# For use by config loader and game

## Sets images from the ImageIncludes in this config
func set_images(imgs: Dictionary) -> void:
    include_images = {}
    for img: String in imgs.keys():
        var n_img: Image = Image.new()
        var buf: PackedByteArray = imgs[img]
        n_img.load_webp_from_buffer(buf)
        include_images[img] = ImageTexture.create_from_image(n_img)

func get_images() -> Dictionary:
    return include_images

# IMPORTING AND EXPORTING CONFIGURATIONS

## Import config
## WARNING: ALLOWS ARBITRARY CODE TO BE RAN,
## WAITING/HOPING FOR GDSCRIPT SANDBOXING IN THE FUTURE
static func import_config(bytes: PackedByteArray) -> TabletopGame:
    var config: Dictionary = bytes_to_var(bytes.decompress_dynamic(-1, 3))
    return _get_tabletop_game(config)

static func _get_tabletop_game(config: Dictionary) -> TabletopGame:
    var sc: GDScript = GDScript.new()
    sc.set_source_code(config.script as Variant as String)
    sc.reload()
    var obj: TabletopGame = TabletopGame.new()
    obj.set_script(sc)
    obj.name = config.name

    obj.set_images(config.include_images as Variant as Dictionary)
    return obj

static func export_config(source_code: String, images: Dictionary, game_name: String) -> PackedByteArray:
    var config: Dictionary = {}
    config.name = game_name
    config.include_images = images
    config.script = source_code
    # if not source_validation(config):
        # return [] TODO: Fix valdation so it doesn't error out
    return var_to_bytes(config).compress(3)

static func source_validation(config: Dictionary) -> bool:
    var tabletop: TabletopGame = _get_tabletop_game(config)
    return tabletop != null