extends Control

@onready var version: Label = %VersionNumber
@onready var license: Label = %Licenses

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    version.text = str("Tabletop Engine version ",ProjectSettings.get_setting("application/config/version"))
    license.text = FileAccess.get_file_as_string(Global.LICENSE_FILE)

func _on_submit_feedback_pressed() -> void:
    OS.shell_open("https://github.com/ryanabx/tabletop-engine-info/issues/new")

func _on_docs_pressed() -> void:
    OS.shell_open("https://github.com/ryanabx/tabletop-engine-info/issues/new")

func _on_github_pressed() -> void:
    OS.shell_open("https://github.com/ryanabx/tabletop-engine-info")
