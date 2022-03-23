extends Area2D

var ouch_activator = 0


var hit_positionX
var hit_owner



var damage

func take_damage():
	ouch_activator = 1

func get_grabbed():
	ouch_activator = 2

func get_thrown():
	ouch_activator = 3

func hit_by_moving():
	ouch_activator = 4

var holdme = 0

var AniPlay #main script configures this in _ready

func _process(_delta):
	if AniPlay.current_animation == "hurtback-pain" or AniPlay.current_animation == "hurtfront-pain":
		holdme = 1

	else:
		holdme = 0



var area_owner_positionY

func where_owner():
	ouch_activator = -1
