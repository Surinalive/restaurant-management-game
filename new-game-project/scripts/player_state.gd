## This is complicated and might not be necessary for a simple(?) game.
## But pretty much provided by strayspark 

# player_state.gd
class_name PlayerState
extends RefCounted

var peer_id: int = 0
var pending_input: Dictionary = {}

func _init(id: int) -> void:
	peer_id = id
