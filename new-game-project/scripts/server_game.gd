##https://www.strayspark.studio/blog/godot-4-multiplayer-networking-authoritative-server


# server_game.gd
extends Node

## Server-side game management

var player_states: Dictionary = {}  # peer_id -> PlayerState
var game_state: GameState = GameState.new()

func _ready() -> void:
	if not multiplayer.is_server():
		set_physics_process(false)
		return
	
	# Add this to listen for new players
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)

# Create the state object when they join
func _on_player_connected(peer_id: int) -> void:
	player_states[peer_id] = PlayerState.new(peer_id);

func _on_player_disconnected(peer_id: int) -> void:
	# Always clean up your dictionary when someone leaves!
	if player_states.has(peer_id):
		player_states.erase(peer_id)

func _physics_process(delta: float) -> void:
	# Step 1: Process pending inputs for all players
	for peer_id in player_states:
		var state = player_states[peer_id]
		if state.pending_input != null:
			_process_input(peer_id, state.pending_input, delta)
			state.pending_input = null

	# Step 2: Update game simulation
	_update_game_simulation(delta)

	# Step 3: Check game rules (kills, objectives, etc.)
	_check_game_rules()

	# Step 4: State is automatically replicated by MultiplayerSynchronizer
	# No manual broadcast needed for synced properties

func _process_input(peer_id: int, input: Dictionary, delta: float) -> void:
	var player_node = _get_player_node(peer_id)
	if player_node == null:
		return

	# Validate input
	var move_vector = input.get("move", Vector2.ZERO)
	move_vector = move_vector.limit_length(1.0)  # Prevent speed hacks

	var jump = input.get("jump", false)
	var shoot = input.get("shoot", false)

	# Apply validated input to player
	player_node._apply_input(move_vector, jump)

	if shoot:
		_handle_shoot(peer_id, player_node, input.get("aim_direction", Vector3.FORWARD))

func _handle_shoot(shooter_id: int, shooter: CharacterBody2D,
					aim_direction: Vector2) -> void:
	# Server performs the raycast -- never trust client hit detection
	aim_direction = aim_direction.normalized()

	var space_state = get_viewport().get_world_2d().direct_space_state
	var ray_origin = shooter.global_position
	var ray_end = ray_origin + aim_direction * 1000.0

	var query = PhysicsRayQueryParameters2D.create(ray_origin, ray_end)
	query.exclude = [shooter.get_rid()]
	query.collision_mask = 0b0110  # Players and environment

	var result = space_state.intersect_ray(query)

	if result:
		var hit_node = result.collider
		if hit_node is CharacterBody2D and hit_node.has_method("take_damage"):
			var damage = 25.0  # Server controls damage values
			hit_node.take_damage(damage, shooter_id)

			# Notify the shooter of the hit (for hit markers, sound effects)
			_notify_hit.rpc_id(shooter_id, result.position)

			# Notify the victim
			var victim_id = int(str(hit_node.name))
			_notify_damage.rpc_id(victim_id, damage, shooter_id)

@rpc("authority", "call_remote", "reliable")
func _notify_hit(hit_position: Vector3) -> void:
	# Client-side hit feedback
	pass

@rpc("authority", "call_remote", "reliable")
func _notify_damage(damage: float, attacker_id: int) -> void:
	# Client-side damage feedback
	pass

func _update_game_simulation(delta: float) -> void:
	# Update projectiles, AI, pickup respawns, etc.
	# All on the server
	pass

func _check_game_rules() -> void:
	# Check win conditions, round timers, etc.
	pass

func _get_player_node(peer_id: int) -> CharacterBody3D:
	var players = $Players
	return players.get_node_or_null(str(peer_id)) as CharacterBody3D
