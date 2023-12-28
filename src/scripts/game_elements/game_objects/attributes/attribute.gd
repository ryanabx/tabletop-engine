class_name Attribute
extends RefCounted

var obj: GameObject

## Attribute Name
func name() -> String: return "attribute"

## Attribute properties
func shareable_properties() -> Array[String]: return []

func _set(property: StringName, value: Variant) -> bool:
    if "%s::%s" % [name(), property] in shareable_properties():
        obj.add_to_property_changes("%s::%s" % [name(), property], value)
    return false