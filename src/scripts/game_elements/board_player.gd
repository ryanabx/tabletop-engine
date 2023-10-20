class_name BoardPlayer
extends Node2D

var selected_object: Selectable = null
var queued_object: Selectable = null

# var holding_object: bool = false

var grab_position: Vector2 = Vector2.ZERO

var board: Board

var hold_timer: Timer

var physics_state: PhysicsDirectSpaceState2D

var select_index: int = -1

var _taps_since_selecting: int = 0

var input_events: Dictionary = {}

var _highlighted_object: Selectable = null

const POLLING_RATE: int = 2

var _poll_num: int = 0

func _ready() -> void:
    physics_state = get_world_2d().get_direct_space_state()
    hold_timer = Timer.new()
    hold_timer.wait_time = 0.5
    hold_timer.timeout.connect(_hold_timer_timeout)
    add_child(hold_timer)

func _hold_timer_timeout() -> void:
    if collection_queued():
        _select_collection(get_queued_object() as Collection)

######################
### Getter Methods ###
######################

func get_selected_object() -> Selectable:
    return selected_object

func get_queued_object() -> Selectable:
    return queued_object

func get_highlighted_object() -> Selectable:
    return _highlighted_object

func is_selecting() -> bool:
    return selected_object != null and is_instance_valid(selected_object)

func object_queued() -> bool:
    return queued_object != null and is_instance_valid(queued_object)

func is_selecting_piece() -> bool:
    return is_selecting() and selected_object is Piece

func piece_queued() -> bool:
    return object_queued() and queued_object is Piece

func is_selecting_collection() -> bool:
    return is_selecting() and selected_object is Collection

func collection_queued() -> bool:
    return object_queued() and queued_object is Collection

func is_highlighting() -> bool:
    return _highlighted_object != null and is_instance_valid(_highlighted_object)

######################
### Input Handling ###
######################

func _input(event: InputEvent) -> void:
    if board.input_mode == Board.InputMode.CAMERA:
        input_events = {}
        deselect()
        return
    var ev: InputEvent = make_input_local(event)
    if ev is InputEventMouseMotion or (ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT):
        _update_highlighted(ev)
    if ev.is_action_pressed("game_flip"):
        if is_selecting() and not get_selected_object().lock_state:
            if get_selected_object() is Flat:
                (get_selected_object() as Flat).face_up = not (get_selected_object() as Flat).face_up
            elif get_selected_object() is Deck:
                (get_selected_object() as Deck).face_up = not (get_selected_object() as Deck).face_up
    if ev is InputEventScreenTouch:
        touch_input(ev as InputEventScreenTouch)
    elif ev is InputEventScreenDrag:
        drag_input(ev as InputEventScreenDrag)

func _update_highlighted(event: InputEvent) -> void:
    if board.touch_type == Board.TouchType.DRAG and event is InputEventMouseButton:
        return
    if board.touch_type == Board.TouchType.TAP and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        _highlighted_object = null
        return
    
    if _poll_num == 0 or event is InputEventMouseButton:
        _highlighted_object = _get_collider_at_position()
        if _highlighted_object != null and not board.game.can_highlight(_highlighted_object, selected_object):
            _highlighted_object = null
    _poll_num = (_poll_num + 1) % POLLING_RATE
    
func touch_input(event: InputEventScreenTouch) -> void:
    if event.pressed:
        input_events[event.index] = event
    else:
        input_events.erase(event.index)
    if select_index != -1 and event.index != select_index and input_events.size() > 1:
        return
    if event.pressed:
        _taps_since_selecting += 1
        print("Tapped since selecting!")
    if event.double_tap == false:
        single_tap_input(event)
    elif input_events.size() == 1:
        double_tap_input(event)

func single_tap_input(event: InputEventScreenTouch) -> void:
    if event.pressed and input_events.size() == 1: # Tap pressed
        print("Tap Pressed: ", board.touch_type)
        if board.touch_type == Board.TouchType.DRAG:
            tap_pressed_drag(event)
        elif board.touch_type == Board.TouchType.TAP:
            tap_pressed_tap(event)
    elif not event.pressed: # Tap released
        print("Tap Released: ", board.touch_type)
        if board.touch_type == Board.TouchType.DRAG and event.index == select_index:
            tap_released_drag(event)
        elif board.touch_type == Board.TouchType.TAP:
            tap_released_tap(event)

func tap_pressed_drag(event: InputEventScreenTouch) -> void:
    _select_with_event(event)

func tap_released_drag(event: InputEventScreenTouch) -> void:
    if is_selecting():
        _deselect_with_event(event)
    hold_timer.stop()

func tap_pressed_tap(event: InputEventScreenTouch) -> void:
    print("Tap pressed tap")
    if object_queued():
        if _get_collider_at_position(get_local_mouse_position(), 1) != get_queued_object():
            deselect()
        else:
            print("Hold timer started")
            grab_position = event.position
            hold_timer.start()

func tap_released_tap(event: InputEventScreenTouch) -> void:
    print("Tap released tap")
    if not is_selecting() and not object_queued():
        print("Select with event")
        _select_with_event(event)
    elif is_selecting() and _get_collider_at_position(get_local_mouse_position(), 2) != get_selected_object():
        _deselect_with_event(event)
    elif object_queued() and _get_collider_at_position() != get_queued_object():
        deselect()
    hold_timer.stop()

func _select_with_event(event: InputEventScreenTouch) -> void:
    var collider: Selectable = _get_collider_at_position()
    if collider != null:
        grab_position = event.position
        select_index = event.index
        collider._on_select(event)

func _deselect_with_event(event: InputEventScreenTouch) -> void:
    var collider: Selectable = _get_collider_at_position()
    if collider != null:
        collider._on_deselect(event)
    deselect()

func double_tap_input(event: InputEventScreenTouch) -> void:
    if event.pressed:
        if board.touch_type == Board.TouchType.TAP and _taps_since_selecting < 2:
            print("Not a double tap! %d" % _taps_since_selecting)
            return
        # print("Double tap")
        print("Succeeded! %d :: %d" % [_taps_since_selecting, board.touch_type])
        var collider: Selectable = _get_collider_at_position()
        if collider != null:
            if collider is Collection:
                board._create_context_menu.emit(collider as Collection)
            elif collider is Piece:
                board._create_context_menu.emit(collider as Piece)
            deselect()

func _get_collider_at_position(pos: Vector2 = get_local_mouse_position(), collision_mask: int = 1) -> Selectable:
    var params: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
    params.position = pos
    params.collide_with_areas = true
    params.collide_with_bodies = false
    params.collision_mask = 1
    var results: Array[Dictionary] = physics_state.intersect_point(params, 65535)
    if results.size() > 0:
        results.sort_custom(compare_by_z_index)
        var collider: Node = results[0].collider
        return collider.get_parent() as Selectable
    return null

func drag_input(event: InputEventScreenDrag) -> void:
    input_events[event.index] = event
    if select_index != event.index:
        return
    if object_queued() and event.position.distance_to(grab_position) > Global.GRAB_THRESHOLD:
        hold_timer.stop()
        if collection_queued() and board.game.can_take_piece_off(get_queued_object() as Collection):
            var pc: Piece = (get_queued_object() as Collection).remove_from_top(get_queued_object().to_local(grab_position))
            select_object(pc)
        elif piece_queued():
            select_object(get_queued_object())
    move_objects_to(event.position)

func move_objects_to(pos: Vector2) -> void:
    if is_selecting():
        get_selected_object().position = (pos - get_selected_object().grab_offset).clamp(-board.size/2, board.size/2)

func compare_by_z_index(a: Dictionary, b: Dictionary) -> bool:
    var collider_a: Node = a.collider
    var collider_b: Node = b.collider
    return (collider_a.get_parent() as GameObject).index > (collider_b.get_parent() as GameObject).index

######################
### Main Processes ###
######################

func select_object(obj: Selectable) -> void:
    deselect()
    obj._authority = multiplayer.get_unique_id()
    obj.move_self_to_top()
    selected_object = obj
    obj.selected = multiplayer.get_unique_id()
    obj.grab_offset = grab_position - obj.position

func queue_select_object(obj: Selectable) -> void:
    if object_queued():
        deselect()
    if obj.queued == 0 and obj.selected == 0:
        obj._authority = multiplayer.get_unique_id()
        _taps_since_selecting = 0
        print("Taps since selecting = 0")
        obj.move_self_to_top()
        queued_object = obj
        obj.queued = multiplayer.get_unique_id()
        hold_timer.start()

func stack_selection_to_item(item: Selectable) -> void:
    item._authority = multiplayer.get_unique_id()
    if item is Collection:
        stack_on_collection(item as Collection)
    elif item is Piece:
        stack_on_piece(item as Piece)
    deselect()

func stack_on_collection(item: Collection) -> void:
    if is_selecting_piece():
        item.add_piece(get_selected_object() as Piece)
    elif is_selecting_collection():
        item.add_collection(get_selected_object() as Collection)

func stack_on_piece(item: Piece) -> void:
    if is_selecting_collection():
        get_selected_object().position = item.position
        (get_selected_object() as Collection).add_piece(item, true)
    elif is_selecting_piece():
        var is_face_up: bool = true
        if item is Flat:
            is_face_up = (item as Flat).face_up
        var collection: Collection = board.new_game_object(
            Board.GameObjectType.DECK,
            {
                "position": item.position,
                "rotation": item.rotation,
                "face_up": is_face_up
            }
        )
        collection.add_piece(item)
        collection.add_piece(get_selected_object() as Piece)

func _select_collection(collection: Collection) -> void:
    if collection is Hand or (collection as Deck).permanent:
        var new_collection: Collection = collection.board.new_game_object(
            Board.GameObjectType.DECK,
            {
                "position": collection.position,
                "rotation": collection.rotation,
                "face_up": collection.face_up
            }
        )
        new_collection.inside = collection.inside
        new_collection.add_to_property_changes("inside", new_collection.inside)
        
        collection._clear_inside()
        collection = new_collection
    grab_position = collection.position
    select_object(collection)
    collection.grab_offset = Vector2.ZERO

func deselect() -> void:
    hold_timer.stop()
    deselect_object()
    dequeue_object()

func deselect_object() -> void:
    if is_selecting() and get_selected_object().selected == multiplayer.get_unique_id():
        get_selected_object()._authority = multiplayer.get_unique_id()
        get_selected_object().selected = 0
        selected_object = null

func dequeue_object() -> void:
    if object_queued() and get_queued_object().queued == multiplayer.get_unique_id():
        _taps_since_selecting = 0
        print("Taps since selecting = 0")
        get_queued_object()._authority = multiplayer.get_unique_id()
        get_queued_object().queued = 0
        queued_object = null

func rotate_selection(amount: float, axis: float) -> void:
    var obj: Selectable = get_selected_object()
    if not is_instance_valid(obj):
        return
    obj.rotation += amount
    if absf(axis) < 0.1 and absf(roundf(obj.rotation_degrees / 45.0) * 45.0 - obj.rotation_degrees) < 7.5:
        obj.rotation_degrees = roundf(obj.rotation_degrees / 45.0) * 45.0
