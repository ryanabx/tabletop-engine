class_name Flat
extends Piece
## flat.gd
## 
## Defines a piece that can be flipped (has 2 sides)

# Private variables

@onready var _sprite: Sprite2D

## View override types. See [member view_override]
enum ViewOverrideType {
    ALL,
    IF_SELECTED,
    IF_NOT_SELECTED,
    NONE
}

## Optional view override for flat objects.
## [member ALL] means every player can view, even if its face down.
## [member IF_SELECTED] means if a player is selecting it, they can view it.
## [member IF_NOT_SELECTED] means if a player isn't selecting it, they can see it.
## [member NONE] means default behavior.
var view_override: ViewOverrideType = ViewOverrideType.NONE

## The image string for the face up side of the flat object.
var image_up: String = ""
## The image string for the face down side of the flat object.
var image_down: String = ""

func _refresh_image() -> void:
    if image_up == "" or image_down == "":
        return
    if board == null or board.game == null or board._get_image(image_up) == null or board._get_image(image_down) == null\
        or not is_instance_valid(_sprite):
            return
    
    var ovr: bool = false
    # print("Selected: %d, Queued: %d, ViewOverrideType: %d" % [selected, queued, view_override])
    if view_override == ViewOverrideType.ALL or not get_attribute("selectable"):
        ovr = true
    elif view_override == ViewOverrideType.IF_SELECTED:
        ovr = get_attribute("selectable").selected == multiplayer.get_unique_id() or get_attribute("selectable").queued == multiplayer.get_unique_id()
    elif view_override == ViewOverrideType.IF_NOT_SELECTED:
        ovr = get_attribute("selectable").selected != multiplayer.get_unique_id() or get_attribute("selectable").queued == multiplayer.get_unique_id()
    
    _sprite.texture = board._get_image(image_up) if not get_attribute("flippable") or get_attribute("flippable").face_up or ovr else board._get_image(image_down)
    _sprite.scale = get_attribute("has_shape").size / _sprite.texture.get_size()

func _process(_delta: float) -> void:
    _refresh_image()

func _ready() -> void:
    # Traits
    add_attribute(Flippable.new(self))
    # Sprite stuff
    _sprite = Sprite2D.new()
    add_child(_sprite)
    super._ready()
