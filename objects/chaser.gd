extends KinematicBody2D

const SPEED = 150

onready var AniPlay = $AniPlay
onready var Sprite = $Sprite
onready var Shadow = $Shadow
onready var AreaCol = $Area2D/CollisionShape2D

enum STATES {IDLE}
export(int) var state = STATES.IDLE

var motion = Vector2()

var move_dir = Vector2(0,0)
var face_dir = 1

func _ready():
	AreaCol.disabled = 1

func _physics_process(_delta):
	if targeted_item != null:
		$Label.text = str("target_position:",targeted_item.position)
	
	motion = move_and_slide(motion, Vector2(0,-1))
	
	Shadow.frame = Sprite.frame
	
	if move_dir.x != 0:
		face_dir = move_dir.x
	
	if face_dir == 1:
		set_flipped(false)
	elif face_dir == -1:
		set_flipped(true)
	
	match state:
		STATES.IDLE:
			idle()
	
	
	if delay_timer > 0:
		delay_timer -= 1



var delay_timer = 0

func idle():
	motion = move_dir*SPEED
	
	if targets_in_scene.size() == 0 or targeted_item == null:
		motion = Vector2(0,0)
		
		if delay_timer == 0:
			AniPlay.play("lookfor")
			target_lookfor()
			################# meaningless, don't copy ##########################
			move_dir = Vector2(0,0)
			face_dir *= -1
			
			delay_timer = 50 ###################################################
		
	
	
	else:
		if delay_timer == 0:
			target_lookfor()
			############################################## move towards target #
			if abs(targeted_item.position.x - position.x) > 40:
				move_dir.x = sign(targeted_item.position.x - position.x)
			else:
				face_dir = sign(targeted_item.position.x - position.x)
				move_dir.x = 0
			
			if abs(targeted_item.position.y - position.y) > 10:
				move_dir.y = sign(targeted_item.position.y - position.y)
			else:
				move_dir.y = 0
			####################################################################
			
			if move_dir != Vector2(0,0): #if still too far
				AniPlay.play("walk")
			else: #if close enough
				AniPlay.play("tag") #calls target_clear
		
		
		else: #if delay timer != 0: Delay after spotting target but before chasing
			motion = Vector2(0,0)
			AniPlay.play("lookfornomore")



export var target_group = "target"
var targets_in_scene = []

#var target_names_reached = []
#var target_position = Vector2(INF,INF)

var targeted_item

func target_lookfor():
	targets_in_scene = get_tree().get_nodes_in_group(target_group) #Who is spawned
	
	if targets_in_scene.size() != 0: #If anyone at all
		for item in targets_in_scene:
			var wr = weakref(item) #Check if they're still real
			
			if (wr.get_ref()): #If they are, then
				if targeted_item == null: #if no target to compare with
					targeted_item = item
				
				else: #if we do
					var distance = sqrt(pow(item.position.x - position.x, 2) + pow(item.position.y - position.y, 2))#get position
					var distance_target = sqrt(pow(targeted_item.position.x - position.x, 2) + pow(targeted_item.position.y - position.y, 2))#compare to already targeted (INF if none)
					
					if abs(distance) < abs(distance_target):#if it's smaller you've got a new target!
						targeted_item = item 
						


func target_clear():
	targeted_item = null
	delay_timer = 50


func set_flipped(flipstate):
	if flipstate: ### LEFT ###
		Sprite.flip_h = true
		Shadow.flip_h = true
		AreaCol.position.x = -19
	else: ########### RIGHT ###
		Sprite.flip_h = false
		Shadow.flip_h = false
		AreaCol.position.x = 19

func _on_Area2D_body_entered(body):
	if body.is_in_group("target"):
		target_clear()
		body.queue_free()
