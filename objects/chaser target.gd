extends KinematicBody2D

var follow = 1

func _physics_process(_delta):
	if follow == 1:
		
		position = get_global_mouse_position()
		
		if !Input.is_action_pressed("mouse1"):
			follow = 0
	
