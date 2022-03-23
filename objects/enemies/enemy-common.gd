extends KinematicBody2D
# All non-specific NPC actions in one neat lil' package for ya 
# Attention, if script-owner has a function with the same name as one here
# THEIRS will be the only one to be used

#const SPRITE0 = preload("res://graphics/characters/NPCB-hobo.png")
#const SPRITE1 = preload("res://graphics/characters/NPC-Hoodie.png")

onready var AniPlay = $AniPlay
onready var Sprite = $Sprite
onready var Shadow = $Shadow
onready var HitShape = $HitArea/HitShape
onready var HurtArea = $HurtArea
onready var HurtShape = $HurtArea/HurtShape
onready var FeetShape = $FeetShape


enum STATES {IDLE,FEAR,ATTACK,GRABBED,CHASING}
export(int) var state = STATES.IDLE


# Function variables
var motion = Vector2()

var move_dir = Vector2(0,0) #move to this direction
var face_dir = 1 #Sprites and things face this way

const SPEED = 60 
#

var faketimer = 0 #Countdown for things
export onready var anibusy = 0 #0, 1, 2, -1, -2, used to check for animation states
var gotthrown = 0 #0 or 1, checks if we are thrown, to hit others in our way

# CONNECTED TO BEHAVIOUR ALT
var anger = 0 #0 or 1, used to go from idle to angry 
var fear = 0 # Used to run away

# Modifyable variables
var speedwalk = 60

export var behavior_alt = 0
# 0 = instantly starts to fight
# 1 = runs away and then starts to fight
# 2 = runs away simply

#var Combo_hurt = 5 #Amount of hits to become vulnerable to grab / kneel
#var Combo_fall = 8 #Amount of hits to fall down

export var looking = 0 #1 for target_lookfor






# Road limits as to not get ran over by cars
var limit_left
var limit_bottom

var roadtop
var roadbottom

var Roadmid
#

func _ready():
	HurtArea.AniPlay = AniPlay #Connect us to HurtShape, it checks on a few things
	
	
	if Global.limit_left != 0:
		limit_left = Global.limit_left
	
	if Global.limit_down != 0:
		limit_bottom = Global.limit_down
	
	if Global.roadtop != 0:
		roadtop = Global.roadtop
	
	if Global.roadbottom != 0:
		roadbottom = Global.roadbottom
	
	Roadmid = round(roadbottom+roadtop)/2 #get middle of the road
	
	
	ouch = 0 # Getting hit, connects with Hurt_Area, AniPlay, to get its info. 
	fear = 0 # NPC-specific but useful, run away if necessary
	combo = 0 # Amount of times hit, decides vulnerability states & animation (ouch, kneel, fall)
	anibusy = 0 # Wide variety, decides if the character is busy done/doing something, and locks up certain changes of state & animations
	HitShape.disabled = 1 # Our attack hitbox
	HurtShape.disabled = 0 # Our ouchie hurtbox
	
	



####      ####      ######   ####   ######    ####     #####
####      ####      ######   ####   ######    ####     #####
##   ##   ##   ##   ##  ##   ##     ##      ##       ##
##   ##   ##   ##   ##  ##   ##     ##      ##       ##
##   ##   ##   ##   ##  ##   ##     ##       ####       ##
####      ####      ##  ##   ##     ####          ##       ##
####      ####      ##  ##   ##     ###           ##       ##
####      ####      ##  ##   ##     ###           ##       ##
##        ##   ##   ######   ####   ######   ####      ####
##        ##   ##   ######   ####   ######   ####      ####
##        ##   ##   ######   ####   ######   ####      ####

func _physics_process(_delta):
	#var cum
	#if hit_owner != null:
	#	cum = hit_owner.combo_increase
#
#	$Label.text = str("",
##
#	"alt:",behavior_alt," anger:",anger,"\n",
#	move_dir," ",faketimer,"\n",
##	"ouch=",ouch," fear=",fear,
#	"c:",combo," h:",Combo_hurt," f:",Combo_fall,
#	"\n+:",cum," ouch active:",HurtArea.ouch_activator,
#	"")
#	########## use/d this to test ###########
	
	motion = move_and_slide(motion, Vector2(0,-1))
	
	match state:
		STATES.IDLE:
			idle()
		STATES.FEAR:
			fearing()
		STATES.ATTACK:
			attacking()
		STATES.GRABBED:
			HitShape.disabled = 1
			HurtShape.disabled = 0
			grabbyplayer()
		STATES.CHASING:
			chaser()
	
	
	if state == 3: #If grabbed by the player#
		FeetShape.disabled = 1
	else:
		FeetShape.disabled = 0
	
	
	Shadow.frame = Sprite.frame
	
	if face_dir == 1:
		set_flipped(false)
	elif face_dir == -1:
		set_flipped(true)
	
	
	if move_dir.x != 0:
		face_dir = move_dir.x
	
	if faketimer > 0:
		faketimer -= 1
	
	
	if position.y > limit_bottom:
		position.y = limit_bottom
	
	if AniPlay.current_animation != "heldup":
		z_index = int(position.y/50) # POSITION OURSELVES ON THE Z_INDEX #
	else:
		z_index = int(position.y/50) - 1 #behing player if grabbed & moving up#
	
	
	if AniPlay.current_animation == "hurtback-pain" or AniPlay.current_animation == "hurtfront-pain": #if combo >= Combo_hurt && combo < Combo_fall: ### over hurt under fall
		FeetShape.shape.radius = 1 #Smaller so player can approach from sides
		HurtShape.position.y = -40 #
		HurtShape.scale.y = 0.5 #### Cut hitbox in half so player doesn't kill by accident
	else:# IF NOT
		if gotthrown == 0: # If not being thrown (ouch_activator == 3 && if abs(motion.x) < 15 && abs(motion.y) < 15:)
			FeetShape.shape.radius = 8
			HurtShape.position.y = -52
			HurtShape.scale.y = 1
		#else keep same state as  hurt-pain
	
	
	### weird as fuck ouch-information transmission system #####################
	### Info comes from HurtArea, activates by checking current animation  #####
	HurtArea.area_owner_positionY = position.y  #Needed for HitArea hitting us, to get our position & compare with theirs ( (-,y) && positionZ)
	
	if HurtArea.ouch_activator != 0:
		if HurtArea.ouch_activator == 1: ######## GETTING HIT ##################
			ouch = 1
			hit_positionX = HurtArea.hit_positionX # Where on the map did they hit us?
			hit_owner = HurtArea.hit_owner # Who hit us?
			
			take_damage() # ouch!
			HurtArea.ouch_activator = 0 # Reset HurtArea's identificator for new hits
		
		
		elif HurtArea.ouch_activator == 2: ######## GRABBED ACTIVATION ######### 
			hit_owner = HurtArea.hit_owner 
			change_state(STATES.GRABBED)
			HurtArea.ouch_activator = 0
			
		
		elif HurtArea.ouch_activator == 3: ###### after grab BEING THROWN ######
			change_state(STATES.ATTACK)
			
			#hit_owner = HurtArea.hit_owner NOT THIS, already know player if grabbed us, DON'T UPDATE
			#hit_positionX = HurtArea.hit_positionX
			
			combo += Combo_fall #over Combo_fall to fall
			faketimer = Staydown_timer*2 # Timer used for how much we should stay down
			motion = SPEED*hit_owner.input_dir*7 #thrown momentum
			take_damage()
			
			gotthrown = 1
			
			HurtShape.scale = Vector2(1.5, 0.8) ## Hurt becomes hitter (like HitShape) when player throws us
			HurtShape.position.y = -25
			
			HurtArea.ouch_activator = 0
			
		
		elif HurtArea.ouch_activator == 4: ###### getting hit by thrown ########
			ouch = 1
			
			hit_positionX = HurtArea.hit_positionX
			hit_owner = HurtArea.hit_owner
			
			faketimer = Staydown_timer*2
			combo += Combo_fall
			
			take_damage()
			HurtArea.ouch_activator = 0
			
		########################################################################
	############################################################################
	if gotthrown == 1: ### #Getting thrown, configuration, config resetter ###
		if abs(motion.x) < 15 && abs(motion.y) < 15:
			HurtShape.scale = Vector2(1,1)
			HurtShape.position.y = -52
			
			gotthrown = 0
			FeetShape.shape.radius = 8
		
#		else: 
#			if abs(motion.x) > 300 or abs(motion.y) > 300:
#				FeetShape.shape.radius = 1 # make FeetShape small to not collide with player's own
#
#
#			else:
#				FeetShape.shape.radius = 8 # and then reset, BUT BEFORE getting us, or else people will go tripping on us already stopped
				
	############################################################################
	
		for area in thrown_array:
			area.hit_owner = hit_owner
			area.hit_positionX = hit_positionX

			area.hit_by_moving()
	
	############################################################################
	if Combo_fall == Combo_hurt: # Blinking when dead but before despawning #
		#piece of shit faketimer won't work, so I used what fucking ever
		
		if Sprite.frame == 38 or Sprite.frame == 48:
		
			if abs(combo) < 2:
				Sprite.visible = 1
				#Shadow.visible = 1
				combo = 31
			
			if combo > 0:
				combo -= 1
			
			if combo < 10:
				Sprite.visible = 0
				#Shadow.visible = 0
			####################################################################
	
	
	############################################################################
	
	
	if Global.sight > (abs(Global.Camera_center-(position.x))):
		onscreen = 1
		onscreen_been = 1
	else:
		onscreen = 0
	
	#print(onscreen_been)

var onscreen = 0
onready var onscreen_been = 0







############        ########            ####                ####################    
############        ########            ####                ####################    
	####            ####    ####        ####                ####                    
	####            ####    ####        ####                ####################    
	####            ####    ####        ####                ####                    
	####            ####    ####        ####                ####                    
############        ########            ############        ####################    
############        ########            ############        ####################  

func anim_idle(): #Get a random idle animation, find a way to make it SCRIPT-OWNER'S OWN, so they can all idle uniquely
	var pick_one = randi() % 4 # o - 3
	
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



var walkswitch = 1 #Used for picking idle OR walk, when targetless

func idle():
	if ouch == 0:
		if fear != 0: #Transition into fear
			AniPlay.play("runstart") # fear: x - 2
			faketimer = 0
			change_state(STATES.FEAR)
		
		
		if faketimer == 0: ##### wander around if targetless ###################
			walkswitch *= -1 # -1 to 1 switch
			
			if walkswitch == 1: # rolled 1, just stay
				move_dir = Vector2(0,0)
				anim_idle()
			
			
			else: ### otherwise randomize walking direction
				var positive_negative = Vector2(randi() % 2,randi() % 2) # randomize 2 values at once, 0 or 1 for both
				
				if positive_negative.x == 0:
					positive_negative.x -= 1 # -1 or 1
				
				if positive_negative.y == 0:
					positive_negative.y -= 1 # -1 or 1
				
				move_dir = positive_negative # move to directions which aren't 0, unless walkswitch == 1 above
				
			
			if looking == 1:
				target_lookfor()
			
			faketimer = 50 + (randi() % 300) #######################################
		
		
		else:#if faketimer != 0: # it's counting down!
			motion = lerp(motion, move_dir*speedwalk, 0.1) #move to direction
			
			if walkswitch == -1:
				
				if move_dir != Vector2(0,0):
					AniPlay.play("walk")
				else:
					faketimer = 0 #RESET and idle anew, if direction is invalid
				
				# Stopping/reflecting before walking onto road ###########################################
				if position.y > roadtop  &&  position.y < Roadmid: #lower than top, higher than mid
					move_dir.y = -1
				
				elif position.y < roadbottom  && position.y > Roadmid: #higher than bottom, lower than mid
					move_dir.y = 1 #######################################################################
			
			
			
			
			# LOOKING TO CHASE A TARGET, DO THIS #
			if looking == 1 && targets_in_scene.size() != 0:
				faketimer /= 3
				
				if target_group == "player":
					hit_owner = targeted_item
					change_state(STATES.ATTACK)
				
				else:
					change_state(STATES.CHASING)
			
			
			
			
			# IF WE'RE CHASEN, DO THIS #
			if abs(walkswitch) == 2: #Happens when DORTOR (or else) calls our attention in their script... wait until they come
				move_dir.x = 0 #Stop moving horizontally
				
				# but still get out of the road!!
				if position.y > roadtop  &&  position.y < Roadmid: #lower than top, higher than mid
					move_dir.y = -1
					AniPlay.play("walkrun")
				
				elif position.y < roadbottom  && position.y > Roadmid: #higher than bottom, lower than mid
					move_dir.y = 1
					AniPlay.play("walkrun")
				
				
				else: #if position is OK, call impatienl idle animation
					move_dir.y = 0#and stop moving vertically
					AniPlay.play("calledattention")
					
				
			
		
	
	
	
	
	
	else:#if ouch != 0: when we're hit! From HurtArea's ouch-activator, from getting hit
		ouch_else()











########    ########        ####        ########
########    ########        ####        ########
####        ####        ####    ####    ####    ####
####        ####        ####    ####    ####    ####
####        ####        ####    ####    ####    ####
########    ########    ############    ########
########    ########    ############    ########
####        ####        ####    ####    ####    ####
####        ####        ####    ####    ####    ####
####        ####        ####    ####    ####    ####
####        ########    ####    ####    ####    ####
####        ########    ####    ####    ####    ####
####        ########    ####    ####    ####    ####

func fearing():
	if ouch == 0:
		HitShape.disabled = 1 #Stop attacking, immediatelly!
		HurtShape.disabled = 0 #Be vulnerable
		
		if fear == 0: #After it's okay
			change_state(STATES.IDLE)
		
		
		if AniPlay.current_animation == "runstart": #If beggining to run
			fear = 1
		
		if AniPlay.current_animation != "runstart": #If done running, actually run
			motion.x = lerp(motion.x, 3*speedwalk*move_dir.x, 0.10)
			move_dir.x = hit_direction
			
			AniPlay.play("run")
		
		
		if behavior_alt == 1: #If brave, go back to attack who attacked us
			if abs(hit_positionX - position.x) > 150:#(hit_owner.position.x - position.x) > 150: 
				# You can choose if run from hit_owner or hit_positionX
				
				anger = 1 #be anmgry
				fear = 0  #lose fear
				change_state(STATES.ATTACK)
			
	
	
	else:#if ouch != 0:
		ouch_else()







   ###      #########      ###      ######   ###   ###
   ###      #########      ###      ######   ###   ###
###   ###      ###      ###   ###   ###      ###   ###
###   ###      ###      ###   ###   ###      ###   ###
###   ###      ###      ###   ###   ###      ###   ###
#########      ###      #########   ###      ######
#########      ###      #########   ###      ######
###   ###      ###      ###   ###   ######   ###   ###
###   ###      ###      ###   ###   ######   ###   ###
###   ###      ###      ###   ###   ######   ###   ###
###   ###      ###      ###   ###   ######   ###   ###

func attacking():
	if ouch == 0 && faketimer == 0:
		if hit_owner != null:
			var wr = weakref(hit_owner) #Check if they're still real (do other new fancy check also)
			
			if (wr.get_ref()) && is_instance_valid(hit_owner): #If they are, then 
				if abs(hit_owner.position.x - position.x) > 54:
					move_dir.x = sign(hit_owner.position.x - position.x)
				else:
					face_dir = sign(hit_owner.position.x - position.x)
					move_dir.x = 0
				
				if abs(hit_owner.position.y - position.y) > 10:
					move_dir.y = sign(hit_owner.position.y - position.y)
				else:
					move_dir.y = 0
			
			else: #Free ourselves from hit_owner behavior right here
				change_state(STATES.IDLE)
				target_clear()
		
		else:
			change_state(STATES.IDLE)
			target_clear()
		
		
		
		if move_dir != Vector2(0,0):
			if anibusy == 0:
				motion = lerp(motion, move_dir*speedwalk*2, 0.1) #accel fast
				
				AniPlay.play("walkrun")
			
				HitShape.disabled = 1 #Always good to be sure
				HurtShape.disabled = 0
		
		else:
			motion = lerp(motion, move_dir*0, 0.1) #deaccel quickly or else we're bullshit
			
			AniPlay.play("punch2") #hit-shape off-on-off // anibusy 1 - 0
		
		
		
	
	
	else:#if ouch != 0:
		ouch_else()









#########   ###   ###      ###      #########   ######
#########   ###   ###      ###      #########   ######
###         ###   ###   ###   ###   ###         ###
###         ###   ###   ###   ###   ###         ###
###         #########   #########   #########   ######
###         #########   #########   #########   ######
###         ###   ###   ###   ###         ###   ###
###         ###   ###   ###   ###         ###   ###
#########   ###   ###   ###   ###   #########   ######
#########   ###   ###   ###   ###   #########   ######

func chaser():
	if ouch == 0:
		motion = lerp(motion, move_dir*(speedwalk+30), 0.1) # Move & acceleration
		
		if faketimer == 0:
			if targets_in_scene.size() == 0: # IF NO TARGETS, CLEAR AND IDLE 
				target_clear()
				change_state(STATES.IDLE)
			
			else:
				target_lookfor() #update target position, look for closer ones
				
				#if targeted_item == null:
				#	target_clear()
				#else:
				if targeted_item != null:
					var wr = weakref(targeted_item) #Check if they're still real
					
					if (wr.get_ref()) && is_instance_valid(targeted_item):
						######################################## move towards target ###
						if abs(targeted_item.position.x - position.x) > 40: #fuckyou
							move_dir.x = sign(targeted_item.position.x - position.x)
						else:
							face_dir = sign(targeted_item.position.x - position.x)
							move_dir.x = 0
						
						if abs(targeted_item.position.y - position.y) > 10:
							move_dir.y = sign(targeted_item.position.y - position.y)
						else:
							move_dir.y = 0
						################################################################
						
						
						if move_dir != Vector2(0,0): #if still too far
							AniPlay.play("walkrun")
					
						else: #if close enough
							if target_available_deal() == true:
								move_dir = Vector2(0,0)
								AniPlay.play("deal") #calls give_cloriquina > target_clear
							else:
								Sprite.frame = 0
					
					else:
						target_clear()
		
		
		else:#if faketimer == 0:
			if targeted_item == null:
				target_lookfor()#target_clear()
			else:
				move_dir = Vector2(0,0)
				
				var wr = weakref(targeted_item) #Check if they're still real
				
				if (wr.get_ref()) && is_instance_valid(targeted_item):
					targeted_item.walkswitch = 2#fuckyou
					targeted_item.face_dir = -sign(targeted_item.position.x - position.x)
					if AniPlay.current_animation != "deal":
						AniPlay.play("dealcall")
					
				
				else:
					target_clear()
					AniPlay.play("idle1")
					
				

	
	else:#if ouch =! 0:
		motion.x = lerp(motion.x, 0, 0.1) # deacceleration
		motion.y = lerp(motion.y, 0, 0.1) # deacceleration
		ouch_else()






func target_available_deal():
	if targeted_item.ouch == 0:
		return true
	else:
		return false



















######         ###         ###   ###         ###      ###########   #########
###   ###   ###   ###   ###   ###   ###   ###   ###   ###           ##
###   ###   ###   ###   ###   ###   ###   ###   ###   ###  ######   ######
###   ###   #########   ###   ###   ###   #########   ###     ###   ###
###   ###   #########   ###   ###   ###   #########   ###     ###   ###
######      ###   ###   ###         ###   ###   ###   ###########   #########


######################################################################################################## DIVIDER OF WATERS
export onready var ouch = 0
# 0 = free
# 1 = stunlock
# 2 = get up


var hit_positionX #comes from HurtArea. (hit_positionX - position.x = hit_direction)
var hit_direction #Get this to know what direction to run away from 

var hit_owner #Connect us to who hurt us, from it comes:
#when hurt:
# combo_increase, 		#I should stILL WRITE: combo_knockback, combo_health_divide
#when grabbed/thrown:
# position, face_dir, input_dir



var combo = 0
# how many consecutive hits, enough to make us hurt then fall. Timed by faketimer

# Weird health / strenght meters, baked into falling down # see AFTER FALL DEBUFF CONFIGURATION ##
var Combo_hurt = 5 #Amount of hits to become vulnerable to grab / kneel
var Combo_fall = 8 #Amount of hits to fall down
#
#cool = round(Combo_hurt/2 - 0.1) #then Renew hurt/fall values as to become more and more vulnerable
#if cool > 0:
#	Combo_hurt = cool
#
#cool  = round(Combo_fall/2 - 0.1)
#if cool > 0:
#	Combo_fall = cool
#
################################################################################

var Staydown_timer = 150 #### NOT COUNTED TIMER, but value that adds to it ####


#func take_damage(combo_increase, timer_increase, ):
func take_damage():
	AniPlay.playback_speed = 1
	anibusy = 0 #Be free from other animations keeping us busy
	HitShape.disabled = 1 #Stop attacking immediatelly
	
	
	hit_direction = sign(position.x - hit_positionX) #Was was the direction of the hit?
	position.x += (1 + randi() % 5) *hit_direction #Move back slightly, mod this later weg
	
	
	
	if faketimer == 0:#Still not hit
		faketimer += 50#25
		combo = hit_owner.combo_increase #Get damage configured in hit_owner
		#not +=, we need to reset combo
		
	else:
		faketimer += 50# - combo
		combo += hit_owner.combo_increase
	
	
	
	
	if state == 0 && (anger == 0 or fear == 0): #aka IDLE, gonna fear or gonna anger?
		if faketimer > 100:
			faketimer /= 3
		
		if behavior_alt == 0:
			if anger == 0:
				change_state(STATES.ATTACK)
				anger = 1
		
		elif fear == 0:
			#change_state(STATES.FEAR)
			fear = 1
	
	

	
	##
	if state == 1: #aka FEAR, instantly fall down
		motion.x = 2* SPEED *hit_direction 
		
		if face_dir == hit_direction:
			AniPlay.play("fallforward") # ouch 1 - 2 // hurtshape off-on >>> frecovery, ouch = 2, 0
		else:
			AniPlay.play("fallback") # ouch 1 - 2 // hurtshape off-on >>> frecovery, ouch = 2, 0
		
	
	
	
	
	
	else: #if state != 1: CALCULATE OUCH STATES
		if combo < Combo_hurt: ### under hurt
			if face_dir == hit_direction:
				if AniPlay.current_animation == "hurtback":
					AniPlay.stop()
					AniPlay.play("hurtback2") #ouch 1 - 0 // sprite & shadow position
				else:
					AniPlay.stop()
					AniPlay.play("hurtback") #ouch 1 - 0 // sprite & shadow position
			
			else:
				if AniPlay.current_animation == "hurtfront":
					AniPlay.stop()
					AniPlay.play("hurtfront2") #ouch 1 - 0 // sprite & shadow position
				else:
					AniPlay.stop()
					AniPlay.play("hurtfront") #ouch 1 - 0 // sprite & shadow position
		
		
		if combo >= Combo_hurt && combo < Combo_fall: ### over hurt under fall
			AniPlay.stop()
			
			if face_dir == hit_direction:
				AniPlay.play("hurtback-pain") #ouch 1 - 0
			
			else:
				AniPlay.play("hurtfront-pain") #ouch 1 - 0
			
			# KNEEL BITCH #
		
		
		if combo >= Combo_fall: ### over fall
			if face_dir == hit_direction:
				AniPlay.play("fallforward") #ouch 1 - 2 // hurtshape off-on >>> frecovery, ouch = 2, 0
				
			
			else:
				AniPlay.play("fallback") #ouch 1 - 2 // hurtshape off-on >>> frecovery, ouch = 2, 0
			
			# GET ON THE FLOOR #
			
			
			
			
			
			############################### AFTER FALL DEBUFF CONFIGURATION ####
			var cool ########################################################### 
			
			#Time to update Combo values, defining how much combo we need to kneel & fall
			if Combo_hurt > 1: 
				cool = round(Combo_hurt/2 - 0.1)
				if cool > 0:
					Combo_hurt = cool
			
			
			if Combo_fall > Combo_hurt:
				cool  = round(Combo_fall/2 - 0.1)
				if cool > 0:
					Combo_fall = cool
			
			Staydown_timer += combo*2 #Add combo to how much time  will stay down, from here and beyond
			faketimer = Staydown_timer
			####################################################################
			####################################################################
		




######  ##  ##  ####  ##  ##    ######  ##     #####  ######
######  ##  ##  ####  ##  ##    ##      ##    ######  ##    
##  ##  ##  ##  ##    ######    ##      ##     ##     ##
##  ##  ##  ##  ##    ######    ####    ##      ###   ####
######  ######  ####  ##  ##    ##      ####  #####   ##
######  ######  ####  ##  ##    ######  ####  ####    ######

func ouch_else(): #called for when ouch != 0 anywhere. Animation should already be playing from take_damge() to reset the values, maybe write a check
	if ouch == 1: #deaccel
		motion = Vector2(lerp(motion.x, 0, 0.05) , lerp(motion.y, 0, 0.1))
	
	
	elif ouch == 2 && faketimer == 0: ### Recovering ###
		#if faketimer == 0: #check if this doesn't many any errors
		
		#if Combo_fall == Combo_hurt: 
		if Combo_hurt > Combo_fall -1: #THIS IS DYING DIE DEATH DEFEAT DEAD #
			queue_free()
		
		
		
		if AniPlay.current_animation != "frecoverforward" && AniPlay.current_animation != "frecoverbackward": #If still not recovering, do
			if face_dir == hit_direction:
				AniPlay.play("frecoverforward") # ouch - 0 // hurtshape off-on
			
			else:
				AniPlay.play("frecoverbackward") # ouch - 0 // hurtshape off-on
			# Instantly get animation so this whole process only happens once
			
			# Who to be angry at for this?
			var wr = weakref(hit_owner) #Check if they're still real
			if (wr.get_ref()): #If they are, then
				if hit_owner != null: ### Important configurationsssszzszszszzss ###
					var hit_owner_direction = sign(hit_owner.position.x - position.x) 
					
					move_dir.x = hit_owner_direction
					
					#hit_direction = -hit_owner_direction
					if behavior_alt == 2:
						hit_direction = -hit_owner_direction #INVERT GETTING UP, to RUN AWAY to the proper direction
						
						hit_owner = null
			
			combo = 0 #Finally free from our pain
			
			# ONLY ONCE: Activate animation & get new facing
		
		else: #Get an early start running if we're feared
			if fear != 0:
				motion = Vector2(lerp(motion.x, move_dir.x, 0.05) , 0)

func _on_HitArea_area_entered(_area):
	pass # Replace with function body.
















############   ######         ###      ######      ######   ######
###            ###   ###   ###   ###   ###   ###   ###      ###   ###
###            ###   ###   ###   ###   ###   ###   ###      ###   ###
###   ######   ######      #########   ######      ######   ###   ###
###      ###   ###   ###   ###   ###   ###   ###   ###      ###   ###
###      ###   ###   ###   ###   ###   ###   ###   ###      ###   ###
############   ###   ###   ###   ###   ######      ######   ######

func grabbyplayer(): #grab BY not grabby >:(  ok maybe grabby 
	position.x = hit_owner.position.x + (hit_owner.face_dir * 15) + (hit_owner.input_dir.x * 5)
	position.y = hit_owner.position.y + (hit_owner.input_dir.y * 5)
	face_dir = -hit_owner.face_dir
	#Link our position and face to them
	
	if hit_owner.input_dir.y == 1:
		AniPlay.play("helddown")
		
	else: #if hit_owner.input_dir.y == -1:
		AniPlay.play("heldup")
	
#	else:
#		if AniPlay.current_animation != "helddown" && AniPlay.current_animation != "heldup":
#			AniPlay.play("heldup") 
#			stays in HELDDOWN, but it looks like they're kissing the player lol
		
	
	#from here grabber activates their code to throw us away




func _on_HurtArea_area_entered(area): #if we're flying back hit, hit those behind us
#	if gotthrown == 1:
#		if area.is_in_group("punchable"):
#
#			area.hit_owner = hit_owner
#			area.hit_positionX = hit_positionX
#
#			area.hit_by_moving()
	if gotthrown == 1:
		if area.is_in_group("punchable"):
			if !thrown_array.has(area):
				thrown_array.push_back(area)

func _on_HurtArea_area_exited(area):
	if area.is_in_group("punchable"):
		if thrown_array.has(area):
			thrown_array.erase(area)

var thrown_array = []












#########      ###      ######      ###############   #########   #########
#########      ###      ######      ###############   #########   #########
   ###      ###   ###   ###   ###   ###               ###            ###
   ###      ###   ###   ###   ###   ###      ######   ###            ###
   ###      #########   ######      ###         ###   ######         ###
   ###      #########   ######      ###         ###   ###            ###
   ###      ###   ###   ###   ###   ###############   #########      ###
   ###      ###   ###   ###   ###   ###############   #########      ###

################### COPIED FROM chaser.gd, TARGETTING SYSTEM ###################
#this CONNECTS TO THE TARGETED ENTITY via TARGETED_ITEM variable
#which updates position dynamically, dumbass

export var target_group = "npc"
var targets_in_scene = []

var target_names_reached = []

var targeted_item



func target_lookfor(): #Find closest target AND update current target's position.
	targets_in_scene = get_tree().get_nodes_in_group(target_group) #Who is spawned
	
	if targets_in_scene.size() != 0: #If anyone at all
		for item in targets_in_scene:
			var wr = weakref(item) #Check if they're still real
			
			
			if (wr.get_ref()) && is_instance_valid(item): #If they are, then ÇÇÇÇÇÇÇÇÇÇÇÇÇÇÇ
				if target_available(item) == true:
					if targeted_item == null: #if no previous target
						targeted_item = item
					
					else: #but if so, we have multiple options, compare
						#if is_instance_valid(targeted_item): #If they are, then ÇÇÇÇÇÇÇÇÇÇÇÇÇÇÇ
						var distance = sqrt(pow(item.position.x - position.x, 2) + pow(item.position.y - position.y, 2))#get position
						var distance_target = sqrt(pow(targeted_item.position.x - position.x, 2) + pow(targeted_item.position.y - position.y, 2))#compare to already targeted (INF if none)
						
						if abs(distance) < abs(distance_target):#if it's smaller
							
							if targeted_item != null: #unfreeze old target and
								if abs(targeted_item.walkswitch) != 1:
									targeted_item.walkswitch = 1
							
							targeted_item = item #you've got a new target!



func target_available(item): #customizable function to see if target available
	if onscreen_been && item.onscreen_been == 1:
		return true
	
	else:
		return false




func target_clear():
	if target_group == "npc":
		if targeted_item != null:
			var wr = weakref(targeted_item) #Check if they're still real
			
			if (wr.get_ref()) && is_instance_valid(targeted_item):
				targeted_item.walkswitch = 1 #Leave NPCs free to walk again
			else:
				targeted_item = null
	
	targeted_item = null
	faketimer = 150








































func change_state(new_state):
	state = new_state

func set_flipped(flipstate):
	if flipstate: ### LEFT ###
		Sprite.flip_h = true
		Shadow.flip_h = true
		HitShape.position.x = -26
	else: ########### RIGHT ###
		Sprite.flip_h = false
		Shadow.flip_h = false
		HitShape.position.x = 26
