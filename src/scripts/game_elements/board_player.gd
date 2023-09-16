class_name BoardPlayer
extends Node2D

var selected_object: Selectable = null
var queued_object: Selectable = null

var grab_position: Vector2 = Vector2.ZERO

var board: Board

var hold_timer: Timer

var physics_state: PhysicsDirectSpaceState2D

var select_index: int = -1

var input_events: Dictionary = {}

func _ready() -> void:
    physics_state = get_world_2d().get_direct_space_state()
    hold_timer = Timer.new()
    hold_timer.wait_time = 0.5
    hold_timer.timeout.connect(_hold_timer_timeout)
    add_child(hold_timer)

func _hold_timer_timeout() -> void:
    if collection_queued():
        _select_collection(get_queued_object())

######################
### Getter Methods ###
######################

func get_selected_object() -> Selectable:
    return selected_object

func get_queued_object() -> Selectable:
    return queued_object

func is_selecting() -> bool:
    return selected_object != null

func object_queued() -> bool:
    return queued_object != null

func is_selecting_piece() -> bool:
    return selected_object != null and selected_object is Piece

func piece_queued() -> bool:
    return queued_object != null and queued_object is Piece

func is_selecting_collection() -> bool:
    return selected_object != null and selected_object is Collection

func collection_queued() -> bool:
    return queued_object != null and queued_object is Collection

######################
### Input Handling ###
######################

func _input(event: InputEvent) -> void:
    var ev: InputEvent = make_input_local(event)
    if ev.is_action_pressed("game_flip"):
        if is_selecting() and not get_selected_object().lock_state:
            get_selected_object().face_up = not get_selected_object().face_up
    if ev is InputEventScreenTouch:
        touch_input(ev)
    elif ev is InputEventScreenDrag:
        drag_input(ev)
    
func touch_input(event: InputEvent) -> void:
    if event.pressed:
        input_events[event.index] = event
    else:
        input_events.erase(event.index)
    
    if event.double_tap == false:
        single_tap_input(event)
    elif input_events.size() == 1:
        double_tap_input(event)

func single_tap_input(event: InputEvent) -> void:
    var params: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
    params.position = get_local_mouse_position()
    params.collide_with_areas = true
    params.collide_with_bodies = false
    params.collision_mask = 1
    if event.pressed and input_events.size() == 1:
        # print("Tap Pressed")
        grab_position = event.position
        var results: Array[Dictionary] = physics_state.intersect_point(params, 65535)
        if results.size() > 0:
            results.sort_custom(compare_by_z_index)
            select_index = event.index
            results[0].collider.get_parent()._on_select(event)
    elif not event.pressed and event.index == select_index:
        # print("Tap Released")
        call_deferred("deselect")
        if is_selecting():
            var results: Array[Dictionary] = physics_state.intersect_point(params, 65535)
            if results.size() > 0:
                results.sort_custom(compare_by_z_index)
                print(results[0].collider.get_parent().get_name())
                results[0].collider.get_parent()._on_deselect(event)

func double_tap_input(event: InputEvent) -> void:
    if event.pressed:
        # print("Double tap")
        var params: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
        params.position = get_local_mouse_position()
        params.collide_with_areas = true
        params.collide_with_bodies = false
        params.collision_mask = 1
        var results: Array[Dictionary] = physics_state.intersect_point(params, 65535)
        if not results.is_empty():
            results.sort_custom(compare_by_z_index)
            if results[0].collider.get_parent() is Collection:
                SignalManager.game_menu_create_collection.emit(results[0].collider.get_parent())
            elif results[0].collider.get_parent() is Piece:
                SignalManager.game_menu_create_piece.emit(results[0].collider.get_parent())
            deselect()


func drag_input(event: InputEvent) -> void:
    input_events[event.index] = event
    if select_index != event.index:
        return
    if object_queued() and event.position.distance_to(grab_position) > Globals.GRAB_THRESHOLD:
        hold_timer.stop()
        if collection_queued() and board.game.can_take_piece_off(get_queued_object()):
            var pc: Piece = get_queued_object().remove_from_top(get_queued_object().to_local(grab_position))
            # pc.position = get_queued_object().position
            # pc.rotation = get_queued_object().rotation
            select_object(pc)
        elif piece_queued():
            select_object(get_queued_object())
    move_objects_to(event.position)

func move_objects_to(pos: Vector2) -> void:
    if is_selecting():
        get_selected_object().position = (pos - get_selected_object().grab_offset).clamp(board.border.position, board.border.end)

func compare_by_z_index(a: Dictionary, b: Dictionary) -> bool:
    return a.collider.get_parent().index > b.collider.get_parent().index

## Shuffles objects
func shuffle(pcs: Array[Piece]) -> void:
    var pcs_shuffled: Array[Piece] = pcs.duplicate(false)
    pcs_shuffled.shuffle()
    for i: int in range(pcs.size()):
        var pc1: Piece = pcs[i]
        var pc2: Piece = pcs_shuffled[i]
        var contents1: Dictionary = {
            "position": pc1.position,
            "rotation": pc1.rotation,
            "index": pc1.index,
            "collection": pc1.collection
        }
        var contents2: Dictionary = {
            "position": pc2.position,
            "rotation": pc2.rotation,
            "index": pc2.index,
            "collection": pc2.collection
        }
        _swap(pc1, contents2)
        _swap(pc2, contents1)

func _swap(pc1: Piece, contents: Dictionary) -> void:
    pc1.position = contents.position
    pc1.rotation = contents.rotation
    pc1.index = contents.index
    if pc1.collection != contents.collection:
        contents.collection.add_piece(pc1)

######################
### Main Processes ###
######################

func select_object(obj: Selectable) -> void:
    deselect()
    obj.authority = multiplayer.get_unique_id()
    obj.move_self_to_top()
    selected_object = obj
    obj.selected = true
    obj.grab_offset = grab_position - obj.position

func queue_select_object(obj: Selectable) -> void:
    deselect()
    obj.move_self_to_top()
    queued_object = obj
    hold_timer.start()

func stack_selection_to_item(item: Selectable) -> void:
    item.authority = multiplayer.get_unique_id()
    if item is Collection:
        stack_on_collection(item)
    elif item is Piece:
        stack_on_piece(item)
    deselect()

func stack_on_collection(item: Collection) -> void:
    if is_selecting_piece():
        item.add_piece(get_selected_object())
    elif is_selecting_collection():
        item.inside.append_array(get_selected_object().inside)
        item.add_to_property_changes("inside",item.inside)
        get_selected_object().clear_inside()

func stack_on_piece(item: Piece) -> void:
    if is_selecting_collection():
        get_selected_object().position = item.position
        get_selected_object().add_piece(item, true)
    elif is_selecting_piece():
        var collection: Collection = board.new_game_object(
            Board.GameObjectType.DECK,
            {
                "name": board.unique_name("newcoll"),
                "position": item.position,
                "rotation": item.rotation
            }
        )
        collection.add_piece(get_selected_object())
        collection.add_piece(item)

func _select_collection(collection: Collection) -> void:
    if collection is Hand or collection.permanent:
        var new_collection: Collection = collection.board.new_game_object(
            Board.GameObjectType.DECK,
            {
                "name": collection.board.unique_name("newcoll"),
                "position": collection.position,
                "rotation": collection.rotation,
                "face_up": collection.face_up
            }
        )
        new_collection.inside = collection.inside
        new_collection.add_to_property_changes("inside", new_collection.inside)
        
        collection.clear_inside()
        collection = new_collection
    grab_position = collection.position
    select_object(collection)
    collection.grab_offset = Vector2.ZERO

func deselect() -> void:
    hold_timer.stop()
    deselect_object()
    dequeue_object()

func deselect_object() -> void:
    if is_selecting():
        get_selected_object().selected = false
    selected_object = null

func dequeue_object() -> void:
    if object_queued():
        get_queued_object().selected = false
        queued_object = null

func rotate_selection(amount: float, axis: float) -> void:
    var obj: Selectable = get_selected_object()
    if not is_instance_valid(obj):
        return
    obj.rotation += amount
    if absf(axis) < 0.1 and absf(roundf(obj.rotation_degrees / 45.0) * 45.0 - obj.rotation_degrees) < 7.5:
        obj.rotation_degrees = roundf(obj.rotation_degrees / 45.0) * 45.0
