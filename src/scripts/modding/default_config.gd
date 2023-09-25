extends TabletopGame

const BASE_SIZE: float = 96

const PIECE_SIZE: Vector2 = BASE_SIZE * Vector2.ONE * 3

func _init() -> void:
    pass

func settings() -> Dictionary:
    return {
        "max_players": 1,
        "min_players": 1
    }

func export_settings() -> Dictionary:
    return {
        "name":"Default Config",
        "schema_version": 1,
        "game_version": 1,
        "include_folders": [],
        "include_types": [],
        "include_image_folders": ["images"],
        "include_image_types": [".svg"]
    }

func add_board(_board: Board) -> void:
    self.board = _board
    board.size = Vector2(20 * BASE_SIZE, 20 * BASE_SIZE)

func game_start() -> void:
    board.clear_board()
    var draw_pile: Collection = board.new_game_object(
        board.GameObjectType.DECK,
        {
            "name": "DRAW_PILE",
            "position": Vector2.ZERO * BASE_SIZE,
            "size": Vector2.ONE * BASE_SIZE,
            "permanent": true,
            "lock_state": true,
            "face_up": false
        }
    )

    var place_pile: Collection = board.new_game_object(
        board.GameObjectType.DECK,
        {
            "name": "PLACE_PILE",
            "position": Vector2.ONE * 2 * BASE_SIZE,
            "size": PIECE_SIZE,
            "permanent": true,
            "lock_state": true,
            "face_up": true
        }
    )

    for i in range(20):
        var pc: Piece = board.new_game_object(
            board.GameObjectType.FLAT,
            {
                "size": PIECE_SIZE,
                "image_up": "images/icon.svg",
                "image_down": "images/icon.svg",
                "face_up": false
            }
        )
        draw_pile.add_piece(pc)
    
    for i in range(20):
        var pc: Piece = board.new_game_object(
            board.GameObjectType.FLAT,
            {
                "size": PIECE_SIZE,
                "image_up": "images/icon.svg",
                "image_down": "images/icon.svg",
                "face_up": false
            }
        )
        place_pile.add_piece(pc)
    
    board.new_game_object(
        board.GameObjectType.HAND,
        {
            "size": Vector2(BASE_SIZE * 8, PIECE_SIZE.y),
            "position": Vector2(0, 8 * BASE_SIZE),
            "size_pieces": PIECE_SIZE
        }
    )