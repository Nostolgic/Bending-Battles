extends Camera3D

@onready var fps_rig = $fps_rig
@onready var animation_player = $fps_rig/AnimationPlayer

var idle = true;

# Called when the node enters the scene tree for the first time.
func _ready():
	animation_player.play("idle", true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	fps_rig.position.x = lerp(fps_rig.position.x,0.0,delta*5)
	fps_rig.position.y = lerp(fps_rig.position.y,0.0,delta*5)
	
	if idle and not animation_player.is_playing():
		animation_player.play("idle", true)


func sway(sway_amount):
	fps_rig.position.x -= sway_amount.x*0.0005
	fps_rig.position.y -= sway_amount.y*0.0005

func _input(event):
	if event.is_action_pressed("shoot"):
		idle = false
		animation_player.play("attack")
		idle = true

