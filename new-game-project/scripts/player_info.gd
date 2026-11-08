##https://www.strayspark.studio/blog/godot-4-multiplayer-networking-authoritative-server

# player_info.gd
class_name PlayerInfo;
extends RefCounted

var peer_id: int
var player_name: String
var player_color: Color
var team: int = 0
var is_ready: bool = false
var ping_ms: int = 0

func _init(id: int, name: String, color: Color = Color.WHITE) -> void:
	peer_id = id
	player_name = name
	player_color = color

func set_player_name(name: String) -> void:
	player_name = name;

func set_player_color(color: Color) -> void:
	player_color = color;
