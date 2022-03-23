extends Sprite

var faketimer = 0
var type = 1

var position_var = Vector2(0,0)

#func _ready():
#	Global.allEffectsBullet = self

func _physics_process(_delta):
	if faketimer > 0:
		faketimer -= 1
		
		visible = 1
		position = position_var
		
		if type == 1:
			if faketimer < 5:
				frame = (randi() % 2) +10
				
				type = 0
			
		
	
	else:#if faketimer == 0:
		visible = 0
		
		if type == 1:
			faketimer = 10
			frame = randi() % 2
	


#	var was_faketimer
#	if was_faketimer != faketimer:
#		was_faketimer = faketimer
