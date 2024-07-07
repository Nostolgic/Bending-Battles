extends CharacterBody3D

var linear_velocity = Vector3.ZERO
var speed = 10
var is_seen = false
@onready var ray_cast_3d = $CollisionShape3D/SCP/RayCast3D
@onready var player = $"../player"

func _ready():
	var player = $"../player"

func _process(delta):
	var direction = (player.global_transform.origin - global_transform.origin).normalized()
	if !is_seen or out_of_pov():
		if !is_seen:
			linear_velocity = direction * speed
			
			#print("he's moving")
		else:
			linear_velocity = direction * (speed * 0.5)
			print("Moving towards player. Direction:", direction, "Linear velocity:", linear_velocity)
	else:
		linear_velocity = Vector3.ZERO # Stop moving when seen
		print("Stopped moving")

	move_and_slide()
	#print("Current SCP Position:", global_transform.origin)

func out_of_pov() -> bool:
	var scp_direction = (global_transform.origin - player.global_transform.origin).normalized()
	var camera_forward = -player.global_transform.basis.z.normalized() # Camera's forward vector
	var angle_to_player = rad_to_deg(camera_forward.angle_to(scp_direction))
	print("Angle to player:", angle_to_player)
	return angle_to_player > player.look_angle_threshold

func _on_player_player_look_at_scp():
	is_seen = true
	print("bruh")
	


func _on_player_player_look_away_from_scp():
	is_seen = false
	print("bruh")
