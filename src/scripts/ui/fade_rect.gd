extends ColorRect

var fade_in_timer: Timer
var fade_out_timer: Timer
var scene: String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    SignalManager.scene_transition.connect(_on_scene_transition)
    show()
    fade_in_timer = Timer.new()
    fade_out_timer = Timer.new()
    add_child(fade_in_timer)
    add_child(fade_out_timer)
    fade_out_timer.timeout.connect(_on_fade_timer_timeout)
    fade_in_timer.one_shot = true
    fade_out_timer.one_shot = true
    fade_in_timer.wait_time = Globals.TRANSITION_TIME_IN
    fade_out_timer.wait_time = Globals.TRANSITION_TIME_OUT
    fade_in_timer.start()

func _process(_delta: float) -> void:
    if not fade_out_timer.is_stopped():
        color.a = 1.0 - (fade_out_timer.time_left / fade_out_timer.wait_time)
    else:
        color.a = fade_in_timer.time_left / fade_in_timer.wait_time

func _on_scene_transition(_scene: String) -> void:
    scene = _scene
    fade_out_timer.start()
    

func _on_fade_timer_timeout() -> void:
    get_tree().change_scene_to_file(scene)