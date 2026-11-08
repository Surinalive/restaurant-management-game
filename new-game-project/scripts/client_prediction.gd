##https://www.strayspark.studio/blog/godot-4-multiplayer-networking-authoritative-server

## NO IDEA WHAT TO DO HERE

# client_prediction.gd
extends Node

## Client-side prediction with server reconciliation

var predicted_states: Array[Dictionary] = []
var last_acknowledged_sequence: int = 0
var reconciliation_threshold: float = 2.0  # Tolerate 2 pixels of desync

func store_predicted_state(sequence: int, position: Vector2,
							velocity: Vector2) -> void:
	predicted_states.append({
		"sequence": sequence,
		"position": position,
		"velocity": velocity,
	})

	# Keep buffer manageable
	while predicted_states.size() > 120:
		predicted_states.pop_front()

func reconcile(server_position: Vector2, server_velocity: Vector2,
			   server_sequence: int, player: CharacterBody2D) -> void:
	last_acknowledged_sequence = server_sequence

	# Find the predicted state for this sequence
	var predicted_index = -1
	for i in predicted_states.size():
		if predicted_states[i].sequence == server_sequence:
			predicted_index = i
			break

	if predicted_index == -1:
		# No matching prediction, just snap
		player.global_position = server_position
		player.velocity = server_velocity
		return

	# Compare prediction to server reality
	var predicted = predicted_states[predicted_index]
	var error = predicted.position.distance_to(server_position)

	if error < reconciliation_threshold:
		# Prediction was close enough, no correction needed
		# Remove acknowledged predictions
		predicted_states = predicted_states.slice(predicted_index + 1)
		return

	# Prediction was wrong. Correct and re-simulate.
	# 1. Snap to server state
	player.global_position = server_position
	player.velocity = server_velocity

	# 2. Remove old predictions up to and including the corrected one
	var remaining_inputs = predicted_states.slice(predicted_index + 1)
	predicted_states.clear()

	# 3. Re-apply all inputs that happened AFTER the corrected frame
	for state in remaining_inputs:
		# Re-simulate this input
		# (You'd need to store the input alongside the state)
		# This is simplified -- full implementation stores inputs too
		predicted_states.append(state)
