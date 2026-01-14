extends Node

enum GameMode { NORMAL, EDITOR, DRIVING, OBJECT_PLACER }

var current_mode: GameMode = GameMode.NORMAL
var track_name: String = ""  # For user track loading (optional)
var came_from_editor: bool = false
