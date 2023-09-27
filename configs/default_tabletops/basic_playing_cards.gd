# basic_playing_cards.gd
# Copyright Ryanabx 2023
extends TabletopGame

const BASE_SCALE: float = 64.0
const CARD_SIZE: Vector2 = Vector2(2.5 * BASE_SCALE, 3.5 * BASE_SCALE)
const HAND_SIZE: Vector2 = Vector2(8 * BASE_SCALE, 3.5 * BASE_SCALE)

const SUITS: Array[String] = [
    "hearts", "spades", "clubs", "diamonds"
]

const TYPES: Array[String] = [
    "2", "3", "4", "5", "6", "7", "8", "9", "10",
    "jack", "queen", "king", "ace"
]

const SPECIAL_CARDS: Array[String] = [
    "red_joker", "black_joker"
]

var hand_position: Vector2

# MUST IMPLEMENT

## Called when the board wants the game to start. Should be used to create all the initial game objects.
## NOTE: MUST be implemented by the configuration creator.
func game_start() -> void:
    var num_players: int = board.number_of_players
    var extent: float = 6 + num_players
    board.size = Vector2.ONE * extent * 2 * BASE_SCALE
    hand_position = Vector2(0 * BASE_SCALE, (extent - 3) * BASE_SCALE)
    board.background = "bg"
    _create_hands()
    _create_deck_of_cards()

# OPTIONAL

## Returns the list of user actions.
## This method may be optionally overridden. By default returns an empty [Array]
func get_actions() -> Array[String]:
    var res: Array[String] = [
        "Reset Board",
        "Make 52 card deck",
        "Make 54 card deck (Include Jokers)"
    ]
    return res

## Runs a specified action based off the action string, retrieved from get_actions()
## should return true if the action was successful, false otherwise.
## This method may be optionally overridden. By default returns [false]
func run_action(action: String) -> bool:
    match action:
        "Reset Board":
            board.clear_board()
            _create_hands()
            _create_deck_of_cards()
        "Make 52 card deck":
            _create_deck_of_cards()
        "Make 54 card deck (Include Jokers)":
            _create_deck_of_cards(true)
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

func _create_hands() -> void:
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
                "size_pieces": CARD_SIZE,
                "size_option": Hand.SizeOption.GROW_FIXED
            }
        )

func _create_deck_of_cards(with_jokers: bool = false) -> void:
    var deck: Deck = board.new_game_object(
        Board.GameObjectType.DECK,
        {
            "position": Vector2.ZERO,
            "size": CARD_SIZE,
            "face_up": false
        }
    )
    
    for face in TYPES:
        for suit in SUITS:
            var pc: Piece = board.new_game_object(
                board.GameObjectType.FLAT,
                {
                    "image_up": "%s_of_%s" % [face,suit],
                    "image_down": "back",
                    "size": CARD_SIZE,
                    "types": [face, suit]
                }
            )
            deck.add_piece(pc)
    
    if with_jokers:
        for jokers in SPECIAL_CARDS:
            var pc: Piece = board.new_game_object(
                board.GameObjectType.FLAT,
                {
                    "image_up": jokers,
                    "image_down": "back",
                    "size": CARD_SIZE
                }
            )
            deck.add_piece(pc)

    deck.shuffle()
