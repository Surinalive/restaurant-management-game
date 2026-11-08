##https://www.strayspark.studio/blog/godot-4-multiplayer-networking-authoritative-server

##NOTE: THIS MUST ALL BE CHANGED LATER!!

# networked_player.gd
extends CharacterBody2D

@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var prediction: Node = $ClientPrediction
@onready var interpolation: Node = $NetworkInterpolation

@export var speed: float = 300.0
#@export var jump_velocity: float = -400.0

# Synced by MultiplayerSynchronizer
var server_position: Vector2
var server_velocity: Vector2
#var health: float = 100.0
#var is_alive: bool = true

# For tracking prediction
var input_sequence: int = 0

func _ready() -> void:
	if is_multiplayer_authority():
		$Camera2D.make_current()
	
	# Physics runs for the server (to calculate reality) 
	# AND the local player (to calculate prediction)
	set_physics_process(is_multiplayer_authority() or multiplayer.is_server())
	
	# Visual interpolation only runs for remote players on your screen
	set_process(not is_multiplayer_authority() and not multiplayer.is_server())

# 1. VISUAL SMOOTHING (Remote Players Only)
func _process(delta: float) -> void:
	var state = interpolation.get_interpolated_state(Time.get_ticks_msec() / 1000.0)
	if not state.is_empty():
		global_position = state.position
		rotation = state.rotation

# 2. PHYSICS & INPUT (Server and Local Player)
func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		_server_process(delta)
	elif is_multiplayer_authority():
		_client_process(delta)

func _client_process(delta: float) -> void:
	
	# Our player doesn't jump.... only mouse clicks are acceptable inputs
	## Gather input
	#var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	#var jump = Input.is_action_just_pressed("jump")
	
	## I think I should have some work here that captures clicks on allowable 
	## floor(tiles?) and stores it below for the key "move"
	
	input_sequence += 1
	var input_data = {
		"sequence": input_sequence,
		#"move": input_vector,
		## no jumping
		#"jump": jump
	}
	
	# Send it to the server
	_submit_input.rpc_id(1, input_data)
	
	# Predict the movement instantly on our screen
	## change this later when I properly understand it
	#_apply_input(input_vector, jump) -> _apply_input(input(?)
	
	# No jumping + player is always on the floor
	#if not is_on_floor():
		#velocity += get_gravity() * delta
	move_and_slide()
	
	# Store this exact movement so we can check it against the server later
	prediction.store_predicted_state(input_sequence, global_position, velocity)

# 3. RPC: SENDING INPUT TO SERVER
@rpc("any_peer", "call_remote", "unreliable_ordered")
func _submit_input(input_data: Dictionary) -> void:
	if not multiplayer.is_server():
		return
		
	var sender_id = multiplayer.get_remote_sender_id()
	if str(sender_id) != name:
		return  # Prevent hacking: You can't send input for someone else's character
		
	## No jumping nor move vector since point and click game
	#var move_vector = input_data.get("move", Vector2.ZERO)
	#var jump = input_data.get("jump", false)
	
	## Change later when I understand what's going on
	# var move = input_data.get("move") (?)
	#_apply_input(move_vector, jump) -> _apply_input(move(?))

# 4. SERVER PROCESSING
func _server_process(delta: float) -> void:
	## player is always on the floor.. no jumping!
	#if not is_on_floor():
		#velocity += get_gravity() * delta
	#
	
	move_and_slide()
	
	# Update the variables the Synchronizer is replicating to clients
	server_position = global_position
	server_velocity = velocity

# 5. MOVEMENT LOGIC (Shared by Client Prediction and Server Reality)
func _apply_input(input_vector: Vector2, jump: bool) -> void:
	var direction = input_vector.x
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	## no jumping!!
	#if jump and is_on_floor():
		#velocity.y = jump_velocity

# 6. RECONCILIATION
# The MultiplayerSynchronizer must call this whenever server_position updates
func _on_server_state_received(sequence: int) -> void:
	if is_multiplayer_authority():
		prediction.reconcile(server_position, server_velocity, sequence, self)
	else:
		var current_time = Time.get_ticks_msec() / 1000.0
		interpolation.add_state(current_time, server_position, rotation)
