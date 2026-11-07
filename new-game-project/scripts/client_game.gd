##https://www.strayspark.studio/blog/godot-4-multiplayer-networking-authoritative-server


# client_game.gd
extends Node

## Client-side game management

var input_sequence: int = 0
var pending_inputs: Array[Dictionary] = []

func _ready() -> void:
	if multiplayer.is_server():
		set_physics_process(false)
		return

func _physics_process(delta: float) -> void:
	var my_player = _get_my_player()
	if my_player == null:
		return

	# Gather input
	var input = _gather_input()
	input_sequence += 1
	input["sequence"] = input_sequence

	# Send to server
	_submit_input.rpc_id(1, input)

	# Client-side prediction: apply input locally immediately
	_predict_movement(my_player, input, delta)

	# Store input for reconciliation
	pending_inputs.append(input)

	# Trim old inputs (keep last 60 frames worth)
	while pending_inputs.size() > 60:
		pending_inputs.pop_front()

func _gather_input() -> Dictionary:
	return {
		"move": Input.get_vector(
			"move_left", "move_right", "move_forward", "move_back"
		),
		"jump": Input.is_action_just_pressed("jump"),
		"shoot": Input.is_action_just_pressed("shoot"),
		"aim_direction": _get_aim_direction(),
	}

func _get_aim_direction() -> Vector2:
	var my_player = _get_my_player()
	if my_player:
		return my_player.global_position.direction_to(my_player.get_global_mouse_position())
	return Vector2.RIGHT # Fallback

func _predict_movement(player: CharacterBody3D, input: Dictionary,
						delta: float) -> void:
	# Apply the same movement logic locally for instant feedback
	# This matches the server's _apply_input logic
	var move_vector = input.get("move", Vector2.ZERO)
	var direction = (player.transform.basis * Vector3(
		move_vector.x, 0, move_vector.y
	)).normalized()

	if direction:
		player.velocity.x = direction.x * player.speed
		player.velocity.z = direction.z * player.speed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.speed)
		player.velocity.z = move_toward(player.velocity.z, 0, player.speed)

	if input.get("jump", false) and player.is_on_floor():
		player.velocity.y = player.jump_velocity

	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta

	player.move_and_slide()

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _submit_input(input: Dictionary) -> void:
	# Received on server, handled by server_game.gd
	pass

func _get_my_player() -> CharacterBody3D:
	var my_id = multiplayer.get_unique_id()
	return $Players.get_node_or_null(str(my_id)) as CharacterBody3D
