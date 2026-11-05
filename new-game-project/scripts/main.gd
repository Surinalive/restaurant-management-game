extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Back.visible = false;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_game() -> void:
	print("Started game");
	get_tree().change_scene_to_file("res://scenes/game_level.tscn")
	pass #transition to game level

func _on_start_pressed() -> void:
	start_game()
	

func lobby() -> void:
	$VBoxContainer/Start.visible = false;
	$VBoxContainer/Host.visible = false;
	$VBoxContainer/Join.visible = false;
	$Back.visible = true;
	$VBoxContainer2/HBoxContainer2/ChangeName.visible = false;
	print("in lobby");


func _on_host_pressed() -> void:
	lobby();

func _on_join_pressed() -> void:
	lobby();

func _on_back_pressed() -> void:
	$VBoxContainer/Start.visible = true;
	$VBoxContainer/Host.visible = true;
	$VBoxContainer/Join.visible = true;
	$Back.visible = false;


func _on_quit_pressed() -> void:
	pass # Replace with function body.
	# quit game

func _on_done_pressed() -> void:
	$VBoxContainer2/HBoxContainer/TextEdit.visible = false;
	$VBoxContainer2/HBoxContainer/Done.visible = false;
	

func _on_text_edit_text_changed() -> void:
	$VBoxContainer2/HBoxContainer2/PlayerName.text = $VBoxContainer2/HBoxContainer/TextEdit.text;

func _on_change_name_pressed() -> void:
	$VBoxContainer2/HBoxContainer/TextEdit.text = "Player";
	$VBoxContainer2/HBoxContainer/TextEdit.visible = true;
	$VBoxContainer2/HBoxContainer/Done.visible = true
