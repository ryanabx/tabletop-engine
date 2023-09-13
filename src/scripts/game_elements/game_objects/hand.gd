class_name Hand
extends Collection

enum VisibilitySetting {
    ALL_PLAYERS,
    DESIGNATED_PLAYERS,
    NOT_DESIGNATED_PLAYERS,
    NO_PLAYERS
}

# Shareable properties
var visibility: VisibilitySetting = VisibilitySetting.DESIGNATED_PLAYERS
var designated_players: Array[int] = []

func get_shareable_properties() -> Array:
    return super.get_shareable_properties() + ["visibility", "designated_players"]

