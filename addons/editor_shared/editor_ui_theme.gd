@tool
extends RefCounted

class_name EditorUITheme

const COLOR_SECTION: Color = Color(0.50, 0.75, 0.95)
const COLOR_SUBTLE: Color = Color(0.65, 0.68, 0.74)
const COLOR_ERROR: Color = Color(0.95, 0.48, 0.42)
const COLOR_WARNING: Color = Color(1.0, 0.72, 0.42)
const SECTION_FONT_SIZE: int = 13
const TITLE_FONT_SIZE: int = 16
const CONTROL_HEIGHT: int = 28

static func style_section_label(label: Label) -> void:
	label.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	label.add_theme_color_override("font_color", COLOR_SECTION)
	label.add_theme_constant_override("outline_size", 0)

static func style_title_label(label: Label) -> void:
	label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.88, 0.91, 0.96))
