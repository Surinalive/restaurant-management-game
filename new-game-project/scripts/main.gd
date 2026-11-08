## https://www.strayspark.studio/blog/godot-4-multiplayer-networking-authoritative-server

extends Control

@onready var host_button: Button = $VBoxContainer/Host
@onready var join_button: Button = $VBoxContainer/HBoxContainer/Join
@onready var address_input: LineEdit = $VBoxContainer/HBoxContainer/AddressInput
@onready var player_list: ItemList = $PlayerList
@onready var start_button: Button = $VBoxContainer/Start
@onready var back_button: Button = $Back
@onready var change_name_button: Button = $VBoxContainer2/HBoxContainer2/ChangeName
@onready var done_button: Button = $VBoxContainer2/HBoxContainer/Done
@onready var name_text: TextEdit = $VBoxContainer2/HBoxContainer/NameText
@onready var player_name_label: Label = $VBoxContainer2/HBoxContainer2/PlayerName
@onready var color_picker: ColorPickerButton = $VBoxContainer2/HBoxContainer3/ColorPicker
@onready var sprite: Sprite2D = $VBoxContainer2/HBoxContainer3/Sprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed);
	join_button.pressed.connect(_on_join_pressed);
	start_button.pressed.connect(_on_start_pressed);

	NetworkManager.player_connected.connect(_refresh_player_list);
	NetworkManager.player_disconnected.connect(_refresh_player_list);
	NetworkManager.connection_established.connect(_on_connected);
	NetworkManager.server_disconnected.connect(_on_server_disconnected);
	NetworkManager.player_name_updated.connect(_player_name_updated)
	back_button.visible = false;


@rpc("authority", "call_local", "reliable")
func start_game() -> void:
	print("Started game");
	get_tree().change_scene_to_file("res://scenes/game")


func _on_start_pressed() -> void:
	if not NetworkManager.is_server:
		return
	# Server tells everyone to start
	start_game.rpc()
	

func in_lobby() -> void:
	host_button.visible = false;
	join_button.visible = false;
	address_input.visible = false;
	back_button.visible = true;
	change_name_button.visible = false;
	print("in lobby");


func _on_host_pressed() -> void:
	var error = NetworkManager.host_game()
	
	if error == OK:
		in_lobby()
		_refresh_player_list(0)


func _on_join_pressed() -> void:
	in_lobby();
	var address = address_input.text
	if address.is_empty():
		address = "127.0.0.1"
	NetworkManager.join_game(address)



func _on_connected() -> void:
	_refresh_player_list(0)

func _player_name_updated() -> void:
	_refresh_player_list(0)


func _refresh_player_list(_id: int) -> void:
	player_list.clear()
	for peer_id in NetworkManager.connected_players:
		var info = NetworkManager.connected_players[peer_id]
		player_list.add_item("%s (ID: %d)" % [info.player_name, info.peer_id])


func _on_back_pressed() -> void:
	NetworkManager.disconnect_game()
	
	start_button.visible = true;
	host_button.visible = true;
	join_button.visible = true;
	back_button.visible = false;

	player_list.clear()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_done_pressed() -> void:
	name_text.visible = false;
	done_button.visible = false;
	
func _on_text_edit_text_changed() -> void:
	player_name_label.text = name_text.text;
	NetworkManager.set_player_name(name_text.text);

func _on_change_name_pressed() -> void:
	name_text.text = "Player";
	name_text.visible = true;
	done_button.visible = true

func _on_server_disconnected() -> void:
	start_button.visible = true;
	host_button.visible = true;
	join_button.visible = true;
	back_button.visible = false;

	player_list.clear()


func _on_color_picker_color_changed(color: Color) -> void:
	sprite.modulate = color;
func _on_change_color_pressed() -> void:
	color_picker.visible = true;


func _on_color_picker_popup_closed() -> void:
	color_picker.visible = false;
