extends Node2D

var instructions: String

# feel free to add more adjectives
# all adjectives start with a space
# adjectives starting with a vowel start with "n "
var rat_attributes = [
	" cool",
	" heroic",
	" punk",
	" cottagecore",
	" gay",
	" friendly",
	"n adorable",
	" round",
	"n anthro",
	" seductive",
	" skaterboy",
	"n abstract",
	" mad",
	" hyperrealistic",
	" dad",
	" baby",
	" soft",
	" square",
	" minecraft",
	" slimy",
	" hot",
	" comically large",
	" miniscule",
	" screen-filling",
	" funny",
	"n evil", 
	" twisted",
	" minimalist"
	
]

var previous_pencil_position
var pencil_speed = Vector2.ZERO

var drawing = false
var was_drawing = false
var can_draw = true

var current_line

# number of total points in lines in drawing
# intended as proxy of how detailed image is/ammount of effort/time spent on it
# not currently used
var points = 0

# how loud the pencil scratching sound is at any given time
var volume = 0.0


func _ready():
	# make prompt different every time
	randomize()
	
	# assemble and display instructions
	instructions = "draw a"
	instructions += rat_attributes[randi()%rat_attributes.size()]
	instructions += " rat"
	$Instructions.text = instructions
	
	# prime the janky pencil speed detector in _process
	# if we dont do this the pencil will strongly jerk in one direction 
	# when the scene loads as it'll think it moved like half a screen in one frame
	
	# global mouse position * 0.5 results in accurate position inside of viewport
	# idk why, but it works and i wont complain
	previous_pencil_position = get_global_mouse_position()*0.5
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# calculate distance traveled by pencil
	var pencil_delta = $pencil.global_position-previous_pencil_position
	
	# if holding mouse and on a drawing surface - draw
	if Input.is_action_pressed("left mouse button") and can_draw:
		# if able to draw place pencil down immediately
		$pencil/pencil.position.y = 0
		
		# if pencil is drawing and moving fast - slowly increase volume
		volume = lerp(volume, pencil_speed.length()/100, delta*10)
			
		if not was_drawing:
			# if you just put the pencil down - spawn a new line2d
			var new_line = Line2D.new()
			
			# set it up to look the way you want
			new_line.default_color = Color.black
			new_line.antialiased = false
			new_line.end_cap_mode = Line2D.LINE_CAP_ROUND
			new_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			new_line.joint_mode = Line2D.LINE_JOINT_ROUND
			new_line.width = 3
			
			# add newly spawned line to the scene as child of self
			add_child(new_line)
			
			# make sure new points are added into the recently created line
			current_line = new_line
		
		# if currently drawing add points under tip of pencil to the most recent line
		current_line.add_point($pencil.position)
		
		# counts how many points there are in the drawing
		# not used
#		points += 1

		# update the information for next frame
		was_drawing = true
	else:
		# if no longer drawing slowly lift pencil up
		$pencil/pencil.position.y = lerp($pencil/pencil.position.y, -10, delta*10)
		
		# if not drawing decrease volume
		volume = lerp(volume, 0.0, delta*10)
		
#		if was_drawing:
#			print(points)
		
		# update information for next frame
		was_drawing = false
		pass
	
	# place shadow where the pencil is so they move in unison
	$"pencil shadow".global_position = $pencil.global_position
	
	# update how loud the pencil scratching is
	$AudioStreamPlayer.volume_db = linear2db(volume)
	
	# this "if" is here to prevent division by zero errors when the game runs too fast
	if delta != 0:
		# make "pencil speed" slowly approach real pencil speed 
		# real pencil speed likes to jerk around a lot, this smoothes it out
		pencil_speed = lerp(pencil_speed, pencil_delta/delta, delta*5)
		
		# tilt pencil based on horizontal speed
		$pencil/pencil.rotation_degrees = 30 + pencil_speed.x*0.1
		
		# squash pencil based on vertical speed
		$pencil.scale.x = pow(1.1, pencil_speed.y*0.01)
		$pencil.scale.y = 1/$pencil.scale.x
		
		# make pencil shadow size correspond to how squashed+tilted the pencil is atm
		$"pencil shadow".scale.y = sin($pencil/pencil.global_rotation)*$pencil.scale.x*0.213
	
	# used for calculating how far it moved on the next frame
	previous_pencil_position = $pencil.global_position
	pass


func _on_NoDrawZone_area_entered(area):
	# when the pencil tip enters the no draw zone (hands + places outside the paper)
	# disable abitlity to draw
	# this will act as if player released mouse button and slowly lift pencil
	can_draw = false
	pass 


func _on_NoDrawZone_area_exited(area):
	# opposite of what the function above does
	can_draw = true
	pass


func _on_Button_pressed():
	# make the manager node thats the root of the scene say you won when you re done
	get_parent().emit_signal("player_won")
	# do a loud *click* sound when the "done" button is pressed
	$AudioStreamPlayer2.play()
	pass
