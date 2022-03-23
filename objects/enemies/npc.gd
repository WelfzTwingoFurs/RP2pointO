extends "res://objects/enemies/enemy-common.gd"
# All non-specific NPC actions in one neat lil' package for ya 
# Everything already comes in configured, just change needed variables for
# customizing proprieties of the entity in _ready or whatever!
#
#Speed
# 
#behavior_alt
# 0 = instantly starts to fight
# 1 = runs away and then starts to fight
# 2 = runs away simply






const SPRITE0 = preload("res://graphics/characters/NPCB-hobo.png")
const SPRITE1 = preload("res://graphics/characters/NPC-Hoodie.png")


func _ready():
	speedwalk = 60
	
	var spriterandi = randi() % 2
	
	if spriterandi == 0:
		Sprite.texture = SPRITE0
		Shadow.texture = SPRITE0
	
	elif spriterandi == 1:
		Sprite.texture = SPRITE1
		Shadow.texture = SPRITE1
	


func anim_idle():
	var pick_one = randi() % 4
	
	if pick_one == 0:
		AniPlay.play("idle1")
	
	elif pick_one == 1:
		AniPlay.play("idle2")
	
	elif pick_one == 2:
		AniPlay.stop()
		Sprite.frame = 3
	
	elif pick_one == 3:
		AniPlay.stop()
		Sprite.frame = 5









func _physics_process(_delta):
#	#var cum
#	#if hit_owner != null:
#	#	cum = hit_owner.combo_increase
##
	$Label.text = str("",
###
	"alt:",behavior_alt," anger:",anger,"\n",
##	move_dir," ",faketimer,"\n",
###	"ouch=",ouch," fear=",fear,
#	"c:",combo," h:",Combo_hurt," f:",Combo_fall,
##	"\n+:",cum," ouch active:",HurtArea.ouch_activator,
	"")
#	







#################################### transformation into zombie ################
var wants_cloroquina = 1

func take_cloroquina():
	if wants_cloroquina == 1:
		var cloroman = load("res://objects/enemies/npczombie.tscn")
		var cloro_instance = cloroman.instance()
		
		###################################### send same information keep it ###
		cloro_instance.position = position
		#cloro_instance.face_dir = face_dir
		
		#cloro_instance.limit_left = limit_left
		#cloro_instance.limit_bottom = limit_bottom
		########################################################################
		
		
		get_parent().add_child(cloro_instance)
		queue_free()



















