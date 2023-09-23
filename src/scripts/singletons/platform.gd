class_name Platform
extends Node

static func is_desktop_platform() -> bool:
    return [
        "Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"
    ].has(OS.get_name())

static func is_web_platform() -> bool:
    return [
        "Web"
    ].has(OS.get_name())

static func is_mobile_platform() -> bool:
    return [
        "iOS", "Android"
    ].has(OS.get_name())