extends Control

func _ready() -> void:
    if not GlobalBridge.global.HasSetup:
        GlobalBridge.global.Setup()
    if not GlobalBridge.global.IsDesktopPlatform():
        %Quit.hide()
    # if Global.is_mobile_platform():
        # %Tabletops.hide()
        # %Settings.hide()
    GlobalBridge.global.LoadThisGame = PackedByteArray([])
    randomize()
    %Splash.text = GlobalBridge.global.SPLASHES[randi_range(0, len(GlobalBridge.global.SPLASHES) - 1)]
    if multiplayer.multiplayer_peer is WebRTCMultiplayerPeer:
        multiplayer.multiplayer_peer.close()
        multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func _on_new_game_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/ui/pages/new_game.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()

func _on_settings_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/ui/pages/settings.tscn")

func _on_tabletops_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/ui/pages/config_editor.tscn")

func _on_about_pressed() -> void:
    $FadeRect.scene_transition.emit("res://src/scenes/ui/pages/about.tscn")
