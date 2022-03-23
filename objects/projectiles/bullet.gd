extends KinematicBody2D

const GRAVITY = 1
var motion = Vector2()

enum STATES {IDLE}
export(int) var state = STATES.IDLE

onready var Sprite = $Sprite
onready var Shadow = $Shadow

onready var Col2D = $Col2D
onready var HitArea = $HitArea
onready var HitShape = $HitArea/HitShape






var limit_left
var limit_right
var limit_bottom

func _ready():
	Col2D.position.y = positionZ# -52
	HitArea.position.y = positionZ# -52
	
	Sprite.position.y = positionZ# -48
	Shadow.position.y = positionZ/10
	######################### repetition for no delay in this important action #
	
	if Global.limit_left != 0:
		limit_left = Global.limit_left
	
	if Global.limit_down != 0:
		limit_bottom = Global.limit_down
	
	
	if type != 0:
		bullet_configure()





var move_dir = Vector2(0,0)

var faketimer = 0

var motionZ = 0
var positionZ = 0


func _physics_process(_delta):
	motion = move_and_slide(motion, Vector2(0,-1))
	
	match state:
		STATES.IDLE:
			idle()
	
	
	
	############################################ SPRITE LOGIC ##################
	if move_dir.x == 1:
		set_flipped(false)
	elif move_dir.x == -1:
		set_flipped(true)
	
	Shadow.frame = Sprite.frame
	
	var supernumbers = sin(OS.get_system_time_msecs() / 50)
	var meganumbers = sin(OS.get_system_time_secs())
	
	var colR = abs(supernumbers)
	var colG = abs(supernumbers + meganumbers)
	var colB = colR + meganumbers
	
	$Sprite.set_modulate(Color(colR,colG,colB))
	############################################################################
	
	
	############################################### Z LOGIC ####################
	Col2D.position.y = positionZ# -52
	HitArea.position.y = positionZ# -52
	
	Sprite.position.y = positionZ# -48
	Shadow.position.y = positionZ/10
	
	
	if gravity_on == 1:
		positionZ += motionZ
		
		if positionZ < 0:
			motionZ += GRAVITY # 1
	
	z_index = int(position.y/50) -1
	############################################################################
	
	
	
	if speed_accel != 0:
		if speed_accel < 0:
			speed_accel += 1
		
		elif speed_accel > 0:
			speed_accel -= 1
		
		
		speed = speed_base + speed_accel*5
	










var type = 0 #0 = regular bullet

var gravity_on = 0

var speed = 500
var speed_accel = 50
var speed_base = 500

var combo_increase = 7



func bullet_configure():
	speed_base = speed
	
	if type == 1:
		pass













func idle():
	if move_dir.x == 0:
		queue_free()
	
	if type == 0: #Regular bullet
		motion.x = move_dir.x * speed
		











export var shot_owner = 0

func _on_Area2D_area_entered(area):
	if area.is_in_group("punchable"):
		if area.area_owner_positionY != null:
			var areaY = -(area.area_owner_positionY - position.y)
			
			
			if areaY < 30 && areaY > -40:
				if area.holdme == 0:
					area_take_damage(area)
				else:
					if positionZ < 10:
						area_take_damage(area)
			
			




var shooter_entity_owner = self

func area_take_damage(area):
	area.take_damage()
	area.hit_positionX = position.x
	area.hit_owner = shooter_entity_owner
	
	queue_free()
















func change_state(new_state):
	state = new_state


func set_flipped(flipstate):
	if flipstate: ### LEFT ###
		Sprite.flip_h = true
		Shadow.flip_h = true
	else: ########### RIGHT ###
		Sprite.flip_h = false
		Shadow.flip_h = false



#func despawn():
#	if shot_owner == 0:
#		if Globalplayer.position.x < (limit_left-45) + sight:
#			if position.x > limit_left + (sight*2):
#				queue_free()
#
#		elif Globalplayer.position.x > (limit_right+45) - sight:
#			if position.x < limit_right - (sight*2):
#				queue_free()
#
#		else:
#			if abs(Globalplayer.position.x - position.x) > sight:
#				queue_free()

#var sight = 999
#var Globalplayer
