extends Node3D

var move_speed = 10.0

func _ready():
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())

func _process(delta):
	if $MultiplayerSynchronizer.get_multiplayer_authority() != multiplayer.get_unique_id():
		return

	# Check for left arrow key press
	if Input.is_action_pressed("ui_left"):
		position.x -= move_speed * delta

	# Check for right arrow key press
	if Input.is_action_pressed("ui_right"):
		position.x += move_speed * delta
