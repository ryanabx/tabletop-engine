extends Node

func _ready() -> void:
	ThemeDB.get_project_theme().default_base_scale = 8.0

func load_images_into_array(image_strings: Array, image_directory: String) -> Array:
	var result: Array = []
	for image_path in image_strings:
		var _image = Image.new()
		var _err = _image.load(image_directory + image_path)
		if _err != OK:
			print("Failed to load image: ",image_directory + image_path)
			return []
		var _texture = ImageTexture.new()
		_texture = ImageTexture.create_from_image(_image)
		result.append(_texture)
	return result

func load_texture_from_string(fname: String, image_directory: String) -> Texture2D:
	var _image = Image.new()
	var _err = _image.load(image_directory + fname)
	if _err != OK:
		print("Failed to load image: ",image_directory + fname)
		return null
	var _texture = ImageTexture.new()
	_texture = ImageTexture.create_from_image(_image)
	return _texture

func rect_with_padding(rct: Rect2, padding: float) -> Rect2:
	return Rect2(rct.position - Vector2(padding, padding), rct.size + Vector2(padding * 2, padding * 2))

func load_json_from_file(fname: String) -> Dictionary:
	if FileAccess.file_exists(fname):
		var data_file = FileAccess.open(fname, FileAccess.READ)
		var parsed_result = JSON.parse_string(data_file.get_as_text())
		if parsed_result is Dictionary:
			return parsed_result
		else:
			print("Error parsing file: ",fname)
			return {}
	else:
		print("File not found: ",fname)
		return {}

func load_images_from_directory(dir: String) -> Dictionary:
	var textures: Dictionary = {}
	var directory_access = DirAccess.open(dir)
	if directory_access.dir_exists("."):
		for fname in directory_access.get_files():
			var file_ext: String = fname.rsplit(".")[-1]
			if file_ext in ["png", "jpg", "jpeg", "bmp", "svg"]:
				var _tx = load_texture_from_string(fname, str(dir,"/"))
				if _tx != null:
					textures[fname] = _tx
	return textures

func has_any(arr1: Array, arr2: Array) -> bool:
	for x in arr1:
		for y in arr2:
			if x == y:
				return true
	return false

func encode_offer(offer: Dictionary) -> String:
	return JSON.stringify(offer)

func decode_offer(offer: String) -> Dictionary:
	return JSON.parse_string(offer)

func is_desktop_platform() -> bool:
	return [
		"Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"
	].has(OS.get_name())

func is_web_platform() -> bool:
	return [
		"Web"
	].has(OS.get_name())

func is_mobile_platform() -> bool:
	return [
		"iOS", "Android"
	].has(OS.get_name())