extends TileMap

export var roadtop = 0

export var roadbottom = 0

export var limit_left = 0
export var limit_down = 0

func _ready():
	if roadtop != 0:
		Global.roadtop = roadtop
	
	if roadbottom != 0:
		Global.roadbottom = roadbottom
	
	if limit_left != 0:
		Global.limit_left = limit_left
	
	if limit_down != 0:
		Global.limit_down = limit_down
