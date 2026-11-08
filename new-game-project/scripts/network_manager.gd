##https://www.strayspark.studio/blog/godot-4-multiplayer-networking-authoritative-server

# network_manager.gd (Autoload)
extends Node

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal server_disconnected
signal connection_established
signal connection_failed
signal player_name_updated

const DEFAULT_PORT: int = 7777
const MAX_PLAYERS: int = 8

var peer: ENetMultiplayerPeer = null
var is_server: bool = false
var connected_players: Dictionary = {}  # peer_id -> PlayerInfo
var my_name: String = "Player";

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
# --- Dedicated Server Auto-Host Logic ---
	if OS.has_feature("dedicated_server") or "--server" in OS.get_cmdline_args():
		print("Starting as dedicated server...")
		get_viewport().disable_2d = true  # Disable 2D rendering for headless performance
		host_game(DEFAULT_PORT)	
	

func set_player_name(name: String) -> void:
	my_name = name;

func host_game(port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS)

	if error != OK:
		push_error("Failed to create server: %s" % error_string(error))
		return error

	multiplayer.multiplayer_peer = peer
	is_server = true

	# Server is also peer ID 1
	connected_players[1] = PlayerInfo.new(1, my_name)
	print("Server started on port %d" % port)

	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)

	if error != OK:
		push_error("Failed to create client: %s" % error_string(error))
		return error

	multiplayer.multiplayer_peer = peer
	is_server = false
	print("Connecting to %s:%d..." % [address, port])

	return OK


func disconnect_game() -> void:
	if peer:
		peer.close()
		peer = null
	multiplayer.multiplayer_peer = null
	is_server = false
	connected_players.clear()

func _on_peer_connected(id: int) -> void:
	print("Peer connected: %d" % id)
	connected_players[id] = PlayerInfo.new(id, "Player_%d" % id)
	player_connected.emit(id)
	_receive_name_update.rpc(1, my_name)
	
	

func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: %d" % id)
	connected_players.erase(id)
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	var my_id = multiplayer.get_unique_id()
	print("Connected to server. My ID: %d" % my_id)
	
	# Add ourselves to our own player list!
	connected_players[my_id] = PlayerInfo.new(my_id, my_name)	
	_send_name_to_server.rpc_id(1, my_name)
	print("Connected to server. My ID: %d" % multiplayer.get_unique_id())
	connection_established.emit()
	
	

func _on_connection_failed() -> void:
	print("Connection failed")
	disconnect_game()
	connection_failed.emit()

func _on_server_disconnected() -> void:
	print("Server disconnected")
	disconnect_game()
	server_disconnected.emit()
	
# Client tells Server its name
@rpc("any_peer", "call_remote", "reliable")
func _send_name_to_server(new_name: String) -> void:
	if not is_server: 
		return
		
	var sender_id = multiplayer.get_remote_sender_id()
	if connected_players.has(sender_id):
		connected_players[sender_id].player_name = new_name
	
		# Server now broadcasts this client's name to everyone else
		_receive_name_update.rpc(sender_id, new_name)
		player_name_updated.emit()
		print("sent name");
	

	
# Server tells Clients a name changed
@rpc("authority", "call_remote", "reliable")
func _receive_name_update(peer_id: int, new_name: String) -> void:
	if connected_players.has(peer_id):
		connected_players[peer_id].player_name = new_name
		player_name_updated.emit()
		print("received name")
