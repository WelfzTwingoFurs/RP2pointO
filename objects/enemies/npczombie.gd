extends "res://objects/enemies/enemy-common.gd"

const SPRITE0 = preload("res://graphics/characters/NPCB-hobo.png")
const SPRITE1 = preload("res://graphics/characters/NPC-Hoodie.png")


func _ready():
	speedwalk = 20
	looking = 1
	
	target_lookfor()



var was_face = 0

func attacking():
	.attacking()
	
	if targeted_item == null:
		target_lookfor()
	
	if face_dir != was_face:
		faketimer = (randi() % 20) + 80
		
		was_face = face_dir
	
	if ouch == 0 && faketimer != 0:
		motion = lerp(motion, Vector2(0,0), 0.01)
		AniPlay.playback_speed = faketimer/30
	else:
		AniPlay.playback_speed = 1
	
	






func anim_idle():
	pass

