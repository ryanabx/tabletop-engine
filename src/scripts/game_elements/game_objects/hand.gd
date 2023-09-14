class_name Hand
extends Collection

enum VisibilitySetting {
    ALL_PLAYERS,
    DESIGNATED_PLAYERS,
    NOT_DESIGNATED_PLAYERS,
    NO_PLAYERS
}

enum SizeOption {
    FIXED_LAYER,
    FIXED_RESIZE,
    GROW_FIXED,
    GROW_UNLIMITED
}

# Shareable properties
var visibility: VisibilitySetting = VisibilitySetting.DESIGNATED_PLAYERS
var designated_players: Array[int] = []
var size_option: SizeOption = SizeOption.FIXED_LAYER

func get_shareable_properties() -> Array:
    return super.get_shareable_properties() + ["visibility", "designated_players"]

func _draw() -> void:
    match size_option:
        SizeOption.FIXED_LAYER: _draw_fixed()

func _draw_fixed() -> void:
    pass

func _process(delta: float) -> void:
    queue_redraw()
    super._process(delta)