# Copyright Ryanabx 2023. Reference for the Open Tabletop API. Extend this class when making a tabletop
class_name TabletopGame
extends RefCounted

var board: Board
var include_images: Dictionary
var name: String = ""

## This function returns the configuration settings for this Tabletop Game
func export_settings() -> Dictionary:
    # NOTE: To be implemented by the configuration creator
    # assert(false, "Not implemented")
    return {}

## Regular settings used by the game
func settings() -> Dictionary:
    # NOTE: To be implemented by the configuration creator
    # assert(false, "Not implemented")
    return {}

## Initializes the Tabletop Game
func add_board(_board: Board) -> void:
    # NOTE: To be implemented by the configuration creator
    # assert(false, "Not implemented")
    pass

## Called when the board wants the game to start. Should be used to create all the initial game objects
func game_start() -> void:
    # NOTE: To be implemented by the configuration creator
    # assert(false, "Not implemented")
    pass

## Returns the list of user actions 
func get_actions() -> Array[String]:
    # NOTE: To be implemented by the configuration creator
    # assert(false, "Not implemented")
    return []

## Runs a specified action based off the action string, retrieved from get_actions()
## should return true if the action was successful, false otherwise
func run_action(_action: String) -> bool:
    # NOTE: To be implemented by the configuration creator
    # assert(false, "Not implemented")
    return false

## Sets images from the ImageIncludes in this config
func set_images(imgs: Dictionary) -> void:
    include_images = {}
    for img: String in imgs.keys():
        var n_img: Image = Image.new()
        n_img.load_webp_from_buffer(imgs[img])
        include_images[img] = ImageTexture.create_from_image(n_img)

func get_images() -> Dictionary:
    return include_images

# OVERRIDABLE FUNCTIONS

## Determines whether a selectable object can be stacked to another selectable object
## [OPTIONAL] Override this function to include programmability
func can_stack(from: Selectable, to: Selectable) -> bool:
    return true

## Determines whether a piece can be taken off a collection
## [OPTIONAL] Override this function to include programmability
func can_take_piece_off(_collection: Collection) -> bool:
    return true

# IMPORTING AND EXPORTING CONFIGURATIONS

## Import config
## WARNING: ALLOWS ARBITRARY CODE TO BE RAN,
## WAITING/HOPING FOR GDSCRIPT SANDBOXING IN THE FUTURE
static func import_config(bytes: PackedByteArray) -> TabletopGame:
    var config: Dictionary = bytes_to_var(bytes.decompress_dynamic(-1, 3))
    return _get_tabletop_game(config)

static func _get_tabletop_game(config: Dictionary) -> TabletopGame:
    var sc: GDScript = GDScript.new()
    sc.set_source_code(config.script)
    sc.reload()
    var obj := TabletopGame.new()
    obj.set_script(sc)
    obj.name = config.name

    obj.set_images(config.include_images)
    return obj

## Export config from a config file
static func export_from_file(fname: String) -> PackedByteArray:
    fname = fname.replace("\\", "/")
    if not FileAccess.file_exists(fname):
        print("File not found at ",fname)
        return PackedByteArray([])
    var scr_text: String = FileAccess.get_file_as_string(fname)
    var dir_path: String = fname.rsplit("/",false,1)[0]
    print("File name: ",fname, " :: Directory path: ",dir_path)
    return export_config_old(scr_text, dir_path)

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

## Export config
static func export_config_old(scr_text: String, dir_path: String) -> PackedByteArray:
    var sc: GDScript = GDScript.new()
    sc.set_source_code(scr_text)
    sc.reload()
    var obj := TabletopGame.new()
    obj.set_script(sc)
    obj._init()
    var config: Dictionary = {}
    config.name = obj.export_settings().name
    # Add includes
    config.include = {}
    config.include_images = {}
    # Add folders to includes
    for folder: String in obj.export_settings().include_folders:
        var folder_open: DirAccess = DirAccess.open(str(dir_path,"/",folder))
        if folder_open == null:
            print("DirAccess failed to open ",str(dir_path,"/",folder),": ",DirAccess.get_open_error())
            return PackedByteArray([])
        for fname: String in folder_open.get_files():
            # Validate file extension
            var file_extension: String = fname.rsplit(".", false, 1)[-1]
            if str(".",file_extension) not in obj.export_settings().include_types:
                continue
            # Add file to includes
            config.include[str(folder,"/",fname)] = FileAccess.get_file_as_bytes(str(dir_path,"/",folder,"/",fname))
    # Add images to get_images()
    for folder: String in obj.export_settings().include_image_folders:
        var folder_open: DirAccess = DirAccess.open(str(dir_path,"/",folder))
        if folder_open == null:
            print("DirAccess failed to open ",str(dir_path,"/",folder),": ",DirAccess.get_open_error())
            return PackedByteArray([])
        for fname: String in folder_open.get_files():
            # Validate file extension
            var file_extension: String = fname.rsplit(".", false, 1)[-1]
            if str(".",file_extension) not in obj.export_settings().include_image_types:
                continue
            # Add file to includes
            config.include_images[str(folder,"/",fname)] = Image.load_from_file(str(dir_path,"/",folder,"/",fname)).save_webp_to_buffer()
    config.script = scr_text
    # Everything turned out good! Compress bytes and return it
    return var_to_bytes(config).compress(3)
