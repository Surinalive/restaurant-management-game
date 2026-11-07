##https://www.strayspark.studio/blog/godot-4-multiplayer-networking-authoritative-server


# network_interpolation.gd
extends Node

## Interpolation for remote entities (other players)

var state_buffer: Array[Dictionary] = []
var interpolation_delay: float = 0.1  # 100ms delay

func add_state(timestamp: float, position: Vector2, rotation: Vector2) -> void:
	state_buffer.append({
		"timestamp": timestamp,
		"position": position,
		"rotation": rotation,
	})

	# Keep buffer size reasonable
	while state_buffer.size() > 30:
		state_buffer.pop_front()

func get_interpolated_state(current_time: float) -> Dictionary:
	var render_time = current_time - interpolation_delay

	# Find the two states to interpolate between
	if state_buffer.size() < 2:
		if state_buffer.size() == 1:
			return state_buffer[0]
		return {}

	# Find states bracketing render_time
	var before: Dictionary = state_buffer[0]
	var after: Dictionary = state_buffer[1]

	for i in range(1, state_buffer.size()):
		if state_buffer[i].timestamp >= render_time:
			after = state_buffer[i]
			before = state_buffer[i - 1]
			break

	# Interpolate
	var time_range = after.timestamp - before.timestamp
	if time_range <= 0:
		return before

	var t = clampf((render_time - before.timestamp) / time_range, 0.0, 1.0)

	return {
		"position": before.position.lerp(after.position, t),
		"rotation": before.rotation.lerp(after.rotation, t),
	}
