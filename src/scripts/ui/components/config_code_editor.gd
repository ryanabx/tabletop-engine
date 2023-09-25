extends CodeEdit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    code_completion_prefixes = PackedStringArray([
        "."
    ])
    code_completion_enabled = true
    print(code_completion_prefixes)


func _on_code_completion_requested():   
    for each in function_names:
        add_code_completion_option(CodeEdit.KIND_FUNCTION, each, each+"()", syntax_highlighter.function_color)
    for each in variable_names:
        add_code_completion_option(CodeEdit.KIND_VARIABLE, each, each)
    update_code_completion_options(true)
    changed = true


func _on_symbol_lookup(symbol:String, line:int, column:int) -> void:
    print("Symbol lookup")
