## https://www.strayspark.studio/blog/godot-4-multiplayer-networking-authoritative-server

extends Control

@onready var player_info_container: VBoxContainer = $PlayerInfoContainer
@onready var player_name_container: HBoxContainer = $PlayerInfoContainer/PlayerNameContainer
@onready var player_name_label: Label = $PlayerInfoContainer/PlayerNameContainer/PlayerName
@onready var change_name_button: Button = $PlayerInfoContainer/PlayerNameContainer/ChangeName
@onready var name_change_container: HBoxContainer = $NameChangeContainer
@onready var name_text: TextEdit = $NameChangeContainer/NameText
@onready var done_button: Button = $NameChangeContainer/Done
@onready var player_icon_container: HBoxContainer = $PlayerInfoContainer/PlayerIconContainer
@onready var sprite: Sprite2D = $PlayerInfoContainer/PlayerIconContainer/Sprite
@onready var change_color_button: Button = $PlayerInfoContainer/PlayerIconContainer/ChangeColor
@onready var color_picker_container: HBoxContainer = $ColorPickerContainer
@onready var color_sprite: Sprite2D = $ColorPickerContainer/Sprite2D

@onready var color_list: ItemList = $ColorPickerContainer/ColorList
@onready var color_picked_button: Button = $ColorPickerContainer/ColorPickedButton
@onready var start_host_container: VBoxContainer = $StartHostContainer
@onready var start_button: Button = $StartHostContainer/Start
@onready var host_button: Button = $StartHostContainer/Host
@onready var join_container: HBoxContainer = $StartHostContainer/JoinContainer
@onready var address_input: LineEdit = $StartHostContainer/JoinContainer/AddressInput
@onready var join_button: Button = $StartHostContainer/JoinContainer/Join
@onready var back_button: Button = $Back
@onready var quit_button: Button = $Quit
@onready var player_list: ItemList = $PlayerList

@onready var color_dictionary = {red = Color.RED, 
								orange = Color.ORANGE, 
								yellow = Color.YELLOW, 
								green = Color.GREEN,
								blue = Color.BLUE,
								purple = Color.PURPLE,
								white = Color.WHITE,
								black = Color.BLACK }

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed);
	join_button.pressed.connect(_on_join_pressed);
	start_button.pressed.connect(_on_start_pressed);

	NetworkManager.player_connected.connect(_refresh_player_list);
	NetworkManager.player_disconnected.connect(_refresh_player_list);
	NetworkManager.connection_established.connect(_on_connected);
	NetworkManager.server_disconnected.connect(_on_server_disconnected);
	NetworkManager.player_info_updated.connect(_player_info_updated)
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
	join_container.visible = false
	back_button.visible = true;
	player_list.visible = true;
	player_name_container.visible = false;
	player_icon_container.visible = false;
	print("in lobby");

func main_menu_reset() -> void:
	start_button.visible = true;
	host_button.visible = true;
	join_container.visible = true
	back_button.visible = false;
	player_list.visible = false;
	player_name_container.visible = true;
	player_icon_container.visible = true;

	player_list.clear()

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

func _player_info_updated() -> void:
	_refresh_player_list(0)

func _refresh_player_list(_id: int) -> void:
	player_list.clear()
	for peer_id in NetworkManager.connected_players:
		var info = NetworkManager.connected_players[peer_id]
		var icon_texture =  load("res://icon.svg")
		
		var item_index = player_list.add_item("%s (ID: %d)" % [info.player_name, info.peer_id], icon_texture)
		player_list.set_item_icon_modulate(item_index, info.player_color)

func _on_back_pressed() -> void:
	NetworkManager.disconnect_game()
	main_menu_reset()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_done_pressed() -> void:
	name_change_container.visible = false;
	player_info_container.visible = true;
	start_host_container.visible = true;
	
func _on_text_edit_text_changed() -> void:
	player_name_label.text = name_text.text;
	NetworkManager.set_player_name(name_text.text);

func _on_change_name_pressed() -> void:
	name_change_container.visible = true;
	player_info_container.visible = false;
	start_host_container.visible = false

func _on_server_disconnected() -> void:
	main_menu_reset()

func _on_change_color_pressed() -> void:
	player_info_container.visible = false;
	color_picker_container.visible  = true;
	start_host_container.visible = false;
	for color in color_dictionary :
		color_list.add_item(color)

func _on_color_list_item_selected(index: int) -> void:
	var color = color_dictionary[color_list.get_item_text(index)];
	sprite.modulate = color;
	color_sprite.modulate = color
	NetworkManager.set_player_color(color);


func _on_color_picked_button_pressed() -> void:
	player_info_container.visible = true;
	color_picker_container.visible  = false;
	start_host_container.visible = true;
