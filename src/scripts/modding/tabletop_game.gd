# Copyright Ryanabx 2023. Reference for the Open Tabletop API. Extend this class when making a tabletop
class_name TabletopGame
extends RefCounted

var board: Board
var include_images: Dictionary

## Use this function to set your settings object
func _init() -> void:
    # NOTE: To be implemented by the configuration creator
    pass

## This function returns the configuration settings for this Tabletop Game
func export_settings() -> Dictionary:
    # NOTE: To be implemented by the configuration creator
    return {}

## Regular settings used by the game
func settings() -> Dictionary:
    # NOTE: To be implemented by the configuration creator
    return {}

## Initializes the Tabletop Game
func add_board(_board: Board) -> void:
    # NOTE: To be implemented by the configuration creator
    pass

## Called when the board wants the game to start. Should be used to create all the initial game objects
func game_start() -> void:
    # NOTE: To be implemented by the configuration creator
    pass

## Returns the list of user actions 
func get_actions() -> Array[String]:
    # NOTE: To be implemented by the configuration creator
    return []

## Runs a specified action based off the action string, retrieved from get_actions()
## should return true if the action was successful, false otherwise
func run_action(_action: String) -> bool:
    # NOTE: To be implemented by the configuration creator
    return false

## Sets images from the ImageIncludes in this config
func set_images(imgs: Dictionary) -> void:
    include_images = {}
    for img in imgs.keys():
        var n_img: Image = Image.new()
        n_img.load_webp_from_buffer(imgs[img])
        include_images[img] = ImageTexture.create_from_image(n_img)

# OVERRIDABLE FUNCTIONS

## Determines whether a piece can be stacked to a collection
## [OPTIONAL] Override this function to include programmability
func can_stack_piece(_piece: Piece, _collection: Collection) -> bool:
    return true

## Determines whether a piece can be taken off a collection
## [OPTIONAL] Override this function to include programmability
func can_take_piece_off(_collection: Collection) -> bool:
    return true

# IMPORTING AND EXPORTING CONFIGURATIONS

## Import an obgf file from a file path
static func import_obgf_from_file(fname: String) -> TabletopGame:
    if not FileAccess.file_exists(fname):
        print("File not found at ",fname)
        return null
    return import_obgf(FileAccess.get_file_as_bytes(fname))

## Import obgf
## WARNING: ALLOWS ARBITRARY CODE TO BE RAN,
## WAITING/HOPING FOR GDSCRIPT SANDBOXING IN THE FUTURE
static func import_obgf(bytes: PackedByteArray) -> TabletopGame:
    var config: Dictionary = bytes_to_var(bytes.decompress_dynamic(-1, 3))
    var sc: GDScript = GDScript.new()
    sc.set_source_code(config.script)
    sc.reload()
    var obj = TabletopGame.new()
    obj.set_script(sc)

    obj.set_images(config.include_images)
    return obj

## Export obgf from a config file
static func export_obgf_from_file(fname: String) -> PackedByteArray:
    fname = fname.replace("\\", "/")
    if not FileAccess.file_exists(fname):
        print("File not found at ",fname)
        return PackedByteArray([])
    var scr_text: String = FileAccess.get_file_as_string(fname)
    var dir_path: String = fname.rsplit("/",false,1)[0]
    print("File name: ",fname, " :: Directory path: ",dir_path)
    return export_obgf(scr_text, dir_path)

## Export obgf
static func export_obgf(scr_text: String, dir_path: String) -> PackedByteArray:
    var sc: GDScript = GDScript.new()
    sc.set_source_code(scr_text)
    sc.reload()
    var obj = TabletopGame.new()
    obj.set_script(sc)
    obj._init()
    var config: Dictionary = {}
    config.name = obj.export_settings().name
    # Add includes
    config.include = {}
    config.include_images = {}
    # Add folders to includes
    for folder in obj.export_settings().include_folders:
        var folder_open: DirAccess = DirAccess.open(str(dir_path,"/",folder))
        if folder_open == null:
            print("DirAccess failed to open ",str(dir_path,"/",folder),": ",DirAccess.get_open_error())
            return PackedByteArray([])
        for fname in folder_open.get_files():
            # Validate file extension
            var file_extension: String = fname.rsplit(".", false, 1)[-1]
            if str(".",file_extension) not in obj.export_settings().include_types:
                continue
            # Add file to includes
            config.include[str(folder,"/",fname)] = FileAccess.get_file_as_bytes(str(dir_path,"/",folder,"/",fname))
    # Add images to include_images
    for folder in obj.export_settings().include_image_folders:
        var folder_open: DirAccess = DirAccess.open(str(dir_path,"/",folder))
        if folder_open == null:
            print("DirAccess failed to open ",str(dir_path,"/",folder),": ",DirAccess.get_open_error())
            return PackedByteArray([])
        for fname in folder_open.get_files():
            # Validate file extension
            var file_extension: String = fname.rsplit(".", false, 1)[-1]
            if str(".",file_extension) not in obj.export_settings().include_image_types:
                continue
            # Add file to includes
            config.include_images[str(folder,"/",fname)] = Image.load_from_file(str(dir_path,"/",folder,"/",fname)).save_webp_to_buffer()
    config.script = scr_text
    # Everything turned out good! Compress bytes and return it
    return var_to_bytes(config).compress(3)
