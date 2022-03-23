extends "res://objects/enemies/enemy-common.gd"

func _ready():
	looking = 1
	speedwalk = 75

func anim_idle():
	var pick_one = randi() % 4
	
	if pick_one == 0:
		AniPlay.play("idle1")
	
	elif pick_one == 1:
		AniPlay.play("idle2")
	
	elif pick_one == 2:
		AniPlay.stop()
		Sprite.frame = 7
	
	elif pick_one == 3:
		AniPlay.stop()
		Sprite.frame = 9

#func idle():
#	.idle()
#	if ouch == 0:
#		if fear != 0:
#			target_lookfor()



func give_cloroquina():
	if targeted_item == null:
		target_clear()
	else:
		targeted_item.take_cloroquina()
		target_clear()



