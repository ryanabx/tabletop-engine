class_name RightClickMenu
extends PopupMenu

var piece: Piece = null
var collection: Collection = null

var _board: Board = null

func _ready() -> void:
    hide()
    get_tree().get_root().get_node("BoardManager").game_load_finished.connect(_game_load_finished)

func _game_load_finished(board: Board) -> void:
    _board = board
    _board._create_context_menu.connect(_on_menu_created)

func reset_menu() -> void:
    set_position(Vector2.ZERO)
    # Disconnect previously connected signals
    if id_pressed.is_connected(_on_clicked_from_object):
        id_pressed.disconnect(_on_clicked_from_object)
    if id_pressed.is_connected(_on_clicked_from_collection):
        id_pressed.disconnect(_on_clicked_from_collection)
    clear()
    set_position(get_viewport().get_mouse_position())

func _on_menu_created(obj: Selectable) -> void:
    if obj is Piece:
        _on_piece_menu_created(obj as Piece)
    elif obj is Collection:
        _on_collection_menu_created(obj as Collection)

func _on_piece_menu_created(pc: Piece) -> void:
    reset_menu()
    piece = pc
    collection = null
    init_piece_menu()
    reset_size()
    popup()

func _on_collection_menu_created(coll: Collection) -> void:
    reset_menu()
    print("Collection menu created")
    piece = null
    collection = coll
    init_collection_menu()
    reset_size()
    popup()

func init_collection_menu() -> void:
    add_item("Shuffle", 8)
    
    var orientation_menu := PopupMenu.new()
    orientation_menu.add_item("Face up", 5)
    orientation_menu.add_item("Face down", 6)
    orientation_menu.add_item("Flip", 1)
    orientation_menu.name = "orientation"
    add_child(orientation_menu)
    if not collection.lock_state:
        add_submenu_item("Set Orientation", "orientation", 7)
    var ordering_menu := PopupMenu.new()
    ordering_menu.name = "ordering"
    add_child(ordering_menu)
    add_submenu_item("Ordering", "ordering", 2)
    ordering_menu.add_item("Go to front", 3)
    ordering_menu.add_item("Send to back", 4)
    id_pressed.connect(_on_clicked_from_collection)
    ordering_menu.id_pressed.connect(_on_clicked_from_collection)
    orientation_menu.id_pressed.connect(_on_clicked_from_collection)

func init_piece_menu() -> void:
    add_item("Flip object", 0)
    var ordering_menu := PopupMenu.new()
    ordering_menu.name = "ordering"
    add_child(ordering_menu)
    add_submenu_item("Ordering", "ordering", 1)
    ordering_menu.add_item("Bring to front", 2)
    ordering_menu.add_item("Send to back", 3)
    id_pressed.connect(_on_clicked_from_object)
    ordering_menu.id_pressed.connect(_on_clicked_from_object)

# RIGHT CLICK MENU FUNCIONALITIES

func _on_clicked_from_object(id: int) -> void:
    match id:
        0: piece.face_up = not piece.face_up
        2: piece.move_self_to_top()
        3: piece.move_self_to_back()

func _on_clicked_from_collection(id: int) -> void:
    match id:
        1:
            if not collection.lock_state:
                collection.face_up = not collection.face_up
        3: collection.move_self_to_front()
        4: collection.move_self_to_back()
        5:
            if not collection.lock_state:
                collection.face_up = true
        6:
            if not collection.lock_state:
                collection.face_up = false
        8: collection.shuffle()
