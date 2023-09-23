class_name Board
extends Node2D
## Board is the main class interfaced with by any TabletopGame.
## 
## The board contains utility functions that are used for operating on the currently running tabletop.

## The currently running tabletop game script. If you are modding, this is the current game (your script)
var game: TabletopGame = null

## The size of the board.
var size: Vector2 = Vector2.ONE

## Enumeration of the types that a GameObject can be.
## [member GameObjectType.MAX] defines the end of the enum, and can't be used
## to instantiate a GameObject.
enum GameObjectType {
    FLAT,
    DECK,
    HAND,
    MAX
}


## Companion constant to [enum GameObjectType] that defines strings for each type.
const GAME_OBJECT_TYPE_STRING = [
    "flat", "deck", "hand"
]

## Specifies the mode the user is using. [member CAMERA] is the camera mode,
## and [member SELECT] is the select mode.
enum InputMode {
    CAMERA,
    SELECT
}

## Specifies the way cards are selected. [member TAP] requires a tap on the object,
## and [member DRAG] doesn't.
enum TouchType {
    TAP,
    DRAG
}

## A reference to the number of players currently in-game.
var number_of_players: int

## The player number assigned to this user. Different from the assigned multiplayer ID.
var player_id: int

## The selected input mode by the user. See [enum InputMode].
var input_mode: InputMode = InputMode.SELECT
## The selected touch type by the user. See [enum TouchType].
var touch_type: TouchType = TouchType.DRAG if not Utils.is_mobile_platform() else TouchType.TAP

signal property_sync()

# Board properties
var background: String = "":
    set(val):
        background = val
        _background_sprite.set_texture(_get_image(background))
        _background_sprite.scale = size / _background_sprite.texture.get_size()
    get:
        return background

# Private variables
var _background_sprite: Sprite2D

# Children
@onready var _board_player: BoardPlayer = $BoardPlayer
@onready var _board_objects: Node2D = $BoardObjects
@onready var _highlights: Node2D = $Highlights

# Private signals
signal _game_menu_create(obj: Selectable)
signal _game_menu_destroy()

var _counter: int = 0

## Returns the player for this board instance.
func get_player() -> BoardPlayer:
    return _board_player

## Finds a specified GameObject by name.
## Returns [null] if the GameObject cannot be found.
func get_object(n: String) -> GameObject:
    var o: GameObject = _board_objects.get_node_or_null(n)
    if o == null or o.get_parent() != _board_objects:
        return null
    return o

## Gets a list of all game objects.
func get_all_objects() -> Array[GameObject]:
    var res: Array[GameObject] = []
    res.assign(_board_objects.get_children())
    return res

## Erases all the game objects on the board.
func clear_board() -> void:
    for obj: GameObject in get_all_objects():
        obj._authority = multiplayer.get_unique_id()
        obj._erase_rpc.rpc(true)

## Moves a piece from [param from] to [param to].
## Optionally specify [param from_ind] as the index to take from, and
## [param to_ind] as the index to put in.
func move_piece(from: Collection, to: Collection, from_ind: int = -1, to_ind: int = -1) -> void:
    var pc: Piece
    if from_ind != -1:
        pc = from._remove_piece_at(from_ind)
    else:
        pc = from.remove_from_top()
    
    if to_ind != -1:
        to._add_piece_at(pc, to_ind)
    else:
        to.add_piece(pc)

## Finds a specified GameObject by index.
## Returns [null] if the index is out of bounds.
func get_object_by_index(index: int) -> GameObject:
    return _board_objects.get_children()[index]

## Creates a new object on the board, and returns a pointer to that object.
## Takes a [param type] from [enum Board.GameObjectType], to define the type of object to be created.
## A list of modifiable GameObject properties can be found in each GameObject's reference.
func new_game_object(type: Board.GameObjectType, properties: Dictionary) -> GameObject:
    var c: GameObject
    if not "name" in properties:
        properties.name = "%d_%s_%d" % [multiplayer.get_unique_id(),Board.GAME_OBJECT_TYPE_STRING[type],_counter]
        _counter += 1
    c = _instantiate_by_type(type).new()
    c.board = self
    c.object_type = type
    for prop: String in properties:
        c.set(prop, properties[prop])
    _board_objects.add_child(c)
    # RPC
    _new_game_object_rpc.rpc(type, properties)
    c.set_multiplayer_authority(multiplayer.get_unique_id())
    return c

## Finds and erases a specified GameObject by name.
## Use [param recursive] to specify whether nested game objects should
## be erased too.
## Returns [true] if the operation was successful, [false] otherwise.
func erase_object(object_name: String, recursive: bool = false) -> bool:
    var obj: GameObject = get_object(object_name)
    if obj == null:
        return false
    obj.erase(recursive)
    return true

# Private methods

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(-size / 2, size), Color.WHITE, false, Global.OUTLINE_THICKNESS) # Board background

func _get_image(path: String) -> Texture2D:
    if game == null:
        return null
    if game.get_images() == null:
        return null
    if not path in game.get_images():
        return null
    return game.get_images()[path]

var _ready_players: Array = []

func _instantiate_by_type(type: Board.GameObjectType) -> GDScript:
    match type:
        Board.GameObjectType.FLAT:
            return Flat
        Board.GameObjectType.DECK:
            return Deck
        Board.GameObjectType.HAND:
            return Hand
    print("WARNING: None of the above types specified")
    return GameObject

@rpc("any_peer", "call_remote", "reliable")
func _new_game_object_rpc(type: Board.GameObjectType, properties: Dictionary) -> void:
    var c: GameObject
    c = _instantiate_by_type(type).new()
    c.board = self
    c.object_type = type
    for prop: String in properties:
        c.set(prop, properties[prop])
    _board_objects.add_child(c)
    c.set_multiplayer_authority(multiplayer.get_remote_sender_id())
    return

func run_action(action: int) -> void:
    game.run_action(game.get_actions()[action])

func _set_player_id() -> void:
    var full_array: PackedInt32Array = PackedInt32Array(multiplayer.get_peers())
    full_array.append(multiplayer.get_unique_id())
    number_of_players = full_array.size()
    full_array.sort()
    player_id = full_array.find(multiplayer.get_unique_id())
    print("My player ID is: ",player_id, "!")

func _ready() -> void:
    _set_player_id()
    
    _board_player.board = self
    _highlights.board = self

    _background_sprite = Sprite2D.new()
    _background_sprite.z_index = -10
    add_child(_background_sprite)
    
    get_viewport().set_physics_object_picking(true)
    get_viewport().set_physics_object_picking_sort(true)

    game.add_board(self)
    _is_ready.rpc_id(1, multiplayer.get_unique_id())

@rpc("any_peer","call_local","reliable")
func _is_ready(id: int) -> void:
    if multiplayer.is_server():
        _ready_players.append(id)
        if _ready_players.size() == multiplayer.get_peers().size() + 1:
            game.game_start()
            _game_load_finished.rpc()

@rpc("authority", "call_local", "unreliable")
func _game_percent_loaded(pc: float) -> void:
    get_tree().get_root().game_percent_loaded.emit(pc)

@rpc("authority", "call_local", "reliable")
func _game_load_finished() -> void:
    get_tree().get_root().game_load_finished.emit(self)

@rpc("authority", "call_local", "reliable")            
func _game_load_started() -> void:
    get_tree().get_root().game_load_started.emit()

func _on_sync_timer_timeout() -> void:
    property_sync.emit()
