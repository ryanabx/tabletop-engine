# uno.gd
# Copyright Ryanabx 2023
extends TabletopGame

const START_HAND: int = 7

const BASE_SIZE: float = 64.0
const HAND_SIZE: Vector2 = Vector2(8 * BASE_SIZE, 3.5 * BASE_SIZE)
const SIZE_PIECE: Vector2 = Vector2(2.5 * BASE_SIZE, 3.5 * BASE_SIZE)

const COLORS: Array[String] = [
    "RED", "BLUE", "YELLOW", "GREEN"
]
const CARD_TYPES: Array[String] = [
    "0", "1", "2", "3", "4", "5", "6",
    "7", "8", "9", "DRAW2", "SKIP", "TURN"
]
const SPECIAL_CARDS: Array[String] = [
    "DRAW4", "WILD"
]
const ACTION_LIST: Array[String] = [
    "Restart Game"
]

var hand_position: Vector2

func initialize() -> void:
    var num_players: int = board.number_of_players
    var extent: float = 6 + num_players
    board.size = Vector2.ONE * extent * 2 * BASE_SIZE
    hand_position = Vector2(0 * BASE_SIZE, (extent - 3) * BASE_SIZE)
    board.background = "images/bg"

func game_start() -> void:
    _create_cards()
    _deal_cards()

func get_actions() -> Array[String]:
    return ACTION_LIST

func run_action(action: String) -> bool:
    match action:
        "Restart Game":
            board.clear_board()
            await board.get_tree().create_timer(0.1).timeout
            _create_cards()
            _deal_cards()
            return true
    # Not a valid action
    return false

func can_stack(from: Selectable, to: Selectable) -> bool:
    if to.name != "PLACE_PILE" or (to is Collection and to.get_inside().is_empty()):
        return true
    var types_1: Array = to.get_inside().back().types
    var types_2: Array = from.types

    if "WILD" in types_1 or "WILD" in types_2\
    or "DRAW4" in types_1 or "DRAW4" in types_2:
        return true
    
    for type: String in types_1:
        if type in types_2:
            return true
    
    return false

func can_highlight(_highlighted: Selectable, _selected: Selectable) -> bool:
    if _selected == null:
        return true
    return can_stack(_selected, _highlighted)

func _create_cards() -> void:
    var draw_pile: Collection = board.new_game_object(
        board.GameObjectType.DECK,
        {
            "name": "DRAW_PILE",
            "position": Vector2(-1.5 * BASE_SIZE, 0 * BASE_SIZE),
            "size": Vector2(2.5 * BASE_SIZE, 3.5 * BASE_SIZE),
            "rotation": 0.0,
            "permanent": true,
            "lock_state": true,
            "face_up": false
        }
    )
    for color in COLORS:
        for type in CARD_TYPES:
            for i in range(2):
                var pc: Piece = board.new_game_object(
                    board.GameObjectType.FLAT,
                    {
                        "face_up": false,
                        "image_up": str("images/UNO_",color,type),
                        "image_down": "images/UNO_FLIPPED",
                        "size": Vector2(2.5 * BASE_SIZE, 3.5 * BASE_SIZE),
                        "rotation": 0.0,
                        "types": [color, type],
                        "view_override": Flat.ViewOverrideType.IF_SELECTED
                    }
                )
                draw_pile.add_piece(pc)
                
    for type in SPECIAL_CARDS:
        for i in range(4):
            var pc: Piece = board.new_game_object(
                board.GameObjectType.FLAT,
                {
                    "face_up": false,
                    "image_up": str("images/UNO_",type),
                    "image_down": "images/UNO_FLIPPED",
                    "size": Vector2(2.5 * BASE_SIZE, 3.5 * BASE_SIZE),
                    "rotation": 0.0,
                    "types": [type],
                    "view_override": Flat.ViewOverrideType.IF_SELECTED
                }
            )
            draw_pile.add_piece(pc)
    board.new_game_object(
        board.GameObjectType.DECK,
        {
            "name": "PLACE_PILE",
            "position": Vector2(1.5 * BASE_SIZE, 0 * BASE_SIZE),
            "size": Vector2(2.5 * BASE_SIZE, 3.5 * BASE_SIZE),
            "rotation": 0.0,
            "permanent": true,
            "lock_state": true,
            "face_up": true
        }
    )

    for i in range(board.number_of_players):
        var player: int = i + 1
        var angle: float = (float(i) / board.number_of_players) * 2.0 * PI
        board.new_game_object(
            board.GameObjectType.HAND,
            {
                "name": str("PLAYER_",player,"_HAND"),
                "position": hand_position.rotated(angle),
                "rotation": angle,
                "size": HAND_SIZE,
                "lock_state": true,
                "face_up": false,
                "visibility": Hand.VisibilitySetting.DESIGNATED,
                "designated_players": [player],
                "size_pieces": SIZE_PIECE,
                "size_option": Hand.SizeOption.GROW_FIXED
            }
        )

func _deal_cards() -> void:
    board.get_object("DRAW_PILE").shuffle()
    board.move_piece(board.get_object("DRAW_PILE"), board.get_object("PLACE_PILE"))
    for p in range(board.number_of_players):
        var hand: String = str("PLAYER_",(p + 1),"_HAND")
        for i in range(START_HAND):
            board.move_piece(board.get_object("DRAW_PILE"), board.get_object(hand))