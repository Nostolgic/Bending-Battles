extends CharacterBody3D

#Speed vars

var current_speed = 5.0

@export var walking_speed = 5.0
@export var sprinting_speed = 8.0
@export var crouching_speed = 3.0

# Player nodes

@onready var neck = $neck
@onready var head = $neck/head
@onready var eyes = $neck/head/eyes

@onready var standing_collision_shape_3d = $standing_CollisionShape3D
@onready var crouching_collision_shape_3d_2 = $crouching_CollisionShape3D2
@onready var ray_cast_3d = $RayCast3D
@onready var camera_3d = $neck/head/eyes/Camera3D
@onready var animation_player = $neck/head/eyes/AnimationPlayer


@onready var view_model_camera = $neck/head/eyes/Camera3D/SubViewportContainer/SubViewport/view_model_camera

#States

var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

#slide vars

var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.0

var end_slide_rotation_y = 0.0


#head bobbing vars

const head_bobbing_sprinting_speed = 22.0
const head_bobbing_walking_speed = 14.0
const head_bobbing_crouching_speed = 10.0

const head_bobbing_crouching_intensity = 0.05
const head_bobbing_sprinting_intensity = 0.2
const head_bobbing_walking_intensity = 0.1

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0

#Movement vars

@export var JUMP_VELOCITY = 4.5
@export var crouching_depth = -0.5
var lerp_speed = 10.0
var air_lerp_speed = 3.0

var free_look_tilt_amount = 8

var last_velocity = Vector3.ZERO

# Get the gravity from the project settings to be synced with RigidBody nodes.

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#input vars

var mouse_sens = 0.15
var direction = Vector3.ZERO

var camera_anglev=0



func _ready():
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
func _input(event):
	
	
	
	if Input.is_action_just_pressed("toggle_fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	
	if event is InputEventMouseMotion:
		if free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y,deg_to_rad(-120),deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x,deg_to_rad(-89),deg_to_rad(89))
		view_model_camera.sway(Vector2(event.relative.x,event.relative.y))
		
func _physics_process(delta):
	
	#updating the viewport
	$neck/head/eyes/Camera3D/SubViewportContainer/SubViewport/view_model_camera.global_transform = camera_3d.global_transform
	$neck/head/eyes/Camera3D/SubViewportContainer/SubViewport.size = DisplayServer.window_get_size()
	
	#getting movement input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	if Input.is_action_pressed("crouch") || sliding:
		
		current_speed = lerp(current_speed,crouching_speed,delta*lerp_speed)
		head.position.y = lerp(head.position.y,crouching_depth,delta*lerp_speed)
		standing_collision_shape_3d.disabled = true
		crouching_collision_shape_3d_2.disabled = false
		
		#Slide begin logic
		
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			free_looking = true
			end_slide_rotation_y = neck.rotation.y
			
			print("slide start")
		
		walking = false
		sprinting = false
		crouching = true
		
	elif !ray_cast_3d.is_colliding():
		
		crouching_collision_shape_3d_2.disabled = true
		standing_collision_shape_3d.disabled = false
		
		head.position.y = lerp(head.position.y,0.0,delta*lerp_speed)

		if Input.is_action_pressed("sprint"):
			# Sprinting
			current_speed = lerp(current_speed,sprinting_speed,delta*lerp_speed)
			
			walking = false
			sprinting = true
			crouching = false
		else:
			#Walking
			current_speed = lerp(current_speed,walking_speed,delta*lerp_speed)
			
			walking = true
			sprinting = false
			crouching = false

	# Stop sliding immediately when crouch is released
	if sliding and not Input.is_action_pressed("crouch"):
		sliding = false
		print("slide end")
		free_looking = false
		update_rotation_to_slide_direction()
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		sliding = false
		animation_player.play("jumping")
		update_rotation_to_slide_direction()
		
	if is_on_floor():
		if last_velocity.y < -10.0:
			animation_player.play("roll")
			if sliding:
				animation_player.play("landing")
		elif last_velocity.y < -4.0:
			animation_player.play("landing")
			print(last_velocity)
	
	#handle freelooking
	
	if Input.is_action_pressed("free_look") || sliding:
		free_looking = true
		
		if sliding:
			eyes.rotation.z = lerp(eyes.rotation.z,-deg_to_rad(5.0),delta*lerp_speed)
		else:
			eyes.rotation.z = -deg_to_rad(neck.rotation.y*free_look_tilt_amount)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y,0.0,delta*lerp_speed)
		eyes.rotation.z = lerp(eyes.rotation.z,0.0,delta*lerp_speed)
		
		
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0 or current_speed <= crouching_speed:
			sliding = false
			print("slide end")
			free_looking = false
			update_rotation_to_slide_direction()
		else:
			end_slide_rotation_y = neck.rotation.y
			
	
	
	#handle head bobbing
	
	
	if sprinting:
		head_bobbing_current_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed*delta
	elif walking:
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed*delta
	elif crouching:
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed*delta
	
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index/2)+0.5
		
		eyes.position.y = lerp(eyes.position.y,head_bobbing_vector.y*(head_bobbing_current_intensity/2.0),delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x,head_bobbing_vector.x*head_bobbing_current_intensity,delta*lerp_speed)
	else:
		eyes.position.y = lerp(eyes.position.y,0.0,delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x,0.0,delta*lerp_speed)
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

  # Get the input direction and handle the movement/deceleration
	if is_on_floor():
			direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * air_lerp_speed)
	
		if sliding:
			direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
			current_speed = (slide_timer + 0.15) * slide_speed
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	last_velocity = velocity
	
	move_and_slide()

func update_rotation_to_slide_direction():
	rotation.y = rotation.y + neck.rotation.y
	neck.rotation.y = 0.0

func _process(delta):
	
	
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

