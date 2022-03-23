extends "res://objects/enemies/enemy-common.gd"
# All non-specific NPC actions in one neat lil' package for ya 
# Everything already comes in configured, just change needed variables for
# customizing proprieties of the entity in _ready or whatever!




const SPRITE0 = preload("res://graphics/characters/NPCB-hobo.png")
const SPRITE1 = preload("res://graphics/characters/NPC-Hoodie.png")

func _ready(): #randomizing our sprite
	var spriterandi = randi() % 2 #
	
	if spriterandi == 0:
		Sprite.texture = SPRITE0
		Shadow.texture = SPRITE0
	
	elif spriterandi == 1:
		Sprite.texture = SPRITE1
		Shadow.texture = SPRITE1 

