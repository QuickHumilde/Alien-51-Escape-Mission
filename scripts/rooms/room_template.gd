extends Node2D

@export var room_type: String
@export var doors := {
	"up": false,
	"down": false,
	"left": false,
	"right": false
}

func set_doors(active_doors):
	for dir in active_doors.keys():
		var node = get_node_or_null("Door" + dir.capitalize())
		if node:
			node.visible = active_doors[dir]
