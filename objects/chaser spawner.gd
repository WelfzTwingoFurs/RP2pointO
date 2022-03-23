extends Sprite

func _physics_process(_delta):
	position = get_global_mouse_position()
	
	if Input.is_action_just_pressed("mouse1"):
		shoot()

const bul_entity = preload("res://objects/chaser target.tscn")

func shoot():
	var bul_instance = bul_entity.instance()
	bul_instance.position = position
	
	get_parent().add_child(bul_instance)
