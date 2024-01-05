class_name FadeRect
extends ColorRect

var fade_in_timer: Timer
var fade_out_timer: Timer
var scene: String = ""

var fade_in_done: bool = false
var fade_out_done: bool = false

signal scene_transition(scn: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    scene_transition.connect(_on_scene_transition)
    show()
    color.a = 1.0
    fade_in_timer = Timer.new()
    fade_out_timer = Timer.new()
    add_child(fade_in_timer)
    add_child(fade_out_timer)
    fade_out_timer.timeout.connect(_on_fade_timer_timeout)
    fade_in_timer.one_shot = true
    fade_out_timer.one_shot = true
    fade_in_timer.wait_time = Global.TRANSITION_TIME_IN
    fade_out_timer.wait_time = Global.TRANSITION_TIME_OUT
    get_tree().create_timer(Global.TRANSITION_TIME_WAIT / 2).timeout.connect(start_fade_timer)
    

func start_fade_timer() -> void:
    fade_in_timer.start()
    fade_in_done = true

func _process(_delta: float) -> void:
    if fade_in_done and not fade_out_done:
        color.a = 1.0 - (fade_out_timer.time_left / fade_out_timer.wait_time) if not fade_out_timer.is_stopped() else \
        fade_in_timer.time_left / fade_in_timer.wait_time
    else:
        color.a = 1.0

func _on_scene_transition(_scene: String) -> void:
    scene = _scene
    fade_out_timer.start()
    

func _on_fade_timer_timeout() -> void:
    fade_out_done = true
    await get_tree().create_timer(Global.TRANSITION_TIME_WAIT / 2).timeout
    get_tree().change_scene_to_file(scene)