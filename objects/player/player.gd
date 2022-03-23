extends KinematicBody2D

const SPRITE1 = preload("res://graphics/characters/player_aspone.png")
const SPRITE2 = preload("res://graphics/characters/player_aspone-holster.png")

const SPEED = 150
const GRAVITY = 1
const JUMP = -12
const AIR_SPEEDGAIN = 10
const AIR_SPEEDLOSS = 10
const AIR_SPEEDLIMIT = 270
#Default playback_speed is 1.2

onready var AniPlay = $AniPlay 
onready var Sprite = $Sprite
onready var Shadow = $Shadow
onready var HurtShape = $HurtArea/HurtShape
onready var HitShape = $HitArea/HitShape
onready var FeetShape = $FeetShape

onready var Camera = $Camera2D


enum STATES {IDLE,HOLDING}
export(int) var state = STATES.IDLE

var motion = Vector2()

export var anibusy = 0
export var aniframe = 0
var aniplus = 0

var input_dir = Vector2(0,0)

var face_dir = 1

var motionZ = 0
var positionZ = 0
var onfloor = 0

var air_accel = Vector2(0,0)

var air_speedloss_var = Vector2(0,0)

export var shooting = 0
var faketimer = 0

var sprite_blink = -1

var ammo1 = 99

export var holster = 0
var holster_check = 0

export var punching = 0






func _ready():
	onfloor = 1
	anibusy = 0
	punching = 0
	
	if Global.limit_left != 0:
		Camera.limit_left = Global.limit_left
	
	if Global.limit_down != 0:
		Camera.limit_bottom = Global.limit_down
	
	




func _physics_process(_delta):
	#print(round(Camera.get_camera_screen_center().x), "  ", abs(get_viewport().size.x)/2)
	#print(Global.Camera_center,"  ",Global.sight)
	
	$CanvasLayer/Debug.text = str("Position=(", round(position.x), ", ", round(position.y), "), Z=",round(positionZ),
	"\nmotion= (", round(motion.x), ", ", round(motion.y), "), Z=", round(motionZ), ". Accel: X=", air_accel.x, " Y=", air_accel.y,
	"\n(aniframe=", aniframe, ", aniplus=",aniplus, ", shooting=",shooting,") =", Sprite.frame, "*", face_dir,
	"\nanibusy=", anibusy, ". punching=", punching, ". Input=", input_dir,
	"\nAniPlay*", AniPlay.playback_speed, "=", AniPlay.current_animation)
	
	motion = move_and_slide(motion, Vector2(0,-1))
	
	match state:
		STATES.IDLE:
			idle()
		STATES.HOLDING:
			holdbaddie()
	
	Global.Camera_center = round(Camera.get_camera_screen_center().x)
	
	
	### Animation frame  ###
	if (Sprite.vframes * Sprite.hframes) > (aniframe + aniplus + shooting):
		Sprite.frame = aniframe + aniplus + shooting
		Shadow.frame = aniframe + aniplus + shooting
	
	
	
	if Input.is_action_pressed("ply1_right"):
		input_dir.x = 1
	elif Input.is_action_pressed("ply1_left"):
		input_dir.x = -1
	else:
		input_dir.x = 0
	
	if Input.is_action_pressed("ply1_down"):
		input_dir.y = 1
	elif Input.is_action_pressed("ply1_up"):
		input_dir.y = -1
	else:
		input_dir.y = 0
	
	
	if input_dir.x != 0:
		if onfloor == 0 && punching != 0:
			pass
		else:
			if HitShape.disabled == true:
				face_dir = input_dir.x
	
	if face_dir == 1:
		set_flipped(false)
	elif face_dir == -1:
		set_flipped(true)
	
	
	if faketimer > 0:
		faketimer -= 1
	
	if sprite_blink > faketimer:
		Sprite.set_modulate(Color(1,1,1))
		sprite_blink = -1
	
	
	z_index = int(position.y/50)
	
	
	############################################################################
	########## Z jump  ##############
	Sprite.position.y = positionZ -48
	Shadow.position.y = positionZ/10 -25
	HurtShape.position.y = positionZ -52
	HitShape.position.y = positionZ +hitshapeY #-62
	
	positionZ += motionZ
	
	if positionZ < 0:
		if Input.is_action_pressed("ply1_jump"):
			motionZ += (GRAVITY-0.2)
		else:
			motionZ += GRAVITY # 1
		
	elif motionZ > 0: #If goes over, correct to 0
		air_accel.x = round(air_accel.x)
		air_accel.y = round(air_accel.y)
		
		anibusy = 0
		
		positionZ = 0
		motionZ = 0
		
		onfloor = 1
		
		if punching != 0:
			if AniPlay.current_animation == "kickair2":
				AniPlay.play("kickland2") # punching - 0 // anibusy 1 - 0 // hitshape off
			else:
				AniPlay.play("kickland") # punching - 0 // anibusy 1 - 0 // hitshape off
#	else: ########### #End jump
#		onfloor = 1
	
	############################################################################
	
	
	
	############################################################################
		### AIR ACCELERATION AND DEACCELERATION ###
	
	#Speed limit
	if abs(air_accel.x) > AIR_SPEEDLIMIT:
		air_accel.x = AIR_SPEEDLIMIT*sign(air_accel.x)
	if abs(air_accel.y) > AIR_SPEEDLIMIT:
		air_accel.y = AIR_SPEEDLIMIT*sign(air_accel.y)
	
	#Speed low fixer
	if abs(air_accel.x) < 10: # if lower than base speed, issues happen 'cause
		air_accel.x = 0       #LERP wasn't used, and player will never stop
	if abs(air_accel.y) < 10: #deaccelerating. Issue with acceleration switching
		air_accel.y = 0       #between 10 and -10 is present, but unnoticeable
	
	
	#Speed gain on air # FeetShape sizer
	if onfloor == 0: 
		if FeetShape.shape.radius  > 4:
			FeetShape.shape.radius -= 1
		
		if abs(input_dir.x) == 1:
			air_accel.x += AIR_SPEEDGAIN*input_dir.x # 10
		
		if abs(input_dir.y) == 1:
			air_accel.y += AIR_SPEEDGAIN*input_dir.y # 10
	
	
	#Speed loss on ground # FeetShape sizer
	elif onfloor != 0: 
		if FeetShape.shape.radius < 8:
			FeetShape.shape.radius += 2
		
		if anibusy == 0:
			if input_dir.x != 0:
				if sign(air_accel.x) == input_dir.x: # if acceleration same direction as input, deaccelerate slowly
					air_speedloss_var.x = AIR_SPEEDLOSS*2 #/2 #5
				
				elif sign(air_accel.x) == -input_dir.x: #if acceleration against direction as input, deaccelerate normally
					air_speedloss_var.x = AIR_SPEEDLOSS #10
			else:
				air_speedloss_var.x = AIR_SPEEDLOSS*2 #20 #if no input, deaccelerate quickly
			
			#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
			### clone for Y ###
			if input_dir.y != 0:
				if sign(air_accel.y) == input_dir.y: # if acceleration same direction as input, deaccelerate slowly
					air_speedloss_var.y = AIR_SPEEDLOSS#/2 #5
				
				elif sign(air_accel.y) == -input_dir.y: #if acceleration against direction as input, deaccelerate normally
					air_speedloss_var.y = AIR_SPEEDLOSS #10
			else:
				air_speedloss_var.y = AIR_SPEEDLOSS*2 #20 #if no input, deaccelerate quickly
			#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
			
			### Application ###
			if abs(air_accel.x) > 0:
				air_accel.x -= air_speedloss_var.x*sign(air_accel.x)
				
			if abs(air_accel.y) > 0:
				air_accel.y -= air_speedloss_var.y*sign(air_accel.y)
		
		### Disregard all logic above if in the beggining animation of jump JUMPSTART
		else:#if anibusy == 1:
			if abs(air_accel.x) > 0:
				air_accel.x -= (AIR_SPEEDLOSS*2)*sign(air_accel.x)
				
			if abs(air_accel.y) > 0:
				air_accel.y -= (AIR_SPEEDLOSS*2)*sign(air_accel.y)
	############################################################################
	
	############################################################################
	
	
	if holster_check != holster: ### player texture changer ####################
		if holster == 0:
			Sprite.texture = SPRITE1
			Shadow.texture = SPRITE1
		else:
			Sprite.texture = SPRITE2
			Shadow.texture = SPRITE2
		
		holster_check = holster ################################################
	
	if punching == 0:
		HitShape.disabled = 1
		
		if punch_movement != 60: #Reset slight punch movement's speed
			punch_movement = 60





func idle(): 
	if Global.limit_left != 0:
		if position.x < (Global.limit_left):
			position.x = position.x + 3
	
	if Global.limit_down != 0:
		if position.y > Global.limit_down:
			position.y = position.y - 3
	
	############################################################################
	### SPEED AND ACCELERATION APPLICATION + jump animation ###
	
	if onfloor == 0:
		motion.x = air_accel.x
		motion.y = air_accel.y
		
		if motionZ > 0:
			if punching == 0:
				if motionZ < 7:
					aniframe = 8
					
				elif motionZ < 13:
					aniframe = 7
					
				elif motionZ < 15:
					aniframe = 0
	
	
	elif onfloor != 0:
		if punching == 0:
			motion = air_accel + input_dir * SPEED/onfloor
		else:
			#motion = Vector2(0,0)
			motion.x = lerp(motion.x, 0, 0.1)
			motion.y = lerp(motion.y, 0, 0.1)
	############################################################################
	
	############################################################################
		if Input.is_action_pressed("ply1_crouch"):
			aniplus = 0
			onfloor = 2
		elif Input.is_action_just_released("ply1_crouch"):
			aniframe = 0
			aniplus = 0
			onfloor = 1
	
	
	############################################################################
	### WALKING ANIMATION ### 0= straight, 20= diagDown, 40= diagUp, 60= down, 80= up
	
	#if onfloor != 0: (commented but true)
		
		if anibusy == 0:
			if input_dir != Vector2(0,0):
				if onfloor == 2:
					AniPlay.play("crouch")
				else:
					AniPlay.play("walk")
				
			else:
				if onfloor == 2:
					aniframe = 9
					
				else:
					if shooting == 0:
						AniPlay.play("idle")
					else:
						AniPlay.stop()
			
			if abs(input_dir.x) == 1:
				#face_dir = input_dir.x
				
				if onfloor != 2:
					if input_dir.y == 1: #diagDown
						aniplus = 20
					elif input_dir.y == -1: #diagUp
						aniplus = 40
					else:
						if input_dir.y == 0: #### Walk animation end delay #####
							if Input.is_action_pressed("ply1_shoot1"):
								aniplus = 0
							elif Input.is_action_just_released("ply1_shoot1"):
								aniframe = 0
							else:
								aniplus = 0 
						else:
							aniplus = 0 ########################################
				else:
					aniplus = 0
			else:
				
				if onfloor != 2:
					if input_dir.y == 1: #Down
						aniplus = 60
					elif input_dir.y == -1: #Up
						aniplus = 80
					else: 
						#if input_dir.x == 0: (already true)
						#### Walk animation end delay ##########################
						if Input.is_action_pressed("ply1_shoot1"):
							aniplus = 0
							if input_dir.y == 0:
								if onfloor == 1:
									aniframe = 0
								elif onfloor == 2: 
									aniframe = 9#sprite = aniframe + shooting
						elif Input.is_action_just_released("ply1_shoot1"):
							aniframe = 0
						else:
							if input_dir.y == 0:
								if aniframe == 0:
									aniplus = 0
							else:
								aniplus = 0 ####################################
				else:
					aniplus = 0
			
			####################################################################
			### Z JUMP START ###
	#if onfloor != 0: (commented but true)
		else:#if anibusy != 0:
			aniplus = 0
			
			if AniPlay.current_animation == "jumpstart": #If holding down jump, "jumpstart" will be slower
				
				if Input.is_action_pressed("ply1_jump"): #playback speed restored at jump()
					AniPlay.playback_speed = 0.7
					
				else:
					AniPlay.playback_speed = 1.2
	
	
	#if onfloor != 0 && anibusy == 0: (commented but true)
		if punching == 0:
			if Input.is_action_just_pressed("ply1_jump"):
				AniPlay.play("jumpstart") #anibusy 1 - 0 // jump()
	############################################################################
	
	############################################################################
	### Weapon holster ###
	#if onfloor != 0 && anibusy == 0: (commented but true)
			if Input.is_action_just_pressed("ply1_holster"):
				faketimer = 23
				if holster == 0:
					AniPlay.play("holster") #holster - 1 // anibusy 1 - 0 // shooting - 0
				else:
					AniPlay.play("holsterDraw") #holster - 0 // anibusy 1 - 0
	############################################################################
	
	############################################################################
	### Shooting ###
	if holster == 0:
		if punching == 0:
			if Input.is_action_pressed("ply1_shoot1"):
				if faketimer == 0:
					shoot()
					if ammo1 > 0:
						faketimer = 13
						ammo1 -= 1
					else:
						faketimer = 23
					
					sprite_blink = faketimer-5
					shooting = 10
			
			elif Input.is_action_just_released("ply1_shoot1"):
				if ammo1 < 1:
					faketimer /= 2
				
			elif !Input.is_action_pressed("ply1_shoot1"):
				if faketimer == 0:
					shooting = 0
				
				# if punching == 0:
				if onfloor != 0:
					if shooting == 0 && AniPlay.current_animation != "jumpstart" && faketimer == 0 && punching == 0:
						if Input.is_action_just_pressed("ply1_shoot2"):
							AniPlay.playback_speed = 1.2
							punching = 2
							
							if AniPlay.current_animation != "punchgun":
								AniPlay.play("punchgun") #anibusy 1 - 0 // punching - 0 // hitshape off-on-off
								#weird bug when spamming punch and walking. punching would be 2, and player stuck
								#fixed in the animation, by putting punching = 0 in the very end
				else:
					if shooting == 0:
						if Input.is_action_just_pressed("ply1_shoot2"):
							punching = 1
							if input_dir.x == 0:
								AniPlay.play("kickair") #punching - 0 // anibusy 1 - 0 // hitshape off-on-off
							else:
								if motionZ < 0:
									AniPlay.play("kickair2") #punching - 0 // anibusy 1 - 0 // hitshape off-on-off
								else:
									AniPlay.play("kickair") #punching - 0 // anibusy 1 - 0 // hitshape off-on-off
	
	############################################################################
	############################################################################
	############################################################################
	
	### Punching melee ###
	else:
		if faketimer == 0:
			if onfloor != 0:
				if punching != 1:
					if AniPlay.current_animation != "jumpstart":
						if Input.is_action_just_pressed("ply1_shoot1"):
							punching = 1
							
							############################################ Punch #
							if AniPlay.current_animation != "punchback" && AniPlay.current_animation != "kick" && AniPlay.current_animation != "kickspin":
								if AniPlay.current_animation == "punch1":
									AniPlay.play("punch2") #anibusy 1 - 0 // punching 2 - 0 // hitshape off-on-off
								else:
									AniPlay.play("punch1") #anibusy 1 - 0 // punching 2 - 0 // hitshape off-on-off
								
								if punch_movement > 1: # Move towards input, but decrease power to not punch-walk forever
									punch_movement -= 10
									
									if input_dir != Vector2(0,0): 
										motion += punch_movement*input_dir
								
							###################### Quick kick start/Spin kick ##
						if Input.is_action_just_pressed("ply1_shoot2"):
							punching = 1 #if button is released, short kick. If held, this animation finishes
							AniPlay.play("kickspin") #punching 1 - 2 - 0 // anibusy 1 - 0 // hitshape off-on-off
							
				
				else:#if punching == 1:
					if AniPlay.playback_speed != 1.2:
						AniPlay.playback_speed = 1.2
					
					######################################## Elbow punchback ###
					if AniPlay.current_animation != "punchback" && AniPlay.current_animation != "kick":
						if Input.is_action_just_pressed("ply1_jump") && Input.is_action_pressed("ply1_shoot1"):
							punching = 2
							AniPlay.play("punchback") #anibusy 1 - 0 // punching 2 - 0 // hitshape off-on-off
					
					############################################ Quick kick ####
					if Input.is_action_just_released("ply1_shoot2"):
						AniPlay.play("kick") #punching 2 - 0 // anibusy 1 - 0 // hitshape off-on-off
			
			else: ############################################## Air kicks #####
				if punching == 0:
					if Input.is_action_just_pressed("ply1_shoot1") or Input.is_action_just_pressed("ply1_shoot2"):
						punching = 1
						if input_dir.x == 0:
							AniPlay.play("kickair") #punching - 0 // anibusy 1 - 0 // hitshape off-on-off
						else:
							if motionZ < 0:
								AniPlay.play("kickair2") #punching - 0 // anibusy 1 - 0 // hitshape off-on-off
							else:
								AniPlay.play("kickair") #punching - 0 // anibusy 1 - 0 // hitshape off-on-off ########################


var punch_movement = 60 #De-acceleration, for moving towards input while attacking. Decreases as to not punch-walk forever




#var bul_pos = 31 #Dynamic position Y in which bullets spawn at
const bul_entity = preload("res://objects/projectiles/bullet.tscn")#effects/muzzleflash.tscn")

func shoot():
	Sprite.set_modulate(Color(1.5,1.5,1))
	
	var bul_instance = bul_entity.instance()
	bul_instance.move_dir = Vector2(face_dir, input_dir.y)
	bul_instance.position = position +Vector2((37*face_dir),(0))
#	Global.allEffectsBullet.position_var.x = position.x +(37*face_dir)
	
	if onfloor == 0 or AniPlay.current_animation == "jumpstart":
		bul_instance.positionZ = (positionZ-50)# jumping
#		Global.allEffectsBullet.position_var.y = position.y +(positionZ-50)# jumping
		
	elif onfloor == 1:
		bul_instance.positionZ = (positionZ-67)# regular
#		Global.allEffectsBullet.position_var.y = position.y +(positionZ-67)# regular
		
	elif onfloor == 2:
		bul_instance.positionZ = (positionZ-36)# crouching
#		Global.allEffectsBullet.position_var.y = position.y +(positionZ-36)# crouching
		
	
	bul_instance.shooter_entity_owner = self
	
	get_parent().add_child(bul_instance)
	
#	Global.allEffectsBullet.type = 1





func jump():
	AniPlay.playback_speed = 1.2
	AniPlay.stop()
	aniframe = 8
	punching = 0
	
	air_accel.x /= 2
	air_accel.y /= 2
	
	if !Input.is_action_pressed("ply1_jump"):
		motionZ = JUMP+2
	else:
		motionZ = JUMP # -12
	
	if Input.is_action_pressed("ply1_shoot2") or (holster == 1 && Input.is_action_pressed("ply1_shoot1")):
		punching = 1
		if input_dir.x == 0:
			AniPlay.play("kickair") #punching - 0 // anibusy 1 - 0 // hitshape off-on-off
		else:
			AniPlay.play("kickair2") #punching - 0 // anibusy 1 - 0 // hitshape off-on-off
	
	onfloor = 0





################################################################################
#################### ATTACKING PUNCHING INFORMATION CONFIGURATION ##############


# This doesn't hit enemy's BODY, it its enemy's AREA (HurtArea/HurtShape)
# that then transmits that information to the body (HurtArea.gd)
var damagearray = []
var areaY

func _on_HitArea_area_entered(area):
	if area.is_in_group("punchable"):
		if !damagearray.has(area):
			damagearray.push_back(area)
		
		if area.area_owner_positionY != null:
			areaY = -(area.area_owner_positionY - position.y)
			
			if areaY < 60:
				area.take_damage()
				area.hit_positionX = position.x
				area.hit_owner = self
				#area.hit_owner = self.position #how about this?
				
				position.x += 2 *face_dir


func _on_HitArea_area_exited(area):
	if damagearray.has(area):
		damagearray.erase(area)





var combo_increase = 0


var hitshapeX = 22
var hitshapeY = -62

func punch_config():
	hitshapeY = -62
	HitShape.scale.y = 1
	
	if AniPlay.current_animation == "punch1" or AniPlay.current_animation == "punch2": #weak punches
		combo_increase = 1
		hitshapeX = 22
		hitshapeY = -70
	
	elif AniPlay.current_animation == "punchgun": #gun punch
		combo_increase = 2
		hitshapeX = 15
	
	elif AniPlay.current_animation == "kick" or AniPlay.current_animation == "kick2": #quick punches
		combo_increase = 2
		hitshapeX = 20
		hitshapeY = -40
		HitShape.scale.y = 1.3
	
	elif AniPlay.current_animation == "punchback": #elbow attack
		combo_increase = 3
		hitshapeX = -15
	
	elif AniPlay.current_animation == "kickair": #standing/falling air-kick
		combo_increase = 3
		hitshapeX = 30
		hitshapeY = -35
	
	elif AniPlay.current_animation == "kickair2": #moving air-kick
		combo_increase = 3
		hitshapeX = 30
		hitshapeY = -35
	
	elif AniPlay.current_animation == "kickspin": #spin kick
		combo_increase = 3
		hitshapeX = 30
		hitshapeY = -50
		HitShape.scale.y = 1.8
	
	
#	elif AniPlay.current_animation == "kickdown": #cowardly kick
#		combo_increase = 4

################################################################################
################################################################################











################################################################################
############### GRABBING / HOLDING / DRAGGING / WHATEVER MECHANIC ##############


func _on_HurtArea_area_entered(area): #Grabbing mechanic
	if punching == 0 && anibusy == 0:# && holster == 1:
		if area.is_in_group("holdmen") && area.holdme == 1:
			area.get_grabbed()
			
			area.hit_owner = self
			area_being_held = area
			
			
			anibusy = 0
			punching = 0
			
			aniplus = 0
			shooting = 0
			
			change_state(STATES.HOLDING)

var area_being_held





func holdbaddie():
	if anibusy == 0:
		motion = input_dir*SPEED/2
		
		if input_dir == Vector2(0,0):
			AniPlay.playback_speed = 0
		
		else:
			AniPlay.playback_speed = 1.2
			AniPlay.play("grabwalk")
			
			if input_dir.y == 1:
				aniplus = 0
			elif input_dir.y == -1:
				aniplus = 10
		
		
		if Input.is_action_just_pressed("ply1_shoot2"):
			AniPlay.playback_speed = 1.2
			AniPlay.play("grabthrow") # anibusy 1 - 0 // area_throw() / state - 0
		
		elif Input.is_action_just_pressed("ply1_shoot1"):
			AniPlay.play("grabattack") # anibusy 1 - 0 
	
	
	
	else: #if anibusy != 0:
		AniPlay.playback_speed = 1.2
		motion.x = lerp(motion.x, 0, 0.1)
		motion.y = lerp(motion.y, 0, 0.1)
		
		if AniPlay.current_animation == "grabthrow":
			if input_dir.y == 0:
				aniplus = -10
			elif input_dir.y == 1:
				aniplus = 0
			elif input_dir.y == -1:
				aniplus = 10
			
		else:
			aniplus = 0


func area_throw():
	
	area_being_held.get_thrown()

################################################################################
################################################################################


































func set_flipped(flipstate):
	if flipstate: ### LEFT ###
		Sprite.flip_h = true
		Shadow.flip_h = true
		HitShape.position.x = -hitshapeX
	else: ########### RIGHT ###
		Sprite.flip_h = false
		Shadow.flip_h = false
		HitShape.position.x = hitshapeX

func change_state(new_state):
	state = new_state






#	if AniPlay.current_animation == "punchgun": #gun punch
#		damage = 10
#
#	elif AniPlay.current_animation == "punch1" or AniPlay.current_animation == "punch2": #weak punches
#		damage = 10
#
#	elif AniPlay.current_animation == "kickdown": #cowardly kick
#		damage = 15
#
#	elif AniPlay.current_animation == "kick": #quick kick
#		damage = 15
#
#	elif AniPlay.current_animation == "punchback": #elbow attack
#		damage = 20
#
#	elif AniPlay.current_animation == "kick2": #spin kick
#		damage = 20
#
#	elif AniPlay.current_animation == "kickair": #standing air-kick
#		damage = 15
#
#	elif AniPlay.current_animation == "kickair2": #moving air-kick
#		damage = 20

var onscreen_been = 1

