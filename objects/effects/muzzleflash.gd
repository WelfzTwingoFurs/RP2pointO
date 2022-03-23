extends Sprite

var timer

var positionZ

var direction

func _ready():
	timer = randi() % 2
	frame = randi() % 2
	flip_v = timer
	
	flip_h = direction -1
	
	position.y += positionZ


func _physics_process(_delta):
	if timer < -1:
		queue_free()
	
	timer -= 1

func fuckyou():
	var system_secs = OS.get_system_time_secs()
	
	var supernumbers = sin((OS.get_system_time_msecs() / 50 ))
	var meganumbers = sin(system_secs)
	
	var colR = abs(supernumbers)
	var colG = abs(supernumbers + meganumbers)
	var colB = colR + meganumbers
	
	$Sprite.set_modulate(Color(colR,colG,colB))
