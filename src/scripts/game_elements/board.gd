class_name Board
extends Node2D

# Tabletop Game Loaded
var game: TabletopGame = null

var size: Vector2 = Vector2.ONE

var def_font: Font = null

enum GameObjectType {
    PIECE,
    DECK,
    HAND,
    MAX
}

const GAME_OBJECT_TYPE_STRING = [
    "piece", "deck", "hand", "max"
]

# Children
@onready var board_player: BoardPlayer = $BoardPlayer
@onready var board_objects: Node2D = $BoardObjects
@onready var highlights: Node2D = $Highlights

var number_of_players: int

var background_sprite: Sprite2D

# Board properties
var background: String = "":
    set(val):
        background = val
        background_sprite.set_texture(game.get_images()[background])
        background_sprite.scale = border.size / background_sprite.texture.get_size()
    get:
        return background

var border: Rect2 = Rect2(0,0,0,0)

var counter: int = 0

func _draw() -> void:
    draw_board_bg()


func get_image(path: String) -> Texture2D:
    if game == null:
        return null
    if game.get_images() == null:
        return null
    if not path in game.get_images():
        return null
    return game.get_images()[path]

## Draw the background specified
func draw_board_bg() -> void:
    draw_rect(border, Color.WHITE, false, Globals.OUTLINE_THICKNESS)

func get_piece(n: String) -> Piece:
    var pc: Piece = board_objects.get_node_or_null(n)
    return pc

func get_pieces(a: Array) -> Array[Piece]:
    var pcs: Array[Piece] = []
    for _a: String in a:
        var pc: Piece = get_piece(_a)
        if pc != null:
            pcs.append(pc)
    return pcs

func get_collection(n: String) -> Collection:
    var c: Collection = board_objects.get_node_or_null(n)
    return c

func get_collections(a: Array) -> Array[Collection]:
    var cs: Array[Collection] = []
    for _a: String in a:
        var c: Collection = get_collection(_a)
        if c != null:
            cs.append(c)
    return cs

func get_gobject(n: String) -> GameObject:
    var o: GameObject = board_objects.get_node_or_null(n)
    if o == null or o.get_parent() != board_objects:
        return null
    return o

func get_game_objects() -> Array[GameObject]:
    var res: Array[GameObject] = []
    res.assign(board_objects.get_children())
    return res

func clear_board() -> void:
    for obj: GameObject in get_game_objects():
        obj.authority = multiplayer.get_unique_id()
        obj.erase_self.rpc(true)

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
    

####################
### Main process ###
####################

func _process(_delta: float) -> void:
    clamp_camera()
    queue_redraw()

## Self explanatory
func clamp_camera() -> void:
    get_parent().camera_controller.position = get_parent().camera_controller.position.clamp(border.position, border.end)

########################
### Multiplayer sync ###
########################

var ready_players: Array = []

#####################
### RPC functions ###
#####################
func instantiate_by_type(type: GameObjectType) -> GDScript:
    match type:
        GameObjectType.PIECE:
            return Piece
        GameObjectType.DECK:
            return Deck
        GameObjectType.HAND:
            return Hand
    print("WARNING: None of the above types specified")
    return GameObject

## Creates new game object on the board
func new_game_object(type: GameObjectType, properties: Dictionary) -> GameObject:
    var c: GameObject
    if not "name" in properties:
        properties.name = "%d_%s_%d" % [multiplayer.get_unique_id(),GAME_OBJECT_TYPE_STRING[type],counter]
        counter += 1
    c = instantiate_by_type(type).new()
    c.board = self
    for prop: String in properties:
        c.set(prop, properties[prop])
    board_objects.add_child(c)
    # RPC
    _new_game_object_rpc.rpc(type, properties)
    print(c.name)
    c.set_multiplayer_authority(multiplayer.get_unique_id())
    return c

@rpc("any_peer", "call_remote", "reliable")
func _new_game_object_rpc(type: GameObjectType, properties: Dictionary) -> void:
    var c: GameObject
    c = instantiate_by_type(type).new()
    c.board = self
    for prop: String in properties:
        c.set(prop, properties[prop])
    board_objects.add_child(c)
    c.set_multiplayer_authority(multiplayer.get_remote_sender_id())
    return

####################
### Config stuff ###
####################

func run_action(action: int) -> void:
    game.run_action(game.get_actions()[action])

func set_player_id() -> void:
    var full_array: PackedInt32Array = PackedInt32Array(multiplayer.get_peers())
    full_array.append(multiplayer.get_unique_id())
    number_of_players = full_array.size()
    full_array.sort()
    Globals.Player.ID = full_array.find(multiplayer.get_unique_id())
    print("My player ID is: ",Globals.Player.ID, "!")

## Called when the board is initialized
func _ready() -> void:
    set_player_id()
    
    board_player.board = self
    highlights.board = self

    SignalManager.run_action.connect(run_action)

    background_sprite = Sprite2D.new()
    background_sprite.z_index = -10
    add_child(background_sprite)
    
    get_viewport().set_physics_object_picking(true)
    get_viewport().set_physics_object_picking_sort(true)

    game.add_board(self)
    is_ready.rpc_id(1, multiplayer.get_unique_id())
    def_font = ThemeDB.fallback_font

@rpc("any_peer","call_local","reliable")
func is_ready(id: int) -> void:
    if multiplayer.is_server():
        ready_players.append(id)
        if ready_players.size() == multiplayer.get_peers().size() + 1:
            game.game_start()
            game_load_finished.rpc()

@rpc("authority", "call_local", "unreliable")
func game_percent_loaded(pc: float) -> void:
    SignalManager.game_percent_loaded.emit(pc)

@rpc("authority", "call_local", "reliable")
func game_load_finished() -> void:
    SignalManager.game_load_finished.emit(self)

@rpc("authority", "call_local", "reliable")            
func game_load_started() -> void:
    SignalManager.game_load_started.emit()


func _on_sync_timer_timeout() -> void:
    SignalManager.property_sync.emit()
