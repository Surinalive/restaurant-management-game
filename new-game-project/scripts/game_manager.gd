## https://www.strayspark.studio/blog/godot-4-multiplayer-networking-authoritative-server
# game_manager.gd
extends Node

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var players_container: Node = $Players

func _ready() -> void:
	if multiplayer.is_server():
		# Spawn a player for each connected peer
		for peer_id in NetworkManager.connected_players:
			_spawn_player(peer_id)

		# Also spawn for future connections
		NetworkManager.player_connected.connect(_spawn_player)
		NetworkManager.player_disconnected.connect(_despawn_player)

func _spawn_player(peer_id: int) -> void:
	var player_scene = preload("res://scenes/player/networked_player.tscn")
	var player = player_scene.instantiate()

	# The node name MUST be unique and deterministic
	# Using peer_id as the name ensures consistency
	player.name = str(peer_id)

	# Set the multiplayer authority to the owning peer
	player.set_multiplayer_authority(peer_id)

	players_container.add_child(player, true)

func _despawn_player(peer_id: int) -> void:
	var player = players_container.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
